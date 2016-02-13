//
//  OAAuthorization.m
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-10.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import "OAAuthorization.h"

@interface OAAuthorization()
@property (nonatomic, readwrite) NSString *accessToken;
@property (nonatomic, readwrite) NSNumber *expiryInSeconds;
@property (nonatomic, readwrite) NSDate *expiryDate;
@end

@implementation OAAuthorization

+ (OAAuthorization *)sharedInstance {
    static dispatch_once_t onceToken;
    static OAAuthorization *shared = nil;
    dispatch_once(&onceToken, ^{
        shared = [self new];
    });
    
    return shared;
}


- (void)startWithAccessToken:(NSString *)token expiryInSeconds:(NSNumber *)expiry {
    _accessToken = token;
    _expiryInSeconds = expiry;
}

- (NSDate *)expiryDate {
    if(self.expiryInSeconds) {
        return [NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)self.expiryInSeconds.longValue];
    } else {
        return nil;
    }
}

- (BOOL)isExpired
{
    return (!self.expiryDate || [self.expiryDate compare:[NSDate new]] == NSOrderedDescending);
}

@end
