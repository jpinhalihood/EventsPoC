//
//  FBPagedApiOperation.m
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-18.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import "FBPagedApiOperation.h"

@implementation FBPagedApiOperation

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
