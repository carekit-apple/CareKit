//
//  OCKTreatmentTableViewCell.m
//  CareKit
//
//  Created by Umer Khan on 1/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKCareCardTableViewCell.h"
#import "OCKColors.h"
#import "OCKCarePlanActivity.h"
#import "OCKCarePlanActivity_Internal.h"
#import "OCKCarePlanEvent.h"
#import "OCKCareCardButton.h"


static const CGFloat HorizontalMargin = 9.0;
static const CGFloat LeadingMargin = 20.0;

@implementation OCKCareCardTableViewCell {
    UILabel *_titleLabel;
    UILabel *_textLabel;
    
    UIView *_leadingEdge;
    
    NSArray <OCKCareCardButton *> *_frequencyButtons;
    OCKCarePlanActivity *_treatment;
    NSMutableArray *_constraints;
}

- (void)setTreatmentEvents:(NSArray<OCKCarePlanEvent *> *)treatmentEvents {
    _treatmentEvents = treatmentEvents;
    _treatment = treatmentEvents.firstObject.activity;
    [self prepareView];
}

- (void)prepareView {
    self.tintColor = _treatment.tintColor;
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    self.separatorInset = UIEdgeInsetsMake(0, 20, 0, 0);
    
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
        [self.contentView addSubview:_titleLabel];
    }
    _titleLabel.text = _treatment.title;
    
    if (!_textLabel) {
        _textLabel = [UILabel new];
        _textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _textLabel.textColor = [UIColor lightGrayColor];
        _textLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightThin];
        [self.contentView addSubview:_textLabel];
    }
    _textLabel.text = _treatment.text;
    
    for (OCKCareCardButton *button in _frequencyButtons) {
        [button removeFromSuperview];
    }
    
    _frequencyButtons = [NSArray new];
    NSMutableArray *buttons = [NSMutableArray new];
    for (OCKCarePlanEvent *event in _treatmentEvents) {
        OCKCareCardButton *frequencyButton = [[OCKCareCardButton alloc] initWithFrame:CGRectMake(0, 0, 50, 75)];
        frequencyButton.tintColor = _treatment.tintColor;
        frequencyButton.selected = (event.state == OCKCarePlanEventStateCompleted);
        frequencyButton.translatesAutoresizingMaskIntoConstraints = NO;
        
        [frequencyButton addTarget:self
                            action:@selector(toggleFrequencyButton:)
                  forControlEvents:UIControlEventTouchUpInside];
        [buttons addObject:frequencyButton];
        
        [self.contentView addSubview:frequencyButton];
    }
    _frequencyButtons = [buttons copy];
    
    if (!_leadingEdge) {
        _leadingEdge = [UIView new];
        [self addSubview:_leadingEdge];
    }
    _leadingEdge.backgroundColor = _treatment.tintColor;
    
    [self setUpConstraints];
}

- (void)setUpConstraints {
    [NSLayoutConstraint deactivateConstraints:_constraints];
    _constraints = [NSMutableArray new];
    
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _leadingEdge.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_constraints addObjectsFromArray:@[
                                        [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                     attribute:NSLayoutAttributeCenterY
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.contentView
                                                                     attribute:NSLayoutAttributeCenterY
                                                                    multiplier:1.0
                                                                      constant:-20.0],
                                        [NSLayoutConstraint constraintWithItem:_textLabel
                                                                     attribute:NSLayoutAttributeBaseline
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_titleLabel
                                                                     attribute:NSLayoutAttributeBaseline
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                     attribute:NSLayoutAttributeBaseline
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_textLabel
                                                                     attribute:NSLayoutAttributeBaseline
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.contentView
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:LeadingMargin],
                                        [NSLayoutConstraint constraintWithItem:_textLabel
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_titleLabel
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:5.0],
                                        [NSLayoutConstraint constraintWithItem:_leadingEdge
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_leadingEdge
                                                                     attribute:NSLayoutAttributeCenterY
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeCenterY
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
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeHeight
                                                                    multiplier:1.0
                                                                      constant:0.0]
                                        ]];
    
    for (int i = 0; i < _frequencyButtons.count; i++) {
        if (i == 0) {
            [_constraints addObject:[NSLayoutConstraint constraintWithItem:_frequencyButtons[i]
                                                                 attribute:NSLayoutAttributeLeading
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeLeading
                                                                multiplier:1.0
                                                                  constant:LeadingMargin]];
        } else {
            [_constraints addObject:[NSLayoutConstraint constraintWithItem:_frequencyButtons[i]
                                                                 attribute:NSLayoutAttributeLeading
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:_frequencyButtons[i-1]
                                                                 attribute:NSLayoutAttributeTrailing
                                                                multiplier:1.0
                                                                  constant:HorizontalMargin]];
        }
        [_constraints addObjectsFromArray:@[
                                            [NSLayoutConstraint constraintWithItem:_frequencyButtons[i]
                                                             attribute:NSLayoutAttributeTop
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:_titleLabel
                                                             attribute:NSLayoutAttributeBottom
                                                            multiplier:1.0
                                                              constant:5.0],
                                            [NSLayoutConstraint constraintWithItem:_frequencyButtons[i]
                                                                         attribute:NSLayoutAttributeHeight
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:nil
                                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                                        multiplier:1.0
                                                                          constant:45.0],
//                                            [NSLayoutConstraint constraintWithItem:_frequencyButtons[i]
//                                                                         attribute:NSLayoutAttributeWidth
//                                                                         relatedBy:NSLayoutRelationEqual
//                                                                            toItem:nil
//                                                                         attribute:NSLayoutAttributeNotAnAttribute
//                                                                        multiplier:1.0
//                                                                          constant:_frequencyButtons[i].frame.size.width]
                                            ]];
    }
    
    [NSLayoutConstraint activateConstraints:_constraints];
}

- (void)toggleFrequencyButton:(id)sender {
    OCKCareCardButton *button = (OCKCareCardButton *)sender;
    button.selected = !button.selected;
    
    // Infer the treatment event from the button index.
    NSInteger index = [_frequencyButtons indexOfObject:button];
    OCKCarePlanEvent *selectedEvent = _treatmentEvents[index];
    
    if (_delegate &&
        [_delegate respondsToSelector:@selector(careCardCellDidUpdateFrequency:ofTreatmentEvent:)]) {
        [_delegate careCardCellDidUpdateFrequency:self ofTreatmentEvent:selectedEvent];
    }
    
}

@end
