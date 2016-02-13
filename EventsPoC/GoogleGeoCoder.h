//
//  GoogleGeoCoder.h
//  EventsPoC
//
//  Created by Jeff Price on 2013-07-09.
//  Copyright (c) 2013 Jeff Price. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GeoCoder.h"

#define GOOGLE_MAPS_API_URL @"https://maps.googleapis.com/maps/api/geocode/json?sensor=true"

typedef void (^GoogleGeoCoderCompletionAction)(NSDictionary * _Nullable data, NSError * _Nullable error);

@interface GoogleGeoCoder : NSOperation
@property (nonatomic, copy) _Nullable GoogleGeoCoderCompletionAction completionAction;


-(id _Nonnull)initWithAddress:(NSString  * _Nonnull)address;

@end
