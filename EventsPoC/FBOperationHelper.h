//
//  FBOperationHelper.h
//  NearMe
//
//  Created by Jeff Price on 2016-04-20.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FBOperationHelper : NSObject
+ (NSArray<NSArray *> *)makeBucketsWithObjectIds:(NSArray<NSString *> *)objectIds;

+ (NSData *)getBatchRequestDataWithObjectIds:(NSArray<NSString *> *)objectIds
                                   startDate:(NSDate *)since
                                     endDate:(NSDate *)until
                                 accessToken:(NSString *)accessToken;

+ (NSString *)getRequestUrlForEventsOnObjectId:(NSString *)objectId
                                     startDate:(NSDate *)startDate
                                       endDate:(NSDate *)endDate;
@end
