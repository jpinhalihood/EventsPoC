//
//  RadiusSelectionTableViewCell.m
//  EventsPoC
//
//  Created by Jeff Price on 2016-03-10.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import "RadiusSelectionTableViewCell.h"

@interface RadiusSelectionTableViewCell()
@end

@implementation RadiusSelectionTableViewCell

- (void)awakeFromNib {
    self.minRadiusLabel.text = [NSString stringWithFormat:@"%ldkm", (long)self.radiusSlider.minimumValue];
    self.maxRadiusLabel.text = [NSString stringWithFormat:@"%ldkm", (long)self.radiusSlider.maximumValue];
    self.radiusSlider.value = [self.initialRadius floatValue];
    self.radiusLabel.text = [NSString stringWithFormat:@"%.2fkm", [self.initialRadius floatValue]];
    [self.radiusSlider addTarget:self action:@selector(didChangeValue:) forControlEvents:UIControlEventValueChanged];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)didChangeValue:(id)sender {
    self.radiusLabel.text = [NSString stringWithFormat:@"%.2fkm", self.radiusSlider.value];
    if(self.radiusChangedAction) {
        self.radiusChangedAction(self.radiusSlider.value * 1000);
    }
}

- (void)setInitialRadius:(NSNumber *)initialRadius {
    CGFloat radius = [initialRadius floatValue] / 1000;
    _initialRadius = [NSNumber numberWithFloat:radius];
    self.radiusSlider.value = radius;
    self.radiusLabel.text = [NSString stringWithFormat:@"%.2fkm", radius];
}

@end
