//
//  OCKCareCardDetailViewController.m
//  CareKit
//
//  Created by Umer Khan on 2/18/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKCareCardDetailViewController.h"
#import "OCKCarePlanActivity.h"
#import "OCKCarePlanEvent.h"


static const CGFloat VerticalMargin = 50.0;
static const CGFloat LeadingMargin = 30.0;
static const CGFloat TopMargin = 100.0;

@implementation OCKCareCardDetailViewController {
    UILabel *_titleLabel;
    UILabel *_textLabel;
    UILabel *_detailedInstructions;
    
    UILabel *_leadingEdge;
    
    NSArray <UIButton *> *_frequencyButtons;
    NSArray <UIDatePicker *> *_frequencyDatePickers;

    OCKTreatment *_treatment;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)setTreatmentEvents:(NSArray<OCKTreatmentEvent *> *)treatmentEvents {
    _treatmentEvents = treatmentEvents;
    [self prepareView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangePreferredContentSize)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
}

- (void)prepareView {
    _treatment = _treatmentEvents.firstObject.treatment;
    
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.view addSubview:_titleLabel];
    }
    _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    _titleLabel.text = _treatment.title;
    
    if (!_textLabel) {
        _textLabel = [UILabel new];
        _textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.view addSubview:_textLabel];
    }
    _textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    _textLabel.text = _treatment.text;
    
    _frequencyButtons = [NSArray new];
    _frequencyDatePickers = [NSArray new];
    NSMutableArray *buttons = [NSMutableArray new];
    for (OCKTreatmentEvent *event in _treatmentEvents) {
        UIButton *frequencyButton = [UIButton new];
        if (event.state == OCKCareEventStateCompleted) {
            frequencyButton.backgroundColor = [UIColor grayColor];
        } else {
            frequencyButton.backgroundColor = _treatment.color;
        }
        frequencyButton.translatesAutoresizingMaskIntoConstraints = NO;
        frequencyButton.userInteractionEnabled = NO;
        
        [self.view addSubview:frequencyButton];
        [buttons addObject:frequencyButton];
    }
    _frequencyButtons = [buttons copy];
    
    if (!_leadingEdge) {
        _leadingEdge = [UILabel new];
        [self.view addSubview:_leadingEdge];
    }
    _leadingEdge.backgroundColor = _treatment.color;
    
    [self setUpConstraints];
}

- (void)setUpConstraints {
    NSMutableArray *constraints = [NSMutableArray new];
    
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _leadingEdge.translatesAutoresizingMaskIntoConstraints = NO;
    
    [constraints addObjectsFromArray:@[
                                       [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.view
                                                                    attribute:NSLayoutAttributeTop
                                                                   multiplier:1.0
                                                                     constant:TopMargin],
                                       [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.view
                                                                    attribute:NSLayoutAttributeLeading
                                                                   multiplier:1.0
                                                                     constant:LeadingMargin],
                                       [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_textLabel
                                                                    attribute:NSLayoutAttributeLeading
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_textLabel
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_titleLabel
                                                                    attribute:NSLayoutAttributeBottom
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_leadingEdge
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.view
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
                                                                       toItem:self.view
                                                                    attribute:NSLayoutAttributeHeight
                                                                   multiplier:1.0
                                                                     constant:0.0]
                                       ]];
    
    for (int i = 0; i < _frequencyButtons.count; i++) {
        if (i == 0) {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_frequencyButtons[i]
                                                                attribute:NSLayoutAttributeCenterY
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_titleLabel
                                                                attribute:NSLayoutAttributeBottom
                                                               multiplier:1.0
                                                                 constant:VerticalMargin]];
        } else {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_frequencyButtons[i]
                                                                attribute:NSLayoutAttributeTop
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_frequencyButtons[i-1]
                                                                attribute:NSLayoutAttributeBottom
                                                               multiplier:1.0
                                                                 constant:15.0]];
        }
        
        [constraints addObject:[NSLayoutConstraint constraintWithItem:_frequencyButtons[i]
                                                            attribute:NSLayoutAttributeLeading
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:self.view
                                                            attribute:NSLayoutAttributeLeading
                                                           multiplier:1.0
                                                             constant:LeadingMargin]];
    }
    
    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)didChangePreferredContentSize {
    [self prepareView];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
