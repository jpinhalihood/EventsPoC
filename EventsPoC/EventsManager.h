//
//  EventsManager.h
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-23.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>


@class EventsList;
@class EventBriteEventsForLocationOp;

FOUNDATION_EXPORT double const EventsDefaultRadius;

@interface EventsManager : NSObject<CLLocationManagerDelegate>

@property (nonatomic, strong) NSNumber *radius;
@property (nonatomic, readonly) EventsList *allEvents;
@property (nonatomic, readonly) EventsList *filteredEvents;

@property (nonatomic, copy) void (^locationUpdatedAction)(EventsList *);

+ (EventsManager *)sharedInstance;
- (void)start;


@end
