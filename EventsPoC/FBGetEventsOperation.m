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

@interface FBGetEventsOperation()
@property (nonatomic, weak) NSURLSessionDataTask *task;
@property (nonatomic, strong) NSMutableArray<FBEvent*> *events;
@property (nonatomic, strong) NSString *user;
@property (nonatomic, copy) void (^completionAction)(NSArray<FBEvent*>*, NSError *);
@end

@implementation FBGetEventsOperation

-(instancetype)initWithUser:(NSString *)user completion:(void (^) (NSArray<FBEvent*> *, NSError *))completion {
    if(self = [super init]) {
        _completionAction = completion;
        _user = user;
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
            NSString *accessToken = [FBSDKAccessToken currentAccessToken].tokenString;
            NSString *url = [NSString stringWithFormat:@"https://graph.facebook.com/v2.5/%@/events?access_token=%@&pretty=0&limit=1000&fields=id,name,description,start_time,end_time,rsvp_status,cover,place", self.user, accessToken];
            
            NSError *error = nil;
            
            while (url != nil && !self.isCancelled) {
                NSMutableArray *newEvents = nil;
                url = [self fetchEventsForUrl:url events:&newEvents error:&error];
                
                [self.events addObjectsFromArray:newEvents];
            }

            NSArray *allEvents = [NSArray arrayWithArray:self.events];
            self.completionAction(allEvents, error);
            [self completeOperation];
        }
    }
}

- (NSString *)fetchEventsForUrl:(NSString *)url events:(__autoreleasing NSMutableArray<FBEvent*> **)events error:(__autoreleasing NSError **)error {

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSDictionary *json = nil;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if(((NSHTTPURLResponse *)response).statusCode / 100 == 2) {
            if(data && !error) {
                NSError *parseError = nil;
                json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&parseError];
            }
            
            dispatch_semaphore_signal(semaphore);
        }
        
    }];
    
    [task resume];
    
    // wait until the task is done
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    NSString *nextUrl = nil;
    if(json) {
        NSArray<NSDictionary*> *dataJson = [json objectForKey:@"data"];
        NSDictionary *pagingJson = [json objectForKey:@"paging"];
        *events = [self getEventsFromJsonArray:dataJson];
        nextUrl = [self getNextUrlFromJson:pagingJson];
        *error = nil;
    }
    
    return nextUrl;
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
