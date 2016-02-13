//
//  MapViewControllerDelegate.m
//  EventsPoC
//
//  Created by Jeff Price on 2013-10-23.
//  Copyright (c) 2013 Jeff Price. All rights reserved.
//

#import "MapViewControllerDelegate.h"

@interface MapViewControllerDelegate ()
@property (nonatomic, weak) UIViewController* sourceController;
@property (nonatomic, weak) UIViewController* destinationController;
@property (nonatomic, weak) NSString* segue;
@end


@implementation MapViewControllerDelegate

-(id)initWithSegue:(NSString *)segueName fromViewController:(UIViewController *)source
{
    if(self = [super init]) {
        self.segue = segueName;
        self.sourceController = source;
    }
    return self;
}



-(void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    if(self.sourceController) {
        [self.sourceController performSegueWithIdentifier:self.segue sender:self.sourceController];
    }
}


@end
