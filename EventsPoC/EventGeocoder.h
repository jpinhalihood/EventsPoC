//
//  EventGeocoder.h
//  EventsPoC
//
//  Created by Jeff Price on 2013-06-27.
//  Copyright (c) 2013 Jeff Price. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>


@interface EventGeocoder : NSObject
@property (nonatomic, strong) NSMutableArray *convertedItems;
@end
