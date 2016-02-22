//
//  AppState.h
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-18.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EventsList;

@interface AppState : NSObject
@property (nonatomic, strong, readwrite) EventsList *events;

+ (AppState *)sharedInstance;
- (void)save;
@end
