//
//  EventsListTableViewCell.m
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-04.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import "EventsListTableViewCell.h"

@interface EventsListTableViewCell()
@end

@implementation EventsListTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.titleLabel.text = nil;
    self.descriptionLabel.text = nil;
    self.startTimeLabel.text = nil;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureWithTitle:(NSString *)title description:(NSString *)description startDate:(NSDate *)startDate host:(NSString *)host
 {
    self.titleLabel.text = title;
    self.descriptionLabel.text = description;
    if(host) {
        self.hostLabel.text = [@"Host: " stringByAppendingString:host];
    }
     
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"MMM dd, yyyy '@' hh:mm a'"];

    self.startTimeLabel.text = [formatter stringFromDate:startDate];
}

@end
