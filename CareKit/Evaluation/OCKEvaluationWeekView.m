//
//  OCKEvaluationWeekView.m
//  CareKit
//
//  Created by Umer Khan on 2/16/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKEvaluationWeekView.h"
#import "OCKWeekView.h"
#import "OCKRingButton.h"
#import "OCKRingView.h"


const static CGFloat RingButtonSize = 20.0;

@implementation OCKEvaluationWeekView {
    OCKWeekView *_weekView;
    NSMutableArray<OCKRingButton *> *_ringButtons;
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
        
        NSInteger weekday = [[NSCalendar currentCalendar] component:NSCalendarUnitWeekday fromDate:[NSDate date]] - 1;
        [_weekView highlightDay:weekday];
        _selectedIndex = weekday;
    }
    
    if (!_ringButtons) {
        _ringButtons = [NSMutableArray new];
        for (int i = 0; i < 7; i++) {
            OCKRingButton *ringButton = [[OCKRingButton alloc] initWithFrame:CGRectMake(0, 0, RingButtonSize, RingButtonSize)];
            ringButton.translatesAutoresizingMaskIntoConstraints = NO;
            
            OCKRingView *ringView = [[OCKRingView alloc] initWithFrame:CGRectMake(0, 0, RingButtonSize + 10, RingButtonSize + 10)];
            ringView.userInteractionEnabled = NO;
            ringView.disableAnimation = YES;
            ringView.hideLabel = YES;
            ringButton.ringView = ringView;
            
            [ringButton addTarget:self
                          action:@selector(updateDayOfWeek:)
                forControlEvents:UIControlEventTouchDown];
            
            [self addSubview:ringButton];
            [_ringButtons addObject:ringButton];
        }
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
                                                                     constant:-5.0],
                                       [NSLayoutConstraint constraintWithItem:_weekView
                                                                    attribute:NSLayoutAttributeCenterX
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeCenterX
                                                                   multiplier:1.0
                                                                     constant:0.0]
                                       ]];
    
    for (int i = 0; i < _ringButtons.count; i++) {
        UILabel *dayLabel = (UILabel *)_weekView.weekLabels[i];
        [constraints addObjectsFromArray:@[
                                           [NSLayoutConstraint constraintWithItem:dayLabel
                                                                        attribute:NSLayoutAttributeBottom
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:_ringButtons[i]
                                                                        attribute:NSLayoutAttributeTop
                                                                       multiplier:1.0
                                                                         constant:-3.0],
                                           [NSLayoutConstraint constraintWithItem:dayLabel
                                                                        attribute:NSLayoutAttributeCenterX
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:_ringButtons[i]
                                                                        attribute:NSLayoutAttributeCenterX
                                                                       multiplier:1.0
                                                                         constant:0.0]
                                           ]];
    }
    
    
    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)setProgressValues:(NSArray *)progressValues {
    _progressValues = progressValues;
    
    for (int i = 0; i < _progressValues.count; i++) {
        _ringButtons[i].ringView.value = [_progressValues[i] floatValue];
    }
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    _selectedIndex = selectedIndex;
    [_weekView highlightDay:selectedIndex];
}

- (void)updateDayOfWeek:(id)sender {
    OCKRingButton *button = (OCKRingButton *)sender;
    NSInteger index = [_ringButtons indexOfObject:button];
    _selectedIndex = index;
    
    if (_delegate &&
        [_delegate respondsToSelector:@selector(evaluationWeekViewSelectionDidChange:)]) {
        [_delegate evaluationWeekViewSelectionDidChange:self];
    }
}

@end
