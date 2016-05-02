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
#import "MergeEventsOperation.h"

#import "NearMe-Swift.h"



NSTimeInterval const EventsDefaultLocationUpdateInterval = 60;
double const EventsDefaultRadius = 200 *1000; // 200 km in meters

@interface EventsManager()
@property (nonatomic, readwrite) EventsList *allEvents;
@property (nonatomic, readwrite) EventsList *filteredEvents;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic, strong) CLLocation *lastLocation;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;

@property (nonatomic, strong) NSDate *lastLocationUpdate;

@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) CLGeocoder *geocoder;
@end

@implementation EventsManager

@synthesize filteredEvents = _filteredEvents;
@synthesize allEvents = _allEvents;
@synthesize radius = _radius;

- (EventsList *)filteredEvents {
    @synchronized (self) {
        if(!_filteredEvents) {
            _filteredEvents = [EventsList new];
        }
        return _filteredEvents;
    }
}

- (void)setFilteredEvents:(EventsList *)filteredEvents {
    @synchronized (self) {
        _filteredEvents = filteredEvents;
    }
}

- (EventsList *)allEvents {
    @synchronized (self) {
        if(!_allEvents) {
            _allEvents = [EventsList new];
        }
        return _allEvents;
    }
}

- (void)setAllEvents:(EventsList *)allEvents {
    @synchronized (self) {
        _allEvents = allEvents;
    }
}

- (NSNumber *)radius {
    @synchronized (self) {
        return _radius;
    }
}

- (void)setRadius:(NSNumber *)radius {
    @synchronized (self) {
        _radius = radius;
    }
}



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
        [self.queue addObserver:self forKeyPath:@"operations" options:0 context:NULL];
        
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
    self.currentLocation = [self.locationManager location];
    NSLog(@"Current Location: %f (Lat) %f (Lng)", self.currentLocation.coordinate.latitude, self.currentLocation.coordinate.longitude);
    [self loadEventsStarting:self.startDate ending:self.endDate location:self.currentLocation];
}

- (void)loadEventsStarting:(NSDate *)start ending:(NSDate *)end location:(CLLocation *)location {
    
    __weak __typeof(self) weakSelf = self;
    __block NSMutableArray<EventsList *> *lists = [NSMutableArray new];
    __block EventsList *mergedEvents;
    
    // Events near my location
    [self.geocoder reverseGeocodeLocation:location
                        completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        
        
        // Merge Op
        MergeEventsOperation *mergeOp = [[MergeEventsOperation alloc] initWithEventsToMerge:lists completion:^(EventsList *events) {
            dispatch_async(dispatch_get_main_queue(), ^{
                mergedEvents = events;
//                weakSelf.allEvents = [mergedEvents copy];
                weakSelf.allEvents = mergedEvents;
                
                // Sort by start time earliest to latest
                NSSortDescriptor *sortByStartDateDesc = [NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:NO];
                [weakSelf.allEvents sortUsingDescriptors:@[sortByStartDateDesc]];
                                
                weakSelf.filteredEvents = [weakSelf filterEvents:mergedEvents forLocation:location radius:weakSelf.radius];
                [weakSelf postEventsUpdatedNotificationWithEvents:weakSelf.filteredEvents];
            });
        }];
        
        FBGetEventsForLocationOperation *locationEventsOp;
        NSString *locationName = placemarks.count ? placemarks.firstObject.locality : nil;
        if(locationName) {
            
            locationEventsOp = [[FBGetEventsForLocationOperation alloc] initWithLocationName:locationName
                                                                                  completion:^(EventsList *events, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *description = [NSString stringWithFormat:@"Loaded %ld location events\n", (long)events.count];
                    [weakSelf logEvents:events description:description];
                    [lists addObject:[events copy]];
                });
            }];
            
            locationEventsOp.startDate = start;
            locationEventsOp.endDate = end;
            locationEventsOp.latitude = [NSNumber numberWithDouble:location.coordinate.latitude];
            locationEventsOp.longitude = [NSNumber numberWithDouble:location.coordinate.longitude];
        }
        
        // My friends and my likes events
        FBGetLikesAndEventsOperation *myLikesAndEventsOp =
                            [[FBGetLikesAndEventsOperation alloc] initWithCompletion:^(EventsList *events, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *description = [NSString stringWithFormat:@"Loaded %ld Like/Friend Events\n", (long)events.count];
                [weakSelf logEvents:events description:description];
                [lists addObject:[events copy]];
            });
        }];
                            
        myLikesAndEventsOp.startDate = start;
        myLikesAndEventsOp.endDate = end;

        EventBriteEventsForLocationOp *ebLocationEventsOp = [[EventBriteEventsForLocationOp alloc] initWithLatitude:self.currentLocation.coordinate.latitude longitude:self.currentLocation.coordinate.longitude radius:self.radius.doubleValue];
               
        ebLocationEventsOp.startDate = self.startDate;
        ebLocationEventsOp.endDate = self.endDate;
        ebLocationEventsOp.completionAction = ^(EventsList *ebEvents, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *description = [NSString stringWithFormat:@"Loaded %ld EventBrite Events\n", (long)ebEvents.count];
                [weakSelf logEvents:ebEvents description:description];
                [lists addObject:ebEvents];
            });
        };
                            
        [mergeOp addDependency:ebLocationEventsOp];
        [mergeOp addDependency:myLikesAndEventsOp];
        [mergeOp addDependency:locationEventsOp];
        
        [self.queue addOperation:ebLocationEventsOp];
        [self.queue addOperation:locationEventsOp];
        [self.queue addOperation:myLikesAndEventsOp];
        [self.queue addOperation:mergeOp];
    }];

}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if(object == self.queue && [keyPath isEqualToString:@"operations"]) {
        NSLog(@"\n==\nActive Operations: %ld", (long)self.queue.operationCount);
        if(self.queue.operationCount == 0) {
            NSLog(@"Completed all object retrieval ops");
            NSLog(@"All Events Count: %ld", (long)self.allEvents.count);
            NSLog(@"Filtered Events Count: %ld", (long)self.filteredEvents.count);
        }
    }
}


