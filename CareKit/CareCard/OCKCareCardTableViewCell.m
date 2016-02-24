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


static const CGFloat HorizontalMargin = 15.0;
static const CGFloat LeadingMargin = 15.0;
static const CGFloat TopMargin = 10.0;

@implementation OCKCareCardTableViewCell {
    UILabel *_titleLabel;
    UILabel *_textLabel;

    UILabel *_leadingEdge;

    NSArray <OCKCareCardButton *> *_frequencyButtons;
    OCKCarePlanActivity *_treatment;
}


- (void)setTreatmentEvents:(NSArray<OCKCarePlanEvent *> *)treatmentEvents {
    _treatmentEvents = treatmentEvents;
    _treatment = treatmentEvents.firstObject.activity;
    [self prepareView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangePreferredContentSize)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
}

- (void)prepareView {
    self.tintColor = _treatment.tintColor;
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:_titleLabel];
    }
    _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    _titleLabel.text = _treatment.title;
    
    if (!_textLabel) {
        _textLabel = [UILabel new];
        _textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _textLabel.textColor = [UIColor lightGrayColor];
        [self.contentView addSubview:_textLabel];
    }
    _textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    _textLabel.text = _treatment.text;

    _frequencyButtons = [NSArray new];
    NSMutableArray *buttons = [NSMutableArray new];
    for (int i = 0; i < _treatmentEvents.count; i++) {
        OCKCareCardButton *frequencyButton = [OCKCareCardButton new];
        frequencyButton.tintColor = _treatment.tintColor;
        frequencyButton.translatesAutoresizingMaskIntoConstraints = NO;
    
        [frequencyButton addTarget:self
                            action:@selector(toggleFrequencyButton:)
                  forControlEvents:UIControlEventTouchUpInside];
        [buttons addObject:frequencyButton];
        
        [self.contentView addSubview:frequencyButton];
    }
    _frequencyButtons = [buttons copy];
    
    if (!_leadingEdge) {
        _leadingEdge = [UILabel new];
        [self addSubview:_leadingEdge];
    }
    
    [self setUpContraints];
}

- (void)setUpContraints {
    NSMutableArray *constraints = [NSMutableArray new];
    
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _leadingEdge.translatesAutoresizingMaskIntoConstraints = NO;
    
    [constraints addObjectsFromArray:@[
                                       [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.contentView
                                                                    attribute:NSLayoutAttributeTop
                                                                   multiplier:1.0
                                                                     constant:TopMargin],
                                       [NSLayoutConstraint constraintWithItem:_textLabel
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.contentView
                                                                    attribute:NSLayoutAttributeTop
                                                                   multiplier:1.0
                                                                     constant:TopMargin],
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
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_frequencyButtons[i]
                                                                attribute:NSLayoutAttributeLeading
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.contentView
                                                                attribute:NSLayoutAttributeLeading
                                                               multiplier:1.0
                                                                 constant:LeadingMargin]];
        } else {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_frequencyButtons[i]
                                                                attribute:NSLayoutAttributeLeading
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_frequencyButtons[i-1]
                                                                attribute:NSLayoutAttributeTrailing
                                                               multiplier:1.0
                                                                 constant:HorizontalMargin]];
        }
        [constraints addObject:[NSLayoutConstraint constraintWithItem:_frequencyButtons[i]
                                                            attribute:NSLayoutAttributeTop
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:_titleLabel
                                                            attribute:NSLayoutAttributeBottom
                                                           multiplier:1.0
                                                             constant:5.0]];
    }
    
    [NSLayoutConstraint activateConstraints:constraints];
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

- (void)didChangePreferredContentSize {
    [self prepareView];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
