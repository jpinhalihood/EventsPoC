//
//  GetLikesAndEventsOperation.m
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-24.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import "FBGetLikesAndEventsOperation.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBEvent.h"


@interface FBGetLikesAndEventsOperation()
@property (nonatomic, strong) NSMutableArray<FBEvent*> *events;
@property (nonatomic, strong) NSArray<NSString *> *objectIds;
@property (nonatomic, copy) void (^completionAction)(NSArray<FBEvent*>*, NSError *);
@end

@implementation FBGetLikesAndEventsOperation

-(instancetype)initWithCompletion:(void (^) (NSArray<FBEvent*> *, NSError *))completion {
    if(self = [super init]) {
        _completionAction = completion;
        _identifier = @"me";
        _events = [NSMutableArray new];
    }
    return self;
}

- (void)main {
    
    @autoreleasepool {
        if(self.isCancelled) {
            return;
        }
        
        if([[FBSDKAccessToken currentAccessToken].expirationDate compare:[NSDate new]] == NSOrderedDescending) {
            NSString *accessToken = [FBSDKAccessToken currentAccessToken].tokenString;
            
            // Get object ids for likes
            self.objectIds = [self getObjectIdsWithAccessToken:accessToken];
            
            
            if(self.isCancelled) {
                return;
            }
            
            NSArray<NSArray *> *buckets = [self makeBucketsWithObjectIds:self.objectIds];

            if(self.isCancelled) {
                return;
            }

            // Get events
            NSError *error = nil;
            NSArray *allEvents = [self getEventsForObjectIds:buckets accessToken:accessToken error:&error];
            
            if(self.completionAction) {
                self.completionAction(allEvents, error);
            }

            [self completeOperation];
        
        }
    }
    
}

- (NSArray<FBEvent*> *)getEventsForObjectIds:(NSArray<NSArray *> *)buckets accessToken:(NSString *)accessToken error:(__autoreleasing NSError **)error {

    NSMutableArray<FBEvent *> *events = [NSMutableArray new];
    for(NSArray *bucket in buckets) {
        
        if(self.isCancelled) {
            break;
        }
        
        NSMutableArray *newEvents = nil;
        NSData *payload = [self getBatchRequestDataWithObjectIds:bucket accessToken:accessToken];
        NSString *url = @"https://graph.facebook.com/v2.5";
        NSArray<NSDictionary*> *results = nil;
        
        NSError *fetchError = nil;
        [self fetchDataForUrl:url body:payload json:&results error:&fetchError];
        if(self.isCancelled) {
            break;
        }
        
        if(results && !fetchError) {
            for(NSDictionary *dictionary in results) {
                NSString *body = [dictionary objectForKey:@"body"];
                NSData *bodyData = [body dataUsingEncoding:NSUTF8StringEncoding];
                NSError *parseError = nil;
                NSDictionary *bodyJson = [NSJSONSerialization JSONObjectWithData:bodyData options:kNilOptions error:&parseError];
                NSArray *eventsJson = [bodyJson objectForKey:@"data"];
                newEvents = [self getEventsFromJsonArray:eventsJson];
                [events addObjectsFromArray:newEvents];
            }
        }
        
        *error = fetchError;
    }
    
    
    return [NSArray arrayWithArray:events];
}


- (NSArray<NSString *> *)getObjectIdsWithAccessToken:(NSString *)accessToken {

    NSString *url = [NSString stringWithFormat:@"https://graph.facebook.com/v2.5/%@/likes?access_token=%@&pretty=0&limit=100", self.identifier, accessToken];
    
    NSError *error = nil;
    NSMutableArray<NSString *> *objectIds = [NSMutableArray new];
    [objectIds addObject:self.identifier];
    
    while (url != nil && !self.isCancelled) {
        
        NSDictionary *json = nil;
        url = [self fetchDataForUrl:url json:&json error:&error];
        
        if(json && !error) {
            NSArray<NSDictionary*> *dataJson = [json objectForKey:@"data"];
            for(NSDictionary *likeJson in dataJson) {
                NSString *objectId = [likeJson objectForKey:@"id"];
                [objectIds addObject:objectId];
            }
        }
    }
    
    return [NSArray arrayWithArray:objectIds];
}

- (NSArray<NSArray *> *)makeBucketsWithObjectIds:(NSArray<NSString *> *)objectIds {

    NSUInteger count=0;
    NSMutableArray<NSArray *> *buckets = [NSMutableArray new];
    NSMutableArray<NSString *> *currentBucket = [[NSMutableArray alloc] initWithCapacity:50];
    
    for(NSString *objectId in self.objectIds) {
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

- (NSString *)getRequestUrlWithObjectId:(NSString *)objectId {
    
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString *since = @"";
    if(self.startDate) {
        since = [NSString stringWithFormat:@"&since=%@", [formatter stringFromDate:self.startDate]];
    }
    
    NSString *until = @"";
    if(self.endDate) {
        until = [NSString stringWithFormat:@"&until=%@", [formatter stringFromDate:self.endDate]];
    }
    
    NSString *url = [NSString stringWithFormat:@"%@/events?pretty=0&limit=1000%@%@", objectId, since, until];
    
    return url;
}

- (NSData *)getBatchRequestDataWithObjectIds:(NSArray<NSString *> *)objectIds accessToken:(NSString *)accessToken {
    
    NSMutableDictionary *payload = [NSMutableDictionary new];
    NSMutableArray *batch = [[NSMutableArray alloc] initWithCapacity:objectIds.count];
    for(NSString *objectId in objectIds) {
        NSMutableDictionary *dictionary = [NSMutableDictionary new];
        NSString *relativeUrl = [self getRequestUrlWithObjectId:objectId];
        [dictionary setObject:@"GET" forKey:@"method"];
        [dictionary setObject:relativeUrl forKey:@"relative_url"];
        
        [batch addObject:dictionary];
    }
    
    [payload setObject:batch forKey:@"batch"];
    
    [payload setObject:accessToken forKey:@"access_token"];
    
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:payload options:kNilOptions error:&error];
    
    //    NSArray *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    //    NSLog(@"\n\nPayload:\n%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
    return data;
    
}


- (NSMutableArray<FBEvent*> *)getEventsFromJsonArray:(NSArray<NSDictionary*> *)json {
    NSMutableArray<FBEvent*> *events = [NSMutableArray new];
    for(NSDictionary *eventJson in json) {
        FBEvent *event = [[FBEvent alloc] initWithDictionary:eventJson];
        [events addObject:event];
    }
    
    NSSortDescriptor *sortByStartDateDesc = [NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:NO];
    [events sortUsingDescriptors:@[sortByStartDateDesc]];
    return events;
}



- (NSString *)fetchDataForUrl:(NSString *)url body:(NSData *)payload json:(__autoreleasing NSArray **)returnJson error:(__autoreleasing NSError **)returnError {
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSArray *json = nil;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:payload];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    self.task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if(((NSHTTPURLResponse *)response).statusCode / 100 == 2) {
            
            if(data && !error) {
                NSError *parseError = nil;
                json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&parseError];
            }
            
            dispatch_semaphore_signal(semaphore);
        }
        
    }];
    
    [self.task resume];
    
    // wait until the task is done
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    NSString *nextUrl = nil;
    if(json) {
        *returnError = nil;
        *returnJson = json;
    }
    
    return nextUrl;
}

@end
