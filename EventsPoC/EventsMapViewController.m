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
    self.mapDelegate = [[MapViewControllerDelegate alloc] initWithSegue:@"ShowEventDetailSegue"
                                                     fromViewController:self];
    self.mapView.delegate = self.mapDelegate;
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

- (void) mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    NSLog(@"Selected");
    [self performSegueWithIdentifier: @"ShowEventDetailSegue" sender: self];
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
    NSTimeInterval secondsSinceLastLocationUpdate = [now timeIntervalSinceDate:self.lastLocationUpdate];
    if(secondsSinceLastLocationUpdate >= EventsMapDefaultLocationUpdateInterval
       || [location distanceFromLocation:self.lastLocation] > self.radius.doubleValue) {
        for(NSObject<EventProtocol> *event in self.events.allItems) {
            if(event.placeLongitude && event.placeLattitude) {
                CLLocation *eventLocation = [[CLLocation alloc] initWithLatitude:event.placeLattitude.doubleValue
                                                                       longitude:event.placeLongitude.doubleValue];
                if([eventLocation distanceFromLocation:location] <= self.radius.doubleValue) {
                    if(!self.filteredEvents) {
                        self.filteredEvents = [EventsList new];
                    }
                    [self.filteredEvents removeAllItems];
                    [self.filteredEvents add:event];
                }
            }
        }
        
        self.lastLocationUpdate = [NSDate new];
        self.lastLocation = location;
        [self mapEvents:self.filteredEvents];
    }
    
}



#pragma mark - Notification Handling
- (void)addNotificationCenter {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUpdatedEventsList:) name:EventsListUpdatedNotification object:nil];
}

- (void)removeNotificationCenter {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EventsListUpdatedNotification object:nil];
}

- (void)handleUpdatedEventsList:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    self.events = [userInfo objectForKey:KeyEventsListUpdatedNotificationPayload];

}

@end
