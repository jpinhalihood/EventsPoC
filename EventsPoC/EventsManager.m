//
//  EventsManager.m
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-23.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import "EventsManager.h"

#import <CoreLocation/CoreLocation.h>

#import "FBEvent.h"
#import "EventsList.h"
#import "EventProtocol.h"
#import "EventNotifications.h"

#import "FBGetLikesAndEventsOperation.h"
#import "FBGetEventsForLocationOperation.h"

NSTimeInterval const EventsDefaultLocationUpdateInterval = 60;
double const EventsDefaultRadius = 200 *1000; // 200 km in meters

@interface EventsManager()
@property (nonatomic, readwrite) EventsList *allEvents;
@property (nonatomic, readwrite) EventsList *filteredEvents;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *lastLocation;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;

@property (nonatomic, strong) NSDate *lastLocationUpdate;

@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) CLGeocoder *geocoder;
@end

@implementation EventsManager

+ (EventsManager *)sharedInstance {
    static EventsManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[EventsManager alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    if(self = [super init]) {
        self.geocoder = [[CLGeocoder alloc] init];
        self.queue = [NSOperationQueue new];
        self.locationManager = [CLLocationManager new];
    
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [self.locationManager requestAlwaysAuthorization];
        
        self.startDate = [NSDate new];
        self.endDate = [self.startDate dateByAddingTimeInterval:60 * 60 * 24];

    }
    
    return self;
}


- (void)start {
    CLLocation *currentLocation = [self.locationManager location];
    
    [self loadFBFriendAndLikeEventsForLocation:currentLocation starting:self.startDate ending:self.endDate];
    [self loadFBEventsNearLocation:currentLocation starting:self.startDate ending:self.endDate];

}

- (void)loadFBFriendAndLikeEventsForLocation:(CLLocation *)currentLocation starting:(NSDate *)start ending:(NSDate *)end {
    
    NSLog(@"Loading Like/Friend events");
    
    __weak __typeof(self) weakSelf = self;
    void (^myLikesAndEventsOpCompletion)(EventsList *, NSError *) = ^(EventsList *fbEvents, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSLog(@"Loaded %ld Like/Friend Events\n", (long)fbEvents.count);
            for(NSObject<EventProtocol> *event in fbEvents.allItems) {
                NSLog(@"Id: %@ | Name: %@ | Host: %@\n", event.eventId, event.eventName, event.eventHost);
            }
            
            if(fbEvents && fbEvents.count > 0) {
                if(!weakSelf.allEvents) {
                    weakSelf.allEvents = [EventsList listFromArrayOfEvents:fbEvents.allItems];
                } else {
                    [weakSelf.allEvents mergeItems:fbEvents.allItems];
                }
                
                [weakSelf postEventsUpdatedNotificationWithEvents:weakSelf.allEvents];
            }
            
        });
    };
    
    FBGetLikesAndEventsOperation *myLikesAndEventsOp = [[FBGetLikesAndEventsOperation alloc] initWithCompletion:myLikesAndEventsOpCompletion];
    myLikesAndEventsOp.startDate = start;
    myLikesAndEventsOp.endDate = end;
    [self.queue addOperation:myLikesAndEventsOp];
    
}

- (void)loadFBEventsNearLocation:(CLLocation *)currentLocation starting:(NSDate *)start ending:(NSDate *)end {
    
    __weak __typeof(self) weakSelf = self;
    
    void (^locationEventsOpCompletion)(EventsList *, NSError *) = ^(EventsList *fbEvents, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSLog(@"Loaded %ld location events\n", (long)fbEvents.count);
            for(NSObject<EventProtocol> *event in fbEvents.allItems) {
                NSLog(@"Id: %@ | Name: %@ | Host: %@\n", event.eventId, event.eventName, event.eventHost);
            }
            
            if(fbEvents && fbEvents.count > 0) {
                EventsList *unfilteredEvents = [EventsList listFromArrayOfEvents:fbEvents.allItems];
                EventsList *filteredEvents = [self filterEvents:unfilteredEvents forLocation:currentLocation radius:weakSelf.radius];
                if(!weakSelf.allEvents) {
                    weakSelf.allEvents = [EventsList listFromArrayOfEvents:fbEvents.allItems];
                } else {
                    [weakSelf.allEvents mergeItems:filteredEvents.allItems];
                }
                
                [weakSelf postEventsUpdatedNotificationWithEvents:weakSelf.allEvents];
            }
            
        });
    };
    
    [self.geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        
        NSString *locationName = placemarks.count ? placemarks.firstObject.locality : nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Current Location: %@", locationName);
            NSLog(@"Loading events within %@ meter radius of %@", self.radius.stringValue, locationName);
        });
        
        if(locationName) {
            FBGetEventsForLocationOperation *locationEventsOp =
            [[FBGetEventsForLocationOperation alloc] initWithLocationName:locationName completion:locationEventsOpCompletion];
            locationEventsOp.startDate = start;
            locationEventsOp.endDate = end;
            locationEventsOp.latitude = [NSNumber numberWithDouble:currentLocation.coordinate.latitude];
            locationEventsOp.longitude = [NSNumber numberWithDouble:currentLocation.coordinate.longitude];
            [weakSelf.queue addOperation:locationEventsOp];
        }
        
    }];

}

