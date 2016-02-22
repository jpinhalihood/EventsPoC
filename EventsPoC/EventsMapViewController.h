//
//  MapViewController.h
//  EventsPoC
//
//  Created by Jeff Price on 2013-06-26.
//  Copyright (c) 2013 Jeff Price. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

#import "SegmentedViewControllerProtocol.h"

@interface EventsMapViewController : UIViewController<MKMapViewDelegate, CLLocationManagerDelegate, SegmentedViewControllerProtocol>

@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@end
