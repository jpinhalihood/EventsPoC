//
//  MergeEventsOperation.h
//  NearMe
//
//  Created by Jeff Price on 2016-04-15.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsynchronousOperation.h"

@class EventsList;


@interface MergeEventsOperation : AsynchronousOperation
- (id)initWithEventsToMerge:(NSArray<EventsList *> *)newEvents completion:(void (^) (EventsList *))completion;
@end
