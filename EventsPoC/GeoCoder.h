//
//  GeoCoder.h
//  EventsPoC
//
//  Created by Jeff Price on 2013-07-09.
//  Copyright (c) 2013 Jeff Price. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GeoCoder <NSObject>

- (void) geocodeAddress: (NSString*) address
             onComplete:(void (^)()) completionHandler
                onError: (void(^)(NSError*)) errorHandler;

@end
