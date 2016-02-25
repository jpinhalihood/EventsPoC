//
//  GetLikesAndEventsOperation.h
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-24.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FBPagedApiOperation.h"
@class FBEvent;


@interface FBGetLikesAndEventsOperation : FBPagedApiOperation
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, assign) NSUInteger limit;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;

-(instancetype)initWithCompletion:(void (^) (NSArray<FBEvent*> *, NSError *))completion;
@end
