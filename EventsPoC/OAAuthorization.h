//
//  OAAuthorization.h
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-10.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAAuthorization : NSObject
@property (nonatomic, readonly) NSString *accessToken;
@property (nonatomic, readonly) NSNumber *expiryInSeconds;
@property (nonatomic, readonly) NSDate *expiryDate;

+ (OAAuthorization *)sharedInstance;
- (void)startWithAccessToken:(NSString *)token expiryInSeconds:(NSNumber *)expiry;
- (BOOL)isExpired;
@end