- (void)postEventsUpdatedNotificationWithEvents:(EventsList *)events {
    NSDictionary *userInfo = @{KeyEventsListUpdatedNotificationPayload : events };
    [[NSNotificationCenter defaultCenter] postNotificationName:EventsListUpdatedNotification object:nil userInfo:userInfo];
}

- (void)setRadius:(NSNumber *)radius {
    _radius = radius;
    [self filterEventsForLocation:self.lastLocation];
}



#pragma mark - CLLocationManagerDelegate Methods
-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [manager startUpdatingLocation];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    CLLocation *location = (CLLocation *)locations.firstObject;
    
    NSDate *now = [NSDate new];
    NSTimeInterval secondsSinceLastLocationUpdate = [self.lastLocationUpdate timeIntervalSinceDate:now];
    if(secondsSinceLastLocationUpdate *-1 >= EventsDefaultLocationUpdateInterval
       || [location distanceFromLocation:self.lastLocation] > self.radius.doubleValue) {
        
        [self filterEventsForLocation:location];
        self.lastLocationUpdate = [NSDate new];
        self.lastLocation = location;

        if(self.locationUpdatedAction) {
            self.locationUpdatedAction(self.filteredEvents);
        }
    }
    
}

- (void)filterEventsForLocation:(CLLocation *)location {
    
    if(!self.filteredEvents) {
        self.filteredEvents = [EventsList new];
    }
    [self.filteredEvents removeAllItems];
    
    for(NSObject<EventProtocol> *event in self.allEvents.allItems) {
        if(event.placeLongitude && event.placeLattitude) {
            CLLocation *eventLocation = [[CLLocation alloc] initWithLatitude:event.placeLattitude.doubleValue
                                                                   longitude:event.placeLongitude.doubleValue];
            if([eventLocation distanceFromLocation:location] <= self.radius.doubleValue) {
                [self.filteredEvents add:event];
            }
        }
    }    
}


- (EventsList *)filterEvents:(EventsList *)events forLocation:(CLLocation *)location radius:(NSNumber *)radius {
    EventsList *filteredEvents = [EventsList new];
    for(NSObject<EventProtocol> *event in events.allItems) {
        if(event.placeLongitude && event.placeLattitude) {
            CLLocation *eventLocation = [[CLLocation alloc] initWithLatitude:event.placeLattitude.doubleValue
                                                                   longitude:event.placeLongitude.doubleValue];
            if([eventLocation distanceFromLocation:location] <= radius.doubleValue) {
                [filteredEvents add:event];
            }
        }
    }
    
    return filteredEvents;
}



+ (void)loadEventsWithCompletion:(void (^) (EventsList *events, NSError *error))completion {
    NSDate *start = [NSDate new];
    NSDate *end = [start dateByAddingTimeInterval:60 * 60 * 24];
    [EventsManager loadEventsBetween:start and:end completion:completion];
}

+ (void)loadEventsBetween:(NSDate *)startDate
                      and:(NSDate *)endDate
               completion:(void (^) (EventsList *events, NSError *error))completion {
    
    [EventsManager loadEventsBetween:startDate and:endDate withinRadius:nil ofLocation:nil completion:completion];
}

//+ (void)loadEventsBetween:(NSDate *)startDate
//                      and:(NSDate *)endDate
//             withinRadius:(NSNumber *)radius
//               ofLocation:(CLLocation *)location
//               completion:(void (^) (EventsList *events, NSError *error))completion {
//    
//    NSOperationQueue *queue = [NSOperationQueue new];
//    NSMutableArray<NSObject<EventProtocol>*> *events = [NSMutableArray new];
//    
//    void (^myLikesAndEventsOpCompletion)(EventsList *, NSError *) = ^(EventsList *fbEvents, NSError *error) {
//
//        for(NSObject<EventProtocol> *fbEvent in fbEvents) {
//            [events addObject:fbEvent];
//        }
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            
//            NSLog(@"%ld Events\n", (long)fbEvents.count);
//            for(NSObject<EventProtocol> *event in fbEvents) {
//                NSLog(@"Id: %@ | Name: %@ | Host: %@\n", event.eventId, event.eventName, event.eventHost);
//            }
//            
//            EventsList *list = nil;
//            if(events && events.count > 0) {
//                if(location) {
//                    for(FBEvent *event in events) {
//                        if(event.placeLongitude && event.placeLattitude) {
//                            CLLocation *eventLocation = [[CLLocation alloc] initWithLatitude:event.placeLattitude.doubleValue
//                                                                                   longitude:event.placeLongitude.doubleValue];
//                            if([eventLocation distanceFromLocation:location] <= radius.doubleValue) {
//                                if(!list) {
//                                    list = [EventsList new];
//                                }
//                                [list add:event];
//                            }
//                        }
//                    }
//                } else {
//                    list = [EventsList listFromArrayOfEvents:events];
//                }
//            }
//            
//            if(completion) {
//                completion(list, error);
//            }
//            
//        });
//    };
//    
//    FBGetLikesAndEventsOperation *myLikesAndEventsOp = [[FBGetLikesAndEventsOperation alloc] initWithCompletion:myLikesAndEventsOpCompletion];
//    myLikesAndEventsOp.startDate = startDate;
//    myLikesAndEventsOp.endDate = endDate;
//    [queue addOperation:myLikesAndEventsOp];
//
//}



@end
