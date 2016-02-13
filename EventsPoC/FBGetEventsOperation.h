//
//  FBGetEventsOperation.h
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-12.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsynchronousOperation.h"

@class FBEvent;

@interface FBGetEventsOperation : AsynchronousOperation
-(instancetype)initWithUser:(NSString *)user completion:(void (^) (NSArray<FBEvent*> *, NSError *))completion;
@end
