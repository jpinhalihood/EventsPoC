//
//  EventsManager.m
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-23.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import "EventsManager.h"

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


+ (void)loadEventsBetween:(NSDate *)startDate and:(NSDate *)endDate completion:(void (^) (EventsList *events, NSError *error))completion {
    
    
    NSOperationQueue *queue = [NSOperationQueue new];
    NSMutableArray<NSObject<EventProtocol>*> *events = [NSMutableArray new];
    
    void (^myLikesAndEventsOpCompletion)(NSArray<FBEvent *> *, NSError *) = ^(NSArray<FBEvent *> *fbEvents, NSError *error) {

        for(NSObject<EventProtocol> *fbEvent in fbEvents) {
            [events addObject:fbEvent];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSLog(@"%ld Events\n", (long)fbEvents.count);
            for(NSObject<EventProtocol> *event in fbEvents) {
                NSLog(@"Id: %@ | Name: %@\n", event.eventId, event.eventName);
            }
            
            EventsList *list = nil;
            if(events && events.count > 0) {
                list = [EventsList listFromArrayOfEvents:events];
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
