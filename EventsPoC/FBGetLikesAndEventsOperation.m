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
#import "EventsList.h"
#import "FBConstants.h"
#import "FBOperationHelper.h"



@interface FBGetLikesAndEventsOperation()
@property (nonatomic, strong) EventsList *events;
@property (nonatomic, strong) NSArray<NSString *> *objectIds;
@property (nonatomic, copy) void (^completionAction)(EventsList *, NSError *);
@end

@implementation FBGetLikesAndEventsOperation

-(instancetype)initWithCompletion:(void (^) (EventsList *, NSError *))completion {
    if(self = [super init]) {
        _completionAction = completion;
        _identifier = @"me";
        _events = [EventsList new];
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
            NSArray<NSString *> *likeObjectIds = [self getLikeObjectIdsWithAccessToken:accessToken];
            NSMutableSet *setOfLikeObjectIds = [NSMutableSet setWithArray:likeObjectIds];

            // Get object ids for friends
            NSArray<NSString *> *friendObjectIds = [self getFriendObjectIdsWithAccessToken:accessToken];
            NSMutableSet *setOfFriendObjectIds = [NSMutableSet setWithArray:friendObjectIds];

            // Union to eliminate the duplicates
            NSMutableSet *combinedSetOfObjectIds = [NSMutableSet setWithSet:setOfLikeObjectIds];
            [combinedSetOfObjectIds unionSet:setOfFriendObjectIds];
            
            self.objectIds = [combinedSetOfObjectIds allObjects];
            
            if(self.isCancelled) {
                return;
            }
            
            NSArray<NSArray *> *buckets = [FBOperationHelper makeBucketsWithObjectIds:self.objectIds];

            if(self.isCancelled) {
                return;
            }

            // Get events
            NSError *error = nil;
            EventsList *allEvents = [self getEventsForObjectIds:buckets accessToken:accessToken error:&error];
            
            if(self.completionAction) {
                self.completionAction(allEvents, error);
            }

            [self completeOperation];
        
        }
    }
    
}

- (EventsList *)getEventsForObjectIds:(NSArray<NSArray *> *)buckets
                          accessToken:(NSString *)accessToken
                                error:(__autoreleasing NSError **)error {

    EventsList *events = [EventsList new];
    for(NSArray *bucket in buckets) {
        
        if(self.isCancelled) {
            break;
        }
        
        NSMutableArray *newEvents = nil;
        NSData *payload = [FBOperationHelper getBatchRequestDataWithObjectIds:bucket
                                                                    startDate:self.startDate
                                                                      endDate:self.endDate
                                                                  accessToken:accessToken];
        NSString *url = FBGraphApiBaseUrl;
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
                [events mergeItems:newEvents];
            }
        }
        
        *error = fetchError;
    }
    
    
    return events;
}




- (NSArray<NSString *> *)getLikeObjectIdsWithAccessToken:(NSString *)accessToken {

    NSString *url = [NSString stringWithFormat:@"%@/%@/likes?access_token=%@&pretty=0&limit=100&fields=id", FBGraphApiBaseUrl, self.identifier, accessToken];
    
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

- (NSArray<NSString *> *)getFriendObjectIdsWithAccessToken:(NSString *)accessToken {
    
    NSString *url = [NSString stringWithFormat:@"%@/%@/friends?access_token=%@&pretty=0&limit=100&fields=id", FBGraphApiBaseUrl, self.identifier, accessToken];
    
    NSError *error = nil;
    NSMutableArray<NSString *> *objectIds = [NSMutableArray new];
    [objectIds addObject:self.identifier];
    
    while (url != nil && !self.isCancelled) {
        
        NSDictionary *json = nil;
        url = [self fetchDataForUrl:url json:&json error:&error];
        
        if(json && !error) {
            NSArray<NSDictionary*> *dataJson = [json objectForKey:@"data"];
            for(NSDictionary *likeJson in dataJson) {
                NSString *objectId = (NSString *)[likeJson objectForKey:@"id"];
                [objectIds addObject:objectId];
            }
        }
    }
    
    return [NSArray arrayWithArray:objectIds];
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
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60 * 5];
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
