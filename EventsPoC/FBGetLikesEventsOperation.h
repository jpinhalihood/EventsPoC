//
//  FBGetLikesEventsOperation.h
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-18.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FBPagedApiOperation.h"

@class FBEvent;

@interface FBGetLikesEventsOperation : FBPagedApiOperation

@property (nonatomic, assign) NSUInteger limit;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, strong) NSArray<NSString *> *objectIds;

-(instancetype)initWithObjectIds:(NSArray<NSString *> *)identifiers completion:(void (^) (NSArray<FBEvent*> *, NSError *))completion;
@end
