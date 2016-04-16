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
        if(self.isCancelled) {
            return;
        }
        
        if([[FBSDKAccessToken currentAccessToken].expirationDate compare:[NSDate new]] == NSOrderedDescending) {
            
            NSString *url = [self getRequestUrl];
            NSError *error = nil;
            while (url != nil && !self.isCancelled) {
                
                EventsList *newEvents = nil;
                NSDictionary *json = nil;
                
                url = [self fetchDataForUrl:url json:&json error:&error];
                if(json && !error) {
                    NSArray<NSDictionary*> *dataJson = [json objectForKey:@"data"];
                    newEvents = [self getEventsFromJsonArray:dataJson];
                }
                
                [self.events mergeItems:newEvents.allItems];
                
            }
            
            NSSortDescriptor *sortByStartDateDesc = [NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:NO];
            [self.events sortUsingDescriptors:@[sortByStartDateDesc]];
            
            if(self.completionAction) {
                self.completionAction(self.events, error);
            }
            [self completeOperation];
        }
        
    }
    
}

- (NSString *)getRequestUrl {
    NSString *accessToken = [FBSDKAccessToken currentAccessToken].tokenString;
    
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZ"];//2016-04-08T16:00:00-0300
    NSString *since = @"";
    if(self.startDate) {
        since = [NSString stringWithFormat:@"&since=%@", [formatter stringFromDate:self.startDate]];
    }
    
    NSString *until = @"";
    if(self.endDate) {
        until = [NSString stringWithFormat:@"&until=%@", [formatter stringFromDate:self.endDate]];
    }
    
    NSString *center = @"";
    if(self.latitude && self.longitude && self.radius) {
        center = [NSString stringWithFormat:@"&center=%@,%@&distance=%@", self.latitude.stringValue, self.longitude.stringValue, self.radius.stringValue];
    }
    
    NSMutableCharacterSet *allowed = [NSMutableCharacterSet alphanumericCharacterSet];
    NSString *unreserved = @"-._~/?";
    [allowed addCharactersInString:unreserved];
    NSString *query = [self.identifier stringByAddingPercentEncodingWithAllowedCharacters:allowed];
    
    NSString *url = [NSString stringWithFormat:@"https://graph.facebook.com/v2.5/search?q=%@&type=event%@%@%@&access_token=%@", query, center, since, until, accessToken];
    
    return url;
}





- (EventsList *)getEventsFromJsonArray:(NSArray<NSDictionary*> *)json {
    EventsList *events = [EventsList new];
    for(NSDictionary *eventJson in json) {
        FBEvent *event = [[FBEvent alloc] initWithDictionary:eventJson];
        [events add:event];
    }
    
    return events;
}


- (NSString *)fetchDataForUrl:(NSString *)url json:(__autoreleasing NSDictionary **)returnJson error:(__autoreleasing NSError **)returnError {
    
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


- (NSString *)getNextUrlFromJson:(NSDictionary *)pagingJson {
    return pagingJson[@"next"];
}

- (void)cancel {
    [self.task cancel];
    [super cancel];
}

@end
