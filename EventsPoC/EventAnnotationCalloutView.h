//
//  EventAnnotationView.h
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-29.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>


#import "DateView.h"


@interface EventAnnotationCalloutView : UIView
@property (nonatomic, weak) IBOutlet UILabel *hostLabel;
@property (nonatomic, weak) IBOutlet UILabel *startTimeLabel;
@property (nonatomic, weak) IBOutlet UILabel *addressLabel;
@property (nonatomic, weak) IBOutlet UIButton *moreButton;

@property (nonatomic, weak) IBOutlet UILabel *dayLabel;
@property (nonatomic, weak) IBOutlet UILabel *monthLabel;


- (void)setDate:(NSDate *)date;
@end
