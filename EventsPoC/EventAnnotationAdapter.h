//
//  AnnotationAdapter.h
//  EventsPoC
//
//  Created by Jeff Price on 2013-10-24.
//  Copyright (c) 2013 Jeff Price. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EventProtocol.h"

@class EventAnnotation;
@class EventsList;

@interface EventAnnotationAdapter : NSObject

+(EventAnnotation*) adaptFromJSON:(NSDictionary *)json;
+(NSArray<EventAnnotation *> *)makeAnnotationsFromGoogleGeoCodeLocationJson:(NSDictionary *)json;
+(EventAnnotation *)adaptFromEvent:(NSObject<EventProtocol> *)event;
+(NSArray<EventAnnotation *> *)adaptFromEventsList:(EventsList *)events;
@end
