//
//  GoogleGeoCoderLocationDO.m
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-03.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import "GoogleGeoCoderLocationDO.h"
#import <CoreLocation/CoreLocation.h>

@interface GoogleGeoCoderLocationDO()
@property (nonatomic, assign) NSDictionary *json;
@end

@implementation GoogleGeoCoderLocationDO

-(instancetype)initWithJsonDictionary:(NSDictionary *)json
{
    if(self = [super init]) {
        _json = json;
    }
    return self;
}

-(CLLocationCoordinate2D)coordinates
{
    NSArray *results = [self.json objectForKey:@"results"];
    NSDictionary *geometry = [results.firstObject objectForKey:@"geometry"];
    NSDictionary *location = [geometry objectForKey:@"location"];
    NSNumber *lat = [location objectForKey:@"lat"];
    NSNumber *lng = [location objectForKey:@"lng"];
    
    return CLLocationCoordinate2DMake(lat.doubleValue, lng.doubleValue);
}
@end
