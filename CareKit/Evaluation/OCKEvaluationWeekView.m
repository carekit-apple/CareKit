//
//  OCKEvaluationWeekView.m
//  CareKit
//
//  Created by Umer Khan on 2/16/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKEvaluationWeekView.h"
#import "OCKWeekView.h"


const static CGFloat DayButtonSize = 20.0;

@implementation OCKEvaluationWeekView {
    OCKWeekView *_weekView;
    NSMutableArray<UIButton *> *_dayButtons;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self prepareView];
    }
    return self;
}

- (void)prepareView {
    if (!_weekView) {
        _weekView = [[OCKWeekView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 25.0)];
        [self addSubview:_weekView];
    }
    
    _dayButtons = [NSMutableArray new];
    
    for (int i = 0; i < 7; i++) {
        
        UIButton *dayButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, DayButtonSize, DayButtonSize)];
        dayButton.translatesAutoresizingMaskIntoConstraints = NO;
        
        [dayButton addTarget:self
                      action:@selector(updateDayOfWeek:)
            forControlEvents:UIControlEventTouchDown];
        
        [self addSubview:dayButton];
        [_dayButtons addObject:dayButton];
    }
    
    [self setUpConstraints];
}

- (void)setUpConstraints {
    NSMutableArray *constraints = [NSMutableArray new];
    
    _weekView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [constraints addObjectsFromArray:@[
                                       [NSLayoutConstraint constraintWithItem:_weekView
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeTop
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_weekView
                                                                    attribute:NSLayoutAttributeCenterX
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeCenterX
                                                                   multiplier:1.0
                                                                     constant:0.0]
                                       ]];
    
    for (int i = 0; i < _dayButtons.count; i++) {
        UILabel *dayLabel = (UILabel *)_weekView.weekLabels[i];
        [constraints addObjectsFromArray:@[
                                           [NSLayoutConstraint constraintWithItem:dayLabel
                                                                        attribute:NSLayoutAttributeBottom
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:_dayButtons[i]
                                                                        attribute:NSLayoutAttributeBottom
                                                                       multiplier:1.0
                                                                         constant:0.0],
                                           [NSLayoutConstraint constraintWithItem:dayLabel
                                                                        attribute:NSLayoutAttributeCenterX
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:_dayButtons[i]
                                                                        attribute:NSLayoutAttributeCenterX
                                                                       multiplier:1.0
                                                                         constant:0.0]
                                           ]];
    }
    
    
    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)updateDayOfWeek:(id)sender {
    UIButton *button = (UIButton *)sender;
    NSInteger day = [_dayButtons indexOfObject:button];
    _selectedDay = day;
    [_weekView highlightDay:day];
    
    if (_delegate &&
        [_delegate respondsToSelector:@selector(evaluationWeekViewSelectionDidChange:)]) {
        [_delegate evaluationWeekViewSelectionDidChange:self];
    }
}


@end
