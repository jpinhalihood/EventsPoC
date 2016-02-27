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

@interface EventsManager : NSObject
+ (void)loadEventsWithCompletion:(void (^) (EventsList *events, NSError *error))completion;
+ (void)loadEventsBetween:(NSDate *)startDate and:(NSDate *)endDate completion:(void (^) (EventsList *events, NSError *error))completion;
+ (void)loadEventsBetween:(NSDate *)startDate
                      and:(NSDate *)endDate
             withinRadius:(NSNumber *)radius
               ofLocation:(CLLocation *)location
               completion:(void (^) (EventsList *events, NSError *error))completion;
@end
