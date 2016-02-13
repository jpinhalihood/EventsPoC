//
//  EventAnnotation.m
//  EventsPoC
//
//  Created by Jeff Price on 2013-06-26.
//  Copyright (c) 2013 Jeff Price. All rights reserved.
//

#import "EventAnnotation.h"
#import <Contacts/ContactsDefines.h>
#import <AddressBook/AddressBook.h>

@interface EventAnnotation()
@property (nonatomic, assign) CLLocationCoordinate2D coordinates;
@property (nonatomic, copy) NSString *eventTitle;
@property (nonatomic, copy) NSString *eventSubTitle;
@end

@implementation EventAnnotation

-(id)initWithCoordinate:(CLLocationCoordinate2D)eventCoord
                  title:(NSString *)eventTitle
               subtitle:(NSString *)eventSubtitle
{
    if(self = [super init]) {
        _coordinates = eventCoord;
        _eventTitle = eventTitle;
        _eventSubTitle = eventSubtitle;
    }
    return self;
}


-(MKMapItem *)mapItem
{
    NSDictionary *addressDict = @{ (NSString *)kABPersonAddressStreetKey : _eventTitle};
    
    MKPlacemark *placemark = [[MKPlacemark alloc]
                              initWithCoordinate:self.coordinate
                              addressDictionary:addressDict];
    
    MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
    mapItem.name = self.title;
    
    return mapItem;
}

#pragma mark - MKAnnotation Methods
-(NSString *)title
{
    return _eventTitle;
}

-(NSString *)subtitle
{
    return _eventSubTitle;
}

-(CLLocationCoordinate2D)coordinate
{
    return self.coordinates;
}
@end
