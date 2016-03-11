//
//  EventAnnotationView.m
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-29.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import "EventAnnotationCalloutView.h"

@interface EventAnnotationCalloutView()
@property (nonatomic, strong) NSDate *date;
@end

@implementation EventAnnotationCalloutView

- (void)setDate:(NSDate *)date {
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"dd"];
    self.dayLabel.text = [formatter stringFromDate:date];
    [formatter setDateFormat:@"MMM"];
    self.monthLabel.text = [[formatter stringFromDate:date] uppercaseString];
}

@end
