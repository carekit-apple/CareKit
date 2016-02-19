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
        for (int i = 1; i < 8; i++) {
            UILabel *dayLabel = [UILabel new];
            dayLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightThin];
            dayLabel.translatesAutoresizingMaskIntoConstraints = NO;
            dayLabel.layer.cornerRadius = 3;
            dayLabel.clipsToBounds = YES;
            
            NSString *day = nil;
            switch (i) {
                case 1:
                    day = @"S";
                    break;
                case 2:
                    day = @"M";
                    break;
                case 3:
                    day = @"T";
                    break;
                case 4:
                    day = @"W";
                    break;
                case 5:
                    day = @"T";
                    break;
                case 6:
                    day = @"F";
                    break;
                case 7:
                    day = @"S";
                    break;
            }
            dayLabel.text = day;
            dayLabel.textAlignment = NSTextAlignmentCenter;
            
            [self addSubview:dayLabel];
            [_weekLabels addObject:dayLabel];
        }
    }
    
    NSInteger weekday = [[NSCalendar currentCalendar] component:NSCalendarUnitWeekday fromDate:[NSDate date]];
    [self highlightDay:weekday];
    
    [self setUpConstraints];
}

- (void)setUpConstraints {
    NSMutableArray *constraints = [NSMutableArray new];
    
    const CGFloat HorizontalMargin = self.bounds.size.width/9;
    
    for (int i=0; i < _weekLabels.count; i++) {
        if (i == 0) {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_weekLabels[i]
                                                                attribute:NSLayoutAttributeWidth
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_weekLabels[i+1]
                                                                attribute:NSLayoutAttributeWidth
                                                               multiplier:1.0
                                                                 constant:0.0]];
        } else {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_weekLabels[i]
                                                                attribute:NSLayoutAttributeWidth
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_weekLabels[i-1]
                                                                attribute:NSLayoutAttributeWidth
                                                               multiplier:1.0
                                                                 constant:0.0]];
        }
        
        [constraints addObjectsFromArray:@[[NSLayoutConstraint constraintWithItem:_weekLabels[i]
                                                                        attribute:NSLayoutAttributeTop
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self
                                                                        attribute:NSLayoutAttributeTop
                                                                       multiplier:1.0
                                                                         constant:TopMargin]
                                           ]];
    }

    {
        [constraints addObjectsFromArray:@[
                                           // Monday
                                           [NSLayoutConstraint constraintWithItem:_weekLabels[1]
                                                                        attribute:NSLayoutAttributeTrailing
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:_weekLabels[2]
                                                                        attribute:NSLayoutAttributeLeading
                                                                       multiplier:1.0
                                                                         constant:-HorizontalMargin],
                                           // Tuesday
                                           [NSLayoutConstraint constraintWithItem:_weekLabels[2]
                                                                        attribute:NSLayoutAttributeTrailing
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:_weekLabels[3]
                                                                        attribute:NSLayoutAttributeLeading
                                                                       multiplier:1.0
                                                                         constant:-HorizontalMargin],
                                           // Wednesday
                                           [NSLayoutConstraint constraintWithItem:_weekLabels[3]
                                                                        attribute:NSLayoutAttributeTrailing
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:_weekLabels[4]
                                                                        attribute:NSLayoutAttributeLeading
                                                                       multiplier:1.0
                                                                         constant:-HorizontalMargin],
                                           // Thursday (Centered on screen, anchor point).
                                           [NSLayoutConstraint constraintWithItem:_weekLabels[4]
                                                                        attribute:NSLayoutAttributeCenterX
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self
                                                                        attribute:NSLayoutAttributeCenterX
                                                                       multiplier:1.0
                                                                         constant:0.0],
                                           // Friday
                                           [NSLayoutConstraint constraintWithItem:_weekLabels[4]
                                                                        attribute:NSLayoutAttributeTrailing
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:_weekLabels[5]
                                                                        attribute:NSLayoutAttributeLeading
                                                                       multiplier:1.0
                                                                         constant:-HorizontalMargin],
                                           // Saturday
                                           [NSLayoutConstraint constraintWithItem:_weekLabels[5]
                                                                        attribute:NSLayoutAttributeTrailing
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:_weekLabels[6]
                                                                        attribute:NSLayoutAttributeLeading
                                                                       multiplier:1.0
                                                                         constant:-HorizontalMargin],
                                           // Sunday
                                           [NSLayoutConstraint constraintWithItem:_weekLabels[6]
                                                                        attribute:NSLayoutAttributeTrailing
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:_weekLabels[0]
                                                                        attribute:NSLayoutAttributeLeading
                                                                       multiplier:1.0
                                                                         constant:-HorizontalMargin]
                                           ]];
    }
    
    [NSLayoutConstraint activateConstraints:constraints];
}

- (NSArray<UILabel *> *)weekLabels {
    return _weekLabels;
}

- (void)highlightDay:(NSInteger)day {
    for (id label in _weekLabels) {
        ((UILabel *)label).backgroundColor = [UIColor clearColor];
        ((UILabel *)label).textColor = [UIColor blackColor];
    }
    ((UILabel *)_weekLabels[day]).backgroundColor = OCKPinkColor();
    ((UILabel *)_weekLabels[day]).textColor = [UIColor whiteColor];
}

@end
