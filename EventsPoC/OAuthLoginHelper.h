//
//  OAuthLoginHelper.h
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-10.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAuthLoginHelper : NSObject
+ (NSString *)generateRandomStateWithLength:(NSUInteger)length;
+ (NSString *)valueForToken:(NSString *)token fromString:(NSString *)string;
@end
