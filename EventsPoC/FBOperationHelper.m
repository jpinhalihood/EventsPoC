//
//  FBOperationHelper.m
//  NearMe
//
//  Created by Jeff Price on 2016-04-20.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import "FBOperationHelper.h"

@implementation FBOperationHelper
+ (NSArray<NSArray *> *)makeBucketsWithObjectIds:(NSArray<NSString *> *)objectIds {
    
    NSUInteger count=0;
    NSMutableArray<NSArray *> *buckets = [NSMutableArray new];
    NSMutableArray<NSString *> *currentBucket = [[NSMutableArray alloc] initWithCapacity:50];
    
    for(NSString *objectId in objectIds) {
        if(count < 49) {
            count++;
            [currentBucket addObject:objectId];
        } else {
            [currentBucket addObject:objectId];
            count = 0;
            [buckets addObject:[NSArray arrayWithArray:currentBucket]];
            [currentBucket removeAllObjects];
        }
    }
    
    if(currentBucket.count > 0) {
        [buckets addObject:[NSArray arrayWithArray:currentBucket]];
    }
    
    return [NSArray arrayWithArray:buckets];
}

+ (NSData *)getBatchRequestDataWithObjectIds:(NSArray<NSString *> *)objectIds
                                   startDate:(NSDate *)since
                                     endDate:(NSDate *)until
                                 accessToken:(NSString *)accessToken {
    
    NSMutableDictionary *payload = [NSMutableDictionary new];
    NSMutableArray *batch = [[NSMutableArray alloc] initWithCapacity:objectIds.count];
    for(NSString *objectId in objectIds) {
        NSMutableDictionary *dictionary = [NSMutableDictionary new];
        NSString *relativeUrl = [FBOperationHelper getRequestUrlForEventsOnObjectId:objectId startDate:since endDate:until];
        [dictionary setObject:@"GET" forKey:@"method"];
        [dictionary setObject:relativeUrl forKey:@"relative_url"];
        
        [batch addObject:dictionary];
    }
    
    [payload setObject:batch forKey:@"batch"];
    
    [payload setObject:accessToken forKey:@"access_token"];
    
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:payload options:kNilOptions error:&error];
    
//        NSArray *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
//        NSLog(@"\n\nPayload:\n%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
    return data;
    
}

+ (NSString *)getRequestUrlForEventsOnObjectId:(NSString *)objectId
                                     startDate:(NSDate *)startDate
                                       endDate:(NSDate *)endDate {
    
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString *since = @"";
    if(startDate) {
        since = [NSString stringWithFormat:@"&since=%@", [formatter stringFromDate:startDate]];
    }
    
    NSString *until = @"";
    if(endDate) {
        until = [NSString stringWithFormat:@"&until=%@", [formatter stringFromDate:endDate]];
    }
    
    NSString *url = [NSString stringWithFormat:@"%@/events?pretty=0&limit=1000%@%@&fields=description,name,place,owner,start_time,end_time,rsvp_status", objectId, since, until];
    
    return url;
}

@end
