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



@interface EventsManager()
@end

@implementation EventsManager

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
