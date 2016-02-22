//
//  FBGetEventsOperation.h
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-12.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FBPagedApiOperation.h"

@class FBEvent;

@interface FBGetEventsOperation : FBPagedApiOperation

@property (nonatomic, assign) NSUInteger limit;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;

-(instancetype)initWithObjectId:(NSString *)identifier completion:(void (^) (NSArray<FBEvent*> *, NSError *))completion;
@end
