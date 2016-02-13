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
#import "Event.h"

@interface EventsMapViewController ()
@property (nonatomic, strong) NSArray *addresses;
@property (nonatomic, strong) NSMutableArray *convertedItems;
@property (nonatomic, strong) MapViewControllerDelegate* mapDelegate;
@property (nonatomic, strong) CLLocationManager *locationManager;
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
    
    self.mapDelegate = [[MapViewControllerDelegate alloc] initWithSegue:@"ShowEventDetailSegue"
                                                     fromViewController:self];
    self.mapView.delegate = self.mapDelegate;
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [self.locationManager requestAlwaysAuthorization];
    
    EventsList* events = [self initializeEvents];
    [self mapEvents:events];
}


-(EventsList*) initializeEvents
{
    self.addresses = [NSArray arrayWithObjects:
                      @"Argyle Bar and Grill, Argyle Street, Halifax, NS",
                      @"Pacifico Bar And Grill, 1505 Barrington Street, Halifax, NS",
                      nil];
    EventsList* events = [[EventsList alloc] init];
    for(NSString* addy in self.addresses) {
        Event* e = [[Event alloc] init];
        e.address = addy;
        [events add: e];
    }
    return events;
}


-(void)mapEvents:(EventsList *)events
{
    __weak typeof(self) weakSelf = self;
    void (^completionAction)(NSDictionary *, NSError *) = ^(NSDictionary *json, NSError *error) {
        NSArray<EventAnnotation *> *annotations = [EventAnnotationAdapter makeAnnotationsFromGoogleGeoCodeLocationJson:json];
        NSArray<MKPlacemark*> *placemarks = [weakSelf pinAnnotations:annotations];

        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.mapView addAnnotations:placemarks];
        });        
    };
    
    for(Event *event in events.allItems) {
        GoogleGeoCoder *geoCoder = [[GoogleGeoCoder alloc] initWithAddress:event.address];
        geoCoder.completionAction = completionAction;
        NSOperationQueue *coderQ = [NSOperationQueue new];
        [coderQ addOperation:geoCoder];
    }
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
    
}
@end
