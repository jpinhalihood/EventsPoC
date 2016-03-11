//
//  RadiusSelectionTableViewCell.h
//  EventsPoC
//
//  Created by Jeff Price on 2016-03-10.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RadiusSelectionTableViewCell : UITableViewCell
@property (nonatomic, strong) NSNumber *initialRadius;
@property (nonatomic, weak) IBOutlet UISlider *radiusSlider;
@property (nonatomic, weak) IBOutlet UILabel *radiusLabel;
@property (nonatomic, weak) IBOutlet UILabel *minRadiusLabel;
@property (nonatomic, weak) IBOutlet UILabel *maxRadiusLabel;

@property (nonatomic, copy) void (^radiusChangedAction)(CGFloat);

@end
