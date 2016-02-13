//
//  GoogleGeoCoder.m
//  EventsPoC
//
//  Created by Jeff Price on 2013-07-09.
//  Copyright (c) 2013 Jeff Price. All rights reserved.
//

#import "GoogleGeoCoder.h"


@interface GoogleGeoCoder()
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSURLSessionDataTask *task;
@end

@implementation GoogleGeoCoder

-(id)initWithAddress:(NSString *)address
{
    if(self = [super init]) {
        _address = address;
    }
    return self;
}


-(void)main
{
    @autoreleasepool {
        if(self.isCancelled) {
            return;
        }
        
        NSString *urlEncodedAddress = [self.address stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        
        NSString *requestStr = [NSString stringWithFormat:@"%@&address=%@", GOOGLE_MAPS_API_URL, urlEncodedAddress];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestStr]];
        [request setHTTPMethod: @"GET"];
        
        if(self.isCancelled) {
            return;
        }
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        self.task = [session dataTaskWithRequest:request
                               completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                   
                                   if(!self.isCancelled && self.completionAction) {
                                       
//                                       NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//                                       NSLog(@"RESPONSE >>\n %@", json);
                                       
                                       NSError* parseError = nil;
                                       NSDictionary* dictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                                                  options:kNilOptions
                                                                                                    error:&parseError];
                                       
                                       self.completionAction(dictionary, error);
                                   }
                                   
                               }];
        [self.task resume];
        
    }
}


-(void)geocodeAddress:(NSString *)address
{
    
}


@end
