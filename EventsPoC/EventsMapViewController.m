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
@property (nonatomic, strong) NSArray<FBEvent*> *fbEvents;
@end

@implementation EventsMapViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor darkGrayColor]}];
    
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
//    CLLocation *location = (CLLocation *)locations.firstObject;
//    NSLog(@"Updated locations: LAT: %f | LNG: %f", location.coordinate.latitude, location.coordinate.longitude);
}


#pragma mark - SegmentedViewControllerProtocol Methods
- (NSString *)displayName {
    return NSLocalizedString(@"Map View", @"A label indicating this view displays events in a map view");
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
    [self mapEvents:self.events];
}

@end
