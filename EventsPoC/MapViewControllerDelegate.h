//
//  MapViewControllerDelegate.h
//  EventsPoC
//
//  Created by Jeff Price on 2013-10-23.
//  Copyright (c) 2013 Jeff Price. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>


@interface MapViewControllerDelegate : NSObject<MKMapViewDelegate>


- (id) initWithSegue: (NSString*) segueName
  fromViewController: (UIViewController*) source;

@end
