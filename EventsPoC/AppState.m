//
//  AppState.m
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-18.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import "AppState.h"
#import "EventsList.h"


@interface AppState()
@end

@implementation AppState

+ (AppState *)sharedInstance {
    static AppState *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [AppState new];
    });
    return shared;
}

- (instancetype)init {
    if(self = [super init]) {
        _events = [EventsList new];
    }
    
    return self;
}


- (EventsList *)events {
    @synchronized(self) {
        return _events;
    }
}

- (void)setEventsList:(EventsList *)events {
    @synchronized(self) {
        _events = events;
    }
}

- (void)save {
    // save to disk
}

@end
