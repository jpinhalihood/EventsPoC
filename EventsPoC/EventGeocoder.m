//
//  EventGeocoder.m
//  EventsPoC
//
//  Created by Jeff Price on 2013-06-27.
//  Copyright (c) 2013 Jeff Price. All rights reserved.
//

#import "EventGeocoder.h"

@implementation EventGeocoder

-(void) getPinnableAddresses: (NSArray*) addresses
                  onComplete: (void (^)(NSArray*)) completionHandler
{
    [self geocodeAddresses: addresses onComplete:^(NSArray *itemsToPin) {
        [self.convertedItems addObjectsFromArray: itemsToPin];
        completionHandler(self.convertedItems);
    }];
}

-(void) geocodeAddresses: (NSArray*) addresses
              onComplete: (void (^)(NSArray*)) completionHandler
{
    
    CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
    for(NSString *address in addresses) {
        [geoCoder geocodeAddressString: address
                     completionHandler:^(NSArray *placemarks, NSError *error) {
                         if(error) {
                             NSLog(@"Error: %@", [error description]);
                         }
                         
                         NSArray *items = [self convertToMKMapItems: placemarks];
                         completionHandler(items);
                     }];
    }
}

-(NSArray*) convertToMKMapItems: (NSArray*) placemarks
{
    NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:0];
    for(CLPlacemark *placemark in placemarks) {
        MKPlacemark *mkp = [self convertCLPlacemark: placemark];
        MKMapItem *item = [[MKMapItem alloc] initWithPlacemark: mkp];
        [items addObject: item];
    }
    
    return [NSArray arrayWithArray: items];
}

-(MKPlacemark*) convertCLPlacemark: (CLPlacemark*) placemark
{
    MKPlacemark *mkplacemark = [[MKPlacemark alloc] initWithPlacemark: placemark];
    return mkplacemark;
}



-(void) geocodeAddress: (NSString*) address completionHandler: (void (^)(NSArray*)) completionHandler
{
    __block NSMutableArray *blocksafeArray = [[NSMutableArray alloc] initWithCapacity:0];
    __block NSArray *blockSafeItems;
    CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
    [geoCoder geocodeAddressString: address
                 completionHandler:^(NSArray *placemarks, NSError *error) {
                     for(CLPlacemark *placemark in placemarks) {
                         MKPlacemark *mkplacemark = [[MKPlacemark alloc] initWithPlacemark: placemark];
                         MKMapItem *item = [[MKMapItem alloc] initWithPlacemark: mkplacemark];
                         [blocksafeArray addObject: item];
                     }
                     
                     blockSafeItems = [NSArray arrayWithArray: blocksafeArray];
                     completionHandler(blockSafeItems);
                 }];    
}


@end
