//
//  FBGetEventsOperation.m
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-12.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import "FBGetEventsOperation.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "FBEvent.h"
#import "FBConstants.h"


NSUInteger const FBGetEventsOperationDefaultLimit = 10;

@interface FBGetEventsOperation()
@property (nonatomic, strong) NSMutableArray<FBEvent*> *events;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, copy) void (^completionAction)(NSArray<FBEvent*>*, NSError *);
@end

@implementation FBGetEventsOperation

-(instancetype)initWithObjectId:(NSString *)identifier completion:(void (^) (NSArray<FBEvent*> *, NSError *))completion {
    if(self = [super init]) {
        _completionAction = completion;
        _identifier = identifier;
        _limit = FBGetEventsOperationDefaultLimit;
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
            
            NSString *url = [self getRequestUrl];
            NSError *error = nil;
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

            NSArray *allEvents = [NSArray arrayWithArray:self.events];
            if(self.completionAction) {
                self.completionAction(allEvents, error);   
            }
            [self completeOperation];
        }
    }
}

- (NSString *)getRequestUrl {
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
    
    
    NSString *url = [NSString stringWithFormat:@"%@/%@/events?access_token=%@&pretty=0&limit=%lul&fields=id,name,description,start_time,end_time,rsvp_status,cover,place%@%@", FBGraphApiBaseUrl, self.identifier, accessToken, (unsigned long)self.limit, since, until];
    
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

- (NSString *)getNextUrlFromJson:(NSDictionary *)pagingJson {
    return pagingJson[@"next"];
}

- (void)completeOperation {
    self.completionAction = nil;
    [super completeOperation];
}

- (void)cancel {
    [self.task cancel];
    [super cancel];
}
@end
