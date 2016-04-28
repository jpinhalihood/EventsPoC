//
//  MapViewController.m
//  EventsPoC
//
//  Created by Jeff Price on 2013-06-26.
//  Copyright (c) 2013 Jeff Price. All rights reserved.
//

#import "EventsMapViewController.h"

#import "EventAnnotationAdapter.h"
#import "EventAnnotation.h"
#import "GoogleGeoCoder.h"
#import "MapViewControllerDelegate.h"
#import "EventDetailViewController.h"

#import "EventsList.h"
#import "MapEvent.h"
#import "EventNotifications.h"
#import "FBEvent.h"
#import "AppState.h"

#import "EventAnnotationCalloutView.h"
#import "DateView.h"

#import "EventsManager.h"

@interface EventsMapViewController ()
@property (nonatomic, strong) NSArray *addresses;
@property (nonatomic, strong) NSMutableArray *convertedItems;
@property (nonatomic, strong) MapViewControllerDelegate* mapDelegate;
@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, strong) EventsList *events;
@property (nonatomic, strong) EventsList *filteredEvents;
@property (nonatomic, strong) NSNumber *radius;

@property (nonatomic, strong) CLLocation *lastLocation;
@property (nonatomic, strong) NSDate *lastLocationUpdate;

@end

double const EventsMapDefaultRadius = 500000; // 50km in meters
NSTimeInterval const EventsMapDefaultLocationUpdateInterval = 60;

@implementation EventsMapViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _radius = [NSNumber numberWithDouble:EventsMapDefaultRadius];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor darkGrayColor]}];
    self.lastLocationUpdate = [NSDate new];
    self.radius = [NSNumber numberWithDouble:EventsMapDefaultRadius];
    
    self.mapView.delegate = self;
    [self addNotificationCenter];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [self.locationManager requestAlwaysAuthorization];
}

- (void)dealloc {
    [self removeNotificationCenter];
}


-(void)mapEvents:(EventsList *)events
{
    __weak typeof(self) weakSelf = self;
    NSArray<EventAnnotation *> *annotations = [EventAnnotationAdapter adaptFromEventsList:events];
    NSArray<MKPlacemark*> *placemarks = [weakSelf pinAnnotations:annotations];

    dispatch_async(dispatch_get_main_queue(), ^{
        // Remove the existing pins except for current location
        id currentLocation = self.mapView.userLocation;
        NSMutableArray *removableAnnotations = [[NSMutableArray alloc] initWithArray:self.mapView.annotations];
        if(currentLocation) {
            [weakSelf.mapView removeAnnotation:currentLocation];
        }
        
        [weakSelf.mapView removeAnnotations:removableAnnotations];
        
        // Add the list of pins
        [weakSelf.mapView addAnnotations:placemarks];
    });
}


-(NSArray<MKPlacemark*> *)pinAnnotations:(NSArray<EventAnnotation*> *)annotations
{
    NSMutableArray<MKPlacemark *> *placemarks = [[NSMutableArray alloc] initWithCapacity:annotations.count];
    for(EventAnnotation *annotation in annotations) {
        MKPlacemark *placemark = annotation.mapItem.placemark;
        [placemarks addObject:placemark];
    }
    
    return placemarks;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - MKMapViewDelegate Methods
- (void) mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {

    MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"pin"];
    if([annotation isKindOfClass:[MKPlacemark class]]) {
        if(!annotationView) {
            annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:nil reuseIdentifier:@"pin"];
            annotationView.canShowCallout = YES;
        }
        
        annotationView.annotation = annotation;
        
        EventAnnotationCalloutView *callout = [[[NSBundle mainBundle] loadNibNamed:@"EventAnnotationCalloutView" owner:self options:nil] firstObject];
        callout.hostLabel.text = @"Hosted by Johnny Appleseed";
        callout.addressLabel.text = @"31 Claudia Crescent, Middle Sackville, NS";
        [callout setDate:[NSDate new]];
        annotationView.detailCalloutAccessoryView = callout;
        
        NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:callout attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:200.0];
        NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:callout attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:111.0];
        
        [callout addConstraints:@[width, height]];
        
        
        annotationView.canShowCallout = YES;
        annotationView.rightCalloutAccessoryView = nil;
        
    }
    
    return annotationView;
    
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {    
    view.canShowCallout = YES;
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    
    CLLocationCoordinate2D centerCoord = mapView.centerCoordinate;
    CLLocation *centerLocation = [[CLLocation alloc] initWithLatitude:centerCoord.latitude longitude:centerCoord.longitude];
    CLLocationCoordinate2D topCoord = [mapView convertPoint:CGPointMake(floorf(self.mapView.bounds.size.width/2.0), 0.0) toCoordinateFromView:self.mapView];
    CLLocation *topLocation = [[CLLocation alloc] initWithLatitude:topCoord.latitude longitude:topCoord.longitude];
    CLLocationDistance radius = [topLocation distanceFromLocation:centerLocation];
    [EventsManager sharedInstance].radius = [NSNumber numberWithDouble:radius];
    
    NSLog(@"Region Changed- Radus: %f", radius);
}


#pragma mark - CLLocationManagerDelegate Methods
-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    self.mapView.showsUserLocation = (status == kCLAuthorizationStatusAuthorizedAlways);
    
    MKCoordinateRegion region;
    region.center.latitude = manager.location.coordinate.latitude;
    region.center.longitude = manager.location.coordinate.longitude;
    region.span.latitudeDelta = 0.010f;
    region.span.longitudeDelta = 0.010f;
    
    [self.mapView setRegion:region];
    
    [manager startUpdatingLocation];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    CLLocation *location = (CLLocation *)locations.firstObject;

    NSDate *now = [NSDate new];
    NSTimeInterval secondsSinceLastLocationUpdate = [self.lastLocationUpdate timeIntervalSinceDate:now];
    if(secondsSinceLastLocationUpdate *-1 >= EventsMapDefaultLocationUpdateInterval
       || [location distanceFromLocation:self.lastLocation] > self.radius.doubleValue) {
        
//        [self filterEventsForLocation:location];
        self.lastLocationUpdate = [NSDate new];
        self.lastLocation = location;
        [self mapEvents:self.filteredEvents];
    }
    
//    [self mapEvents:self.filteredEvents];
}

//- (void)filterEventsForLocation:(CLLocation *)location {
//    
//    if(!self.filteredEvents) {
//        self.filteredEvents = [EventsList new];
//    }
//    [self.filteredEvents removeAllItems];
//    
//    for(NSObject<EventProtocol> *event in self.events.allItems) {
//        if(event.placeLongitude && event.placeLattitude) {
//            CLLocation *eventLocation = [[CLLocation alloc] initWithLatitude:event.placeLattitude.doubleValue
//                                                                   longitude:event.placeLongitude.doubleValue];
//            if([eventLocation distanceFromLocation:location] <= self.radius.doubleValue) {
//                [self.filteredEvents add:event];
//            }
//        }
//    }
//    
//    self.lastLocationUpdate = [NSDate new];
//    self.lastLocation = location;
//}


#pragma mark - Notification Handling
- (void)addNotificationCenter {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUpdatedEventsList:) name:EventsListUpdatedNotification object:nil];
}

- (void)removeNotificationCenter {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EventsListUpdatedNotification object:nil];
}

- (void)handleUpdatedEventsList:(NSNotification *)notification {
    self.filteredEvents = [EventsManager sharedInstance].filteredEvents;
    
//    CLLocation *currentLocation = [self.locationManager location];
//    [self filterEventsForLocation:currentLocation];
    [self mapEvents:self.filteredEvents];
}

@end
