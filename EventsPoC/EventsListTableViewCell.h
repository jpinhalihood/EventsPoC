//
//  EventsListTableViewCell.h
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-04.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EventsListTableViewCell : UITableViewCell
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *descriptionLabel;
@property (nonatomic, weak) IBOutlet UILabel *startTimeLabel;

- (void)configureWithTitle:(NSString *)title description:(NSString *)description startDate:(NSDate *)startDate;
@end
