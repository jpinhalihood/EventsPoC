//
//  Event.h
//  EventsPoC
//
//  Created by Jeff Price on 2013-10-24.
//  Copyright (c) 2013 Jeff Price. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EventAnnotation.h"
#import "EventProtocol.h"
@interface MapEvent : NSObject

@property (nonatomic, strong) EventAnnotation* annotation;
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSString* subtitle;
@property (nonatomic, strong) NSString* eventDescription;
@property (nonatomic, strong) NSString* startTimeEpoch;
@property (nonatomic, strong) NSString* endTimeEpoch;
@property (nonatomic, strong) NSString* host;
@property (nonatomic, strong) NSString* address;
@end
