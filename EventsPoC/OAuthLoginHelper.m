//
//  OAuthLoginHelper.m
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-10.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import "OAuthLoginHelper.h"

@implementation OAuthLoginHelper

+ (NSString *)generateRandomStateWithLength:(NSUInteger)length {
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity:length];
    
    for (int i=0; i<length; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex:arc4random_uniform((int)[letters length])]];
    }
    
    return randomString;
}

+ (NSString *)valueForToken:(NSString *)token fromString:(NSString *)string {
    NSString *valueForToken = nil;
    NSString *delim = @"&";
    NSRange rangeOfToken = [string rangeOfString:token];
    if(rangeOfToken.location != NSNotFound) {
        NSUInteger index = rangeOfToken.location + rangeOfToken.length;
        NSString *stringAfterToken = [string substringFromIndex:index];
        NSRange rangeOfDelim = [stringAfterToken rangeOfString:delim];
        if(rangeOfDelim.location != NSNotFound) {
            valueForToken = [stringAfterToken substringToIndex:rangeOfDelim.location];
        } else {
            valueForToken = stringAfterToken;
        }
    }
    
    return valueForToken;
}
@end
