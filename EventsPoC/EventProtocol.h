//
//  EventProtocol.h
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-18.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#ifndef EventProtocol_h
#define EventProtocol_h

@protocol EventProtocol <NSObject>

@property (nonatomic, strong) NSNumber *eventId;
@property (nonatomic, strong) NSString *eventName;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSDate *endTime;
@property (nonatomic, strong) NSString *eventDescription;
@property (nonatomic, strong) NSNumber *placeLongitude;
@property (nonatomic, strong) NSNumber *placeLattitude;
@property (nonatomic, strong) NSString *eventHost;

@end
#endif /* EventProtocol_h */
