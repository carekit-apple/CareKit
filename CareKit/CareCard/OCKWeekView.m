//
//  OCKTreatmentWeekView.m
//  CareKit
//
//  Created by Umer Khan on 1/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKWeekView.h"
#import "OCKColors.h"

const static CGFloat TopMargin = 12.0;

@implementation OCKWeekView {
    NSMutableArray<UILabel *> *_weekLabels;
    NSMutableArray *_constraints;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self prepareView];
    }
    return self;
}

- (void)prepareView {
    if (!_weekLabels) {
        _weekLabels = [NSMutableArray new];
        for (int i = 0; i < 7; i++) {
            UILabel *dayLabel = [UILabel new];
            dayLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightThin];
            dayLabel.translatesAutoresizingMaskIntoConstraints = NO;
            dayLabel.layer.cornerRadius = 3;
            dayLabel.clipsToBounds = YES;
            
            NSString *day = nil;
            switch (i) {
                case 0:
                    day = @"S";
                    break;
                case 1:
                    day = @"M";
                    break;
                case 2:
                    day = @"T";
                    break;
                case 3:
                    day = @"W";
                    break;
                case 4:
                    day = @"T";
                    break;
                case 5:
                    day = @"F";
                    break;
                case 6:
                    day = @"S";
                    break;
            }
            dayLabel.text = day;
            dayLabel.textAlignment = NSTextAlignmentCenter;
            
            [self addSubview:dayLabel];
            [_weekLabels addObject:dayLabel];
        }
    }
    
    [self setUpConstraints];
}

- (void)setUpConstraints {
    [NSLayoutConstraint deactivateConstraints:_constraints];
    
    _constraints = [NSMutableArray new];
    
    const CGFloat HorizontalMargin = self.bounds.size.width/9;
    
    for (int i = 0; i < _weekLabels.count; i++) {
        if (i == 0) {
            [_constraints addObject:[NSLayoutConstraint constraintWithItem:_weekLabels[i]
                                                                 attribute:NSLayoutAttributeWidth
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:_weekLabels[i+1]
                                                                 attribute:NSLayoutAttributeWidth
                                                                multiplier:1.0
                                                                  constant:0.0]];
        } else {
            [_constraints addObject:[NSLayoutConstraint constraintWithItem:_weekLabels[i]
                                                                 attribute:NSLayoutAttributeWidth
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:_weekLabels[i-1]
                                                                 attribute:NSLayoutAttributeWidth
                                                                multiplier:1.0
                                                                  constant:0.0]];
        }
        
        [_constraints addObjectsFromArray:@[[NSLayoutConstraint constraintWithItem:_weekLabels[i]
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self
                                                                         attribute:NSLayoutAttributeTop
                                                                        multiplier:1.0
                                                                          constant:TopMargin]
                                            ]];
    }
    
    {
        [_constraints addObjectsFromArray:@[
                                            // Monday
                                            [NSLayoutConstraint constraintWithItem:_weekLabels[0]
                                                                         attribute:NSLayoutAttributeTrailing
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:_weekLabels[1]
                                                                         attribute:NSLayoutAttributeLeading
                                                                        multiplier:1.0
                                                                          constant:-HorizontalMargin],
                                            // Tuesday
                                            [NSLayoutConstraint constraintWithItem:_weekLabels[1]
                                                                         attribute:NSLayoutAttributeTrailing
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:_weekLabels[2]
                                                                         attribute:NSLayoutAttributeLeading
                                                                        multiplier:1.0
                                                                          constant:-HorizontalMargin],
                                            // Wednesday
                                            [NSLayoutConstraint constraintWithItem:_weekLabels[2]
                                                                         attribute:NSLayoutAttributeTrailing
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:_weekLabels[3]
                                                                         attribute:NSLayoutAttributeLeading
                                                                        multiplier:1.0
                                                                          constant:-HorizontalMargin],
                                            // Thursday (Centered on screen, anchor point).
                                            [NSLayoutConstraint constraintWithItem:_weekLabels[3]
                                                                         attribute:NSLayoutAttributeCenterX
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self
                                                                         attribute:NSLayoutAttributeCenterX
                                                                        multiplier:1.0
                                                                          constant:0.0],
                                            // Friday
                                            [NSLayoutConstraint constraintWithItem:_weekLabels[3]
                                                                         attribute:NSLayoutAttributeTrailing
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:_weekLabels[4]
                                                                         attribute:NSLayoutAttributeLeading
                                                                        multiplier:1.0
                                                                          constant:-HorizontalMargin],
                                            // Saturday
                                            [NSLayoutConstraint constraintWithItem:_weekLabels[4]
                                                                         attribute:NSLayoutAttributeTrailing
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:_weekLabels[5]
                                                                         attribute:NSLayoutAttributeLeading
                                                                        multiplier:1.0
                                                                          constant:-HorizontalMargin],
                                            // Sunday
                                            [NSLayoutConstraint constraintWithItem:_weekLabels[5]
                                                                         attribute:NSLayoutAttributeTrailing
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:_weekLabels[6]
                                                                         attribute:NSLayoutAttributeLeading
                                                                        multiplier:1.0
                                                                          constant:-HorizontalMargin]
                                            ]];
    }
    
    [NSLayoutConstraint activateConstraints:_constraints];
}

- (void)highlightDay:(NSInteger)selectedIndex {
    for (id label in _weekLabels) {
        ((UILabel *)label).backgroundColor = [UIColor clearColor];
        ((UILabel *)label).textColor = [UIColor blackColor];
    }
    ((UILabel *)_weekLabels[selectedIndex]).backgroundColor = OCKRedColor();
    ((UILabel *)_weekLabels[selectedIndex]).textColor = [UIColor whiteColor];
}

@end
