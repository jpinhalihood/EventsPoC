//
//  FBEvent.m
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-12.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import "FBEvent.h"

NSString * const KeyFBEventId = @"id";
NSString * const KeyFBEventName = @"name";
NSString * const KeyFBEventStartTime = @"start_time";
NSString * const KeyFBEventEndTime = @"end_time";
NSString * const KeyFBEventCover = @"cover";
NSString * const KeyFBEventCoverSource = @"source";
NSString * const KeyFBEventPlace = @"place";
NSString * const KeyFBEventPlaceStreet = @"street";
NSString * const KeyFBEventPlaceCity = @"city";
NSString * const KeyFBEventPlaceState = @"state";
NSString * const KeyFBEventPlaceCountry = @"country";
NSString * const KeyFBEventPlaceZip = @"zip";
NSString * const KeyFBEventPlaceName = @"name";
NSString * const KeyFBEventPlaceLocation = @"location";
NSString * const KeyFBEventPlaceLocationLat = @"latitude";
NSString * const KeyFBEventPlaceLocationLng = @"longitude";
NSString * const KeyFBEventDescription = @"description";
NSString * const KeyFBEventRsvpStatus = @"rsvp_status";
NSString * const KeyFBEventHost = @"owner";


@implementation FBEvent

- (instancetype)initWithDictionary:(NSDictionary *)json {
    if(self = [super init]) {
        NSNumberFormatter *numberFormatter = [NSNumberFormatter new];
        if([json[KeyFBEventId] isKindOfClass:[NSString class]]) {
            _eventId = [numberFormatter numberFromString:json[KeyFBEventId]];
        }
        else {
            _eventId = json[KeyFBEventId];
        }
                
        _eventName = json[KeyFBEventName];
        _eventDescription = json[KeyFBEventDescription];
        _rsvpStatus = json[KeyFBEventRsvpStatus];
        
        NSDictionary *host = json[KeyFBEventHost];
        _eventHost = host[KeyFBEventName];
        
        NSDateFormatter *formatter = [NSDateFormatter new];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZ"];
        NSString *dateTime = json[KeyFBEventStartTime];
        _startTime = [formatter dateFromString:dateTime];

        dateTime = json[KeyFBEventEndTime];
        _endTime = [formatter dateFromString:dateTime];
        
        
        NSDictionary *cover = [json objectForKey:KeyFBEventCover];
        _coverArtUrl = cover[KeyFBEventCoverSource];
        
        NSDictionary *place = json[KeyFBEventPlace];
        _placeName = place[KeyFBEventPlaceName];
        
        NSDictionary *location = place[KeyFBEventPlaceLocation];
        _placeStreet = location[KeyFBEventPlaceStreet];
        _placeCity = location[KeyFBEventPlaceCity];
        _placeState = location[KeyFBEventPlaceState];
        _placeCountry = location[KeyFBEventPlaceCountry];
        _placeZip = location[KeyFBEventPlaceZip];
        _placeLattitude = location[KeyFBEventPlaceLocationLat];
        _placeLongitude = location[KeyFBEventPlaceLocationLng];

    }
    
    return self;
}

@end
