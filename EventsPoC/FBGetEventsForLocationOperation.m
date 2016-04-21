//
//  FBGetEventsForLocationOperation.m
//  NearMe
//
//  Created by Jeff Price on 2016-03-25.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import "FBGetEventsForLocationOperation.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "FBEvent.h"
#import "EventsList.h"
#import "FBConstants.h"
#import "FBOperationHelper.h"

double const FBGetEventsForLocationOperationDefaultRadiusInMeters = 1000 * 200; // 200 km in meters

@interface FBGetEventsForLocationOperation()
@property (nonatomic, strong) EventsList *events;
@property (nonatomic, strong) NSArray<NSString *> *objectIds;
@property (nonatomic, copy) void (^completionAction)(EventsList *, NSError *);
@property (nonatomic, strong) NSURLSessionTask *task;
@end


@implementation FBGetEventsForLocationOperation


-(instancetype)initWithLocationName:(NSString *)locationName
                         completion:(void (^) (EventsList *, NSError *))completion {
    if(self = [super init]) {
        _radius = [NSNumber numberWithDouble:FBGetEventsForLocationOperationDefaultRadiusInMeters];
        _identifier = locationName;
        _completionAction = completion;
        _events = [EventsList new];
    }
    return self;
}

- (void)main {
    
    @autoreleasepool {
        if(self.isCancelled || !self.identifier) {
            [self completeOperation];
            return;
        }
        
        if([[FBSDKAccessToken currentAccessToken].expirationDate compare:[NSDate new]] == NSOrderedDescending) {
            
            NSString *accessToken = [FBSDKAccessToken currentAccessToken].tokenString;
            
            // Get object ids for likes
            self.objectIds = [self getPlaceObjectIdsWithAccessToken:accessToken];
            
            if(self.isCancelled) {
                return;
            }
            
            NSArray<NSArray *> *buckets = [FBOperationHelper makeBucketsWithObjectIds:self.objectIds];
            
            if(self.isCancelled) {
                return;
            }
            
            // Get events
            NSError *error = nil;
            self.events = [self getEventsForObjectIds:buckets accessToken:accessToken error:&error];

            // Sort by start time earliest to latest
            NSSortDescriptor *sortByStartDateDesc = [NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:NO];
            [self.events sortUsingDescriptors:@[sortByStartDateDesc]];
            
            if(self.completionAction) {
                self.completionAction(self.events, error);
            }
        }
        
        [self completeOperation];
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
        
        EventsList *newEvents = nil;
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
                
                for(NSObject<EventProtocol> *event in newEvents.allItems) {
                    NSLog(@"Event: %@, Starts: %@ Ends: %@ Location: %@", event.eventName, event.startTime, event.endTime, event.placeName);
                }
                
                [events mergeItems:newEvents.allItems];
            }
        }
        
        *error = fetchError;
    }
    
    
    return events;
}

- (NSArray<NSString *> *)getPlaceObjectIdsWithAccessToken:(NSString *)accessToken {
    
    NSString *center = @"";
    if(self.latitude && self.longitude && self.radius) {
        center = [NSString stringWithFormat:@"&center=%@,%@&distance=%@", self.latitude.stringValue, self.longitude.stringValue, self.radius.stringValue];
    }
    
    NSString *url = [NSString stringWithFormat:@"%@/search?q=&type=place%@&pretty=0&limit=100&fields=id&access_token=%@", FBGraphApiBaseUrl, center, accessToken];
    
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


- (EventsList *)getEventsFromJsonArray:(NSArray<NSDictionary*> *)json {
    EventsList *events = [EventsList new];
    for(NSDictionary *eventJson in json) {
        FBEvent *event = [[FBEvent alloc] initWithDictionary:eventJson];
        [events add:event];
    }
    
    return events;
}


- (NSString *)fetchDataForUrl:(NSString *)url
                         json:(__autoreleasing NSDictionary **)returnJson
                        error:(__autoreleasing NSError **)returnError {
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSDictionary *json = nil;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
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
        NSDictionary *pagingJson = [json objectForKey:@"paging"];
        nextUrl = [self getNextUrlFromJson:pagingJson];
        *returnError = nil;
        *returnJson = json;
    }
    
    return nextUrl;
}


- (NSString *)fetchDataForUrl:(NSString *)url
                         body:(NSData *)payload
                         json:(__autoreleasing NSArray **)returnJson
                        error:(__autoreleasing NSError **)returnError {
    
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


- (NSString *)getNextUrlFromJson:(NSDictionary *)pagingJson {
    return pagingJson[@"next"];
}

- (void)cancel {
    [self.task cancel];
    [super cancel];
}

@end
