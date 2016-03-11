//
//  FBSession.h
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-17.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

@interface FBSession : NSObject
+ (NSString *)getAccessToken;
+ (void)renewFromViewController:(UINavigationController *)callingVc;
@end
