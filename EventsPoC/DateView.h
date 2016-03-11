//
//  DateView.h
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-29.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DateView : UIView
@property (nonatomic, weak) IBOutlet UILabel *dayLabel;
@property (nonatomic, weak) IBOutlet UILabel *monthLabel;

- (void)setDate:(NSDate *)date;
@end
