//
//  FBGetLikesEventsOperation.m
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-18.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import "FBGetLikesEventsOperation.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "FBEvent.h"
#import "FBGetEventsOperation.h"


@interface FBGetLikesEventsOperation()
@property (nonatomic, strong) NSMutableArray<FBEvent*> *events;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, copy) void (^completionAction)(NSArray<FBEvent*>*, NSError *);
@end

@implementation FBGetLikesEventsOperation

-(instancetype)initWithObjectIds:(NSArray<NSString *> *)objectIds completion:(void (^) (NSArray<FBEvent*> *, NSError *))completion {
    if(self = [super init]) {
        _completionAction = completion;
        _objectIds = objectIds;
    }
    return self;
}

- (void)main {
    @autoreleasepool {
        if(self.isCancelled) {
            return;
        }
        
        self.events = [NSMutableArray new];
        if([[FBSDKAccessToken currentAccessToken].expirationDate compare:[NSDate new]] == NSOrderedDescending) {

            NSError *error = nil;
            for(NSString *objectId in self.objectIds) {
                NSString *url = [self getRequestUrlWithObjectId:objectId];
                
                // Get all pages
                while (url != nil && !self.isCancelled) {
                    
                    NSMutableArray *newEvents = nil;
                    NSDictionary *json = nil;
                    
                    url = [self fetchDataForUrl:url json:&json error:&error];
                    if(json && !error) {
                        NSArray<NSDictionary*> *dataJson = [json objectForKey:@"data"];
                        newEvents = [self getEventsFromJsonArray:dataJson];
                    }
                    
                    [self.events addObjectsFromArray:newEvents];
                    
                }
            }
   
            
            NSArray *allEvents = [NSArray arrayWithArray:self.events];
            self.completionAction(allEvents, error);
            [self completeOperation];
        }
    }
}


- (NSString *)getRequestUrlWithObjectId:(NSString *)objectId {
    NSString *accessToken = [FBSDKAccessToken currentAccessToken].tokenString;
    
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
    
    NSString *url = [NSString stringWithFormat:@"https://graph.facebook.com/v2.5/%@/events?access_token=%@&pretty=0&limit=1000%@%@", objectId, accessToken, since, until];
    
    return url;
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

@end
