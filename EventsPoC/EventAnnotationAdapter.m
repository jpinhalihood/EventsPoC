//
//  AnnotationAdapter.m
//  EventsPoC
//
//  Created by Jeff Price on 2013-10-24.
//  Copyright (c) 2013 Jeff Price. All rights reserved.
//
#import <CoreLocation/CoreLocation.h>

#import "EventAnnotationAdapter.h"
#import "EventAnnotation.h"
#import "EventProtocol.h"
#import "EventsList.h"


@implementation EventAnnotationAdapter

+(EventAnnotation *)adaptFromJSON:(NSDictionary *)json
{
    NSDictionary *geometry = [json objectForKey:@"geometry"];
    NSDictionary* location = [geometry objectForKey: @"location"];
    NSString* lattitude = (NSString*)[location valueForKey: @"lat"];
    NSString* longitude = (NSString*)[location valueForKey: @"lng"];
    
    CLLocationCoordinate2D coords;
    coords.latitude = [lattitude doubleValue];
    coords.longitude = [longitude doubleValue];
    
    EventAnnotation* annotation = [[EventAnnotation alloc] initWithCoordinate:coords title:@"Event Title" subtitle:@"Event Sub-title"];
    return annotation;
    
}

+(NSArray<EventAnnotation *> *)makeAnnotationsFromGoogleGeoCodeLocationJson:(NSDictionary *)json
{
    NSArray *results = [json objectForKey:@"results"];
    NSMutableArray<EventAnnotation *> *annotations = [NSMutableArray new];
    if(results && results.count > 0) {
        for(NSDictionary *result in results) {
            EventAnnotation* annotation = [EventAnnotationAdapter adaptFromJSON:result];
            [annotations addObject:annotation];
        }
    }
    
    return [NSArray arrayWithArray:annotations];
}

+(EventAnnotation *)adaptFromEvent:(NSObject<EventProtocol> *)event {
    CLLocationCoordinate2D coords;
    coords.latitude = [event.placeLattitude doubleValue];
    coords.longitude = [event.placeLongitude doubleValue];
    
    EventAnnotation* annotation = [[EventAnnotation alloc] initWithCoordinate:coords title:event.eventName subtitle:event.eventDescription];
    return annotation;
}

+(NSArray<EventAnnotation *> *)adaptFromEventsList:(EventsList *)events {
    NSMutableArray<EventAnnotation *> *annotations = [NSMutableArray new];
    for(NSObject<EventProtocol> *event in events.allItems) {
        EventAnnotation *annotation = [EventAnnotationAdapter adaptFromEvent:event];
        [annotations addObject:annotation];
    }
    return [NSArray arrayWithArray:annotations];
}

@end
