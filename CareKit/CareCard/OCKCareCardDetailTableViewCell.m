//
//  OCKCareCardDetailTableViewCell.m
//  CareKit
//
//  Created by Umer Khan on 2/19/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKCareCardDetailTableViewCell.h"
#import "OCKCarePlanEvent.h"


static const CGFloat LeadingMargin = 30.0;
static const CGFloat TrailingMargin = 15.0;

@implementation OCKCareCardDetailTableViewCell {
    UIButton *_frequencyButton;
    UIDatePicker *_timePicker;
    UILabel *_noValueLabel;
    
    UIView *_leadingEdge;
    
    OCKCarePlanActivity *_treatment;
}

- (void)setTreatmentEvent:(OCKCarePlanEvent *)treatmentEvent {
    _treatmentEvent = treatmentEvent;
    _treatment = treatmentEvent.activity;
    [self prepareView];
}

- (void)prepareView {
    self.tintColor = _treatment.tintColor;

    if (!_frequencyButton) {
        _frequencyButton = [UIButton new];
        _frequencyButton.userInteractionEnabled = NO;
        [self.contentView addSubview:_frequencyButton];
    }
    
    if (_treatmentEvent.state == OCKCarePlanEventStateCompleted) {
        _frequencyButton.backgroundColor = [UIColor grayColor];
    } else {
        _frequencyButton.backgroundColor = _treatment.tintColor;
    }
    
    if (!_noValueLabel) {
        _noValueLabel = [UILabel new];
        _noValueLabel.text = @"--";
        [self.contentView addSubview:_noValueLabel];
    }
    _noValueLabel.textColor = _treatment.tintColor;
    _noValueLabel.hidden = (_treatmentEvent.state == OCKCarePlanEventStateCompleted);
    
    if (_treatmentEvent.state == OCKCarePlanEventStateCompleted) {
        if (!_timePicker) {
            _timePicker = [UIDatePicker new];
            _timePicker.datePickerMode = UIDatePickerModeTime;
            [self.contentView addSubview:_timePicker];
        }
        [_timePicker setDate:_treatmentEvent.result.completionDate animated:YES];
    } else {
        _timePicker = nil;
    }
    
    if (!_leadingEdge) {
        _leadingEdge = [UIView new];
        [self addSubview:_leadingEdge];
    }
    _leadingEdge.backgroundColor = _treatment.tintColor;
    
    [self setUpConstraints];
}

- (void)setUpConstraints {
    NSMutableArray *constraints = [NSMutableArray new];
    
    _frequencyButton.translatesAutoresizingMaskIntoConstraints = NO;
    _noValueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _leadingEdge.translatesAutoresizingMaskIntoConstraints = NO;
    
    [constraints addObjectsFromArray:@[
                                       [NSLayoutConstraint constraintWithItem:_frequencyButton
                                                                    attribute:NSLayoutAttributeCenterY
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.contentView
                                                                    attribute:NSLayoutAttributeCenterY
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_frequencyButton
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.contentView
                                                                    attribute:NSLayoutAttributeLeading
                                                                   multiplier:1.0
                                                                     constant:LeadingMargin],
                                       [NSLayoutConstraint constraintWithItem:self.contentView
                                                                    attribute:NSLayoutAttributeTrailing
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_noValueLabel
                                                                    attribute:NSLayoutAttributeTrailing
                                                                   multiplier:1.0
                                                                     constant:2*TrailingMargin],
                                       [NSLayoutConstraint constraintWithItem:_noValueLabel
                                                                    attribute:NSLayoutAttributeCenterY
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.contentView
                                                                    attribute:NSLayoutAttributeCenterY
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_leadingEdge
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.contentView
                                                                    attribute:NSLayoutAttributeLeading
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_leadingEdge
                                                                    attribute:NSLayoutAttributeWidth
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:nil
                                                                    attribute:NSLayoutAttributeNotAnAttribute
                                                                   multiplier:1.0
                                                                     constant:3.0],
                                       [NSLayoutConstraint constraintWithItem:_leadingEdge
                                                                    attribute:NSLayoutAttributeHeight
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.contentView
                                                                    attribute:NSLayoutAttributeHeight
                                                                   multiplier:1.0
                                                                     constant:0.0]
                                       ]];
    
    if (_timePicker) {
        _timePicker.translatesAutoresizingMaskIntoConstraints = NO;
        [constraints addObjectsFromArray:@[
                                           [NSLayoutConstraint constraintWithItem:_timePicker
                                                                        attribute:NSLayoutAttributeCenterY
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.contentView
                                                                        attribute:NSLayoutAttributeCenterY
                                                                       multiplier:1.0
                                                                         constant:0.0],
                                           [NSLayoutConstraint constraintWithItem:_timePicker
                                                                        attribute:NSLayoutAttributeTrailing
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.contentView
                                                                        attribute:NSLayoutAttributeTrailing
                                                                       multiplier:1.0
                                                                         constant:TrailingMargin]
                                           ]];
    }
    
    [NSLayoutConstraint activateConstraints:constraints];
}

@end
