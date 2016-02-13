//
//  EventAnnotation.h
//  EventsPoC
//
//  Created by Jeff Price on 2013-06-26.
//  Copyright (c) 2013 Jeff Price. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>



@interface EventAnnotation : NSObject<MKAnnotation>

-(MKMapItem *)mapItem;

-(id)initWithCoordinate:(CLLocationCoordinate2D)eventCoord
                  title:(NSString *)eventTitle
               subtitle:(NSString *)eventSubtitle;


@end

