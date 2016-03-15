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

NSTimeInterval const EventsDefaultLocationUpdateInterval = 60;
double const EventsDefaultRadius = 200 *1000; // 200 km in meters

@interface EventsManager()

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *lastLocation;

@property (nonatomic, strong) NSDate *lastLocationUpdate;

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
        self.locationManager = [CLLocationManager new];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [self.locationManager requestAlwaysAuthorization];
    }
    
    return self;
}


- (void)start {

    NSOperationQueue *queue = [NSOperationQueue new];
    NSMutableArray<NSObject<EventProtocol>*> *events = [NSMutableArray new];
    CLLocation *currentLocation = [self.locationManager location];
    
    __weak __typeof(self) weakSelf = self;
    void (^myLikesAndEventsOpCompletion)(NSArray<FBEvent *> *, NSError *) = ^(NSArray<FBEvent *> *fbEvents, NSError *error) {
        
        for(NSObject<EventProtocol> *fbEvent in fbEvents) {
            [events addObject:fbEvent];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSLog(@"%ld Events\n", (long)fbEvents.count);
            for(NSObject<EventProtocol> *event in fbEvents) {
                NSLog(@"Id: %@ | Name: %@ | Host: %@\n", event.eventId, event.eventName, event.eventHost);
            }
            
            if(events && events.count > 0) {
                weakSelf.allEvents = [EventsList listFromArrayOfEvents:events];
                [weakSelf filterEventsForLocation:currentLocation];
                [weakSelf postEventsUpdatedNotification];
            }
            
        });
    };
    
    
    NSDate *start = [NSDate new];
    NSDate *end = [start dateByAddingTimeInterval:60 * 60 * 24];
    
    FBGetLikesAndEventsOperation *myLikesAndEventsOp = [[FBGetLikesAndEventsOperation alloc] initWithCompletion:myLikesAndEventsOpCompletion];
    myLikesAndEventsOp.startDate = start;
    myLikesAndEventsOp.endDate = end;
    [queue addOperation:myLikesAndEventsOp];
}

- (void)postEventsUpdatedNotification {
    NSDictionary *userInfo = @{KeyEventsListUpdatedNotificationPayload : self.allEvents };
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
    
    self.lastLocationUpdate = [NSDate new];
    self.lastLocation = location;
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

+ (void)loadEventsBetween:(NSDate *)startDate
                      and:(NSDate *)endDate
             withinRadius:(NSNumber *)radius
               ofLocation:(CLLocation *)location
               completion:(void (^) (EventsList *events, NSError *error))completion {
    
    NSOperationQueue *queue = [NSOperationQueue new];
    NSMutableArray<NSObject<EventProtocol>*> *events = [NSMutableArray new];
    
    void (^myLikesAndEventsOpCompletion)(NSArray<FBEvent *> *, NSError *) = ^(NSArray<FBEvent *> *fbEvents, NSError *error) {

        for(NSObject<EventProtocol> *fbEvent in fbEvents) {
            [events addObject:fbEvent];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSLog(@"%ld Events\n", (long)fbEvents.count);
            for(NSObject<EventProtocol> *event in fbEvents) {
                NSLog(@"Id: %@ | Name: %@ | Host: %@\n", event.eventId, event.eventName, event.eventHost);
            }
            
            EventsList *list = nil;
            if(events && events.count > 0) {
                if(location) {
                    for(FBEvent *event in events) {
                        if(event.placeLongitude && event.placeLattitude) {
                            CLLocation *eventLocation = [[CLLocation alloc] initWithLatitude:event.placeLattitude.doubleValue
                                                                                   longitude:event.placeLongitude.doubleValue];
                            if([eventLocation distanceFromLocation:location] <= radius.doubleValue) {
                                if(!list) {
                                    list = [EventsList new];
                                }
                                [list add:event];
                            }
                        }
                    }
                } else {
                    list = [EventsList listFromArrayOfEvents:events];
                }
            }
            
            if(completion) {
                completion(list, error);
            }
            
        });
    };
    
    FBGetLikesAndEventsOperation *myLikesAndEventsOp = [[FBGetLikesAndEventsOperation alloc] initWithCompletion:myLikesAndEventsOpCompletion];
    myLikesAndEventsOp.startDate = startDate;
    myLikesAndEventsOp.endDate = endDate;
    [queue addOperation:myLikesAndEventsOp];

}



@end
