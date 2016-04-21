//
//  MergeEventsOperation.m
//  NearMe
//
//  Created by Jeff Price on 2016-04-15.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import "MergeEventsOperation.h"

#import "EventsList.h"

@interface MergeEventsOperation()
@property (nonatomic, strong) EventsList *mergedEvents;
@property (nonatomic, strong) NSArray<EventsList *> *lists;
@property (nonatomic, copy) void (^completionAction)(EventsList *);
@end

@implementation MergeEventsOperation

- (id)initWithEventsToMerge:(NSArray<EventsList *> *)newEvents completion:(void (^) (EventsList *))completion {
    if(self = [super init]) {
        _lists = newEvents;
        _completionAction = completion;
    }
    return self;
}

- (void)main {
    @autoreleasepool {
        if(self.isCancelled) {
            return;
        }
        
        for(EventsList *list in self.lists) {
            if(!self.mergedEvents) {
                self.mergedEvents = [EventsList new];
            }
            
            [self.mergedEvents mergeItems:list.allItems];
        }
        
        NSSortDescriptor *sortByStartDateDesc = [NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:NO];
        [self.mergedEvents sortUsingDescriptors:@[sortByStartDateDesc]];
        
        if(self.completionAction) {
            self.completionAction(self.mergedEvents);
        }
        
        [self completeOperation];
    }
}
@end
