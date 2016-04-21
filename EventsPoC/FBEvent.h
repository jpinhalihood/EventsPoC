//
//  FBEvent.h
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-12.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EventProtocol.h"


@interface FBEvent : NSObject<EventProtocol, NSCopying>

@property (nonatomic, strong) NSNumber *eventId;
@property (nonatomic, strong) NSString *eventName;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSDate *endTime;
@property (nonatomic, strong) NSString *coverArtUrl;
@property (nonatomic, strong) NSString *placeName;
@property (nonatomic, strong) NSString *placeStreet;
@property (nonatomic, strong) NSString *placeCity;
@property (nonatomic, strong) NSString *placeCountry;
@property (nonatomic, strong) NSString *placeState;
@property (nonatomic, strong) NSString *placeZip;
@property (nonatomic, strong) NSNumber *placeLongitude;
@property (nonatomic, strong) NSNumber *placeLattitude;
@property (nonatomic, strong) NSString *eventHost;
@property (nonatomic, strong) NSString *rsvpStatus;
@property (nonatomic, strong) NSString *eventDescription;
- (instancetype)initWithDictionary:(NSDictionary *)json;

@end
