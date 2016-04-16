//
//  FBGetEventsForLocationOperation.h
//  NearMe
//
//  Created by Jeff Price on 2016-03-25.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FBPagedApiOperation.h"

@class FBEvent;
@class EventsList;

@interface FBGetEventsForLocationOperation : AsynchronousOperation
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, assign) NSUInteger limit;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;

@property (nonatomic, strong) NSNumber *latitude;
@property (nonatomic, strong) NSNumber *longitude;
@property (nonatomic, strong) NSNumber *radius;

-(instancetype)initWithLocationName:(NSString *)locationName completion:(void (^) (EventsList *, NSError *))completion;
@end