- (void)logEvents:(EventsList *)events description:(NSString *)description {
    NSLog(@"%@", description);
    for(NSObject<EventProtocol> *event in events.allItems) {
        NSLog(@"Id: %@ | Name: %@ | Host: %@\n", event.eventId, event.eventName, event.eventHost);
    }
    
}

- (void)loadFBFriendAndLikeEventsForLocation:(CLLocation *)currentLocation starting:(NSDate *)start ending:(NSDate *)end {
    
    NSLog(@"Loading Like/Friend events");
    
    __weak __typeof(self) weakSelf = self;
    void (^myLikesAndEventsOpCompletion)(EventsList *, NSError *) = ^(EventsList *events, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *description = [NSString stringWithFormat:@"Loaded %ld location events\n", (long)events.count];
            [weakSelf logEvents:events description:description];
            [weakSelf postEventsUpdatedNotificationWithEvents:weakSelf.allEvents];
        });
    };
    
    FBGetLikesAndEventsOperation *myLikesAndEventsOp = [[FBGetLikesAndEventsOperation alloc] initWithCompletion:myLikesAndEventsOpCompletion];
    myLikesAndEventsOp.startDate = start;
    myLikesAndEventsOp.endDate = end;
    [self.queue addOperation:myLikesAndEventsOp];
    
}

- (void)loadFBEventsNearLocation:(CLLocation *)currentLocation starting:(NSDate *)start ending:(NSDate *)end {
    
    __weak __typeof(self) weakSelf = self;
    
    void (^locationEventsOpCompletion)(EventsList *, NSError *) = ^(EventsList *events, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSString *description = [NSString stringWithFormat:@"Loaded %ld location events\n", (long)events.count];
            [weakSelf logEvents:events description:description];
            [weakSelf postEventsUpdatedNotificationWithEvents:weakSelf.allEvents];
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
        
        if(self.filteredEvents) {
            [self.filteredEvents removeAllItems];
        }
        
        self.filteredEvents = [self filterEvents:self.allEvents forLocation:location radius:self.radius];
        
        self.lastLocationUpdate = [NSDate new];
        self.lastLocation = location;

        if(self.locationUpdatedAction) {
            self.locationUpdatedAction(self.filteredEvents);
        }
    }
}

- (void)refreshEventsForLocationChangedTo:(CLLocation *)newLocation {
    [self loadFBEventsNearLocation:newLocation starting:self.startDate ending:self.endDate];
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

@end
