//
//  OCKEvaluationTableViewCell.m
//  CareKit
//
//  Created by Umer Khan on 2/2/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKEvaluationTableViewCell.h"
#import "OCKCarePlanEvent.h"


const static CGFloat LeadingMargin = 20.0;
const static CGFloat HorizontalMargin = 5.0;
const static CGFloat TrailingMargin = 35.0;

const static CGFloat ValueLabelWidth = 100.0;

@implementation OCKEvaluationTableViewCell {
    UILabel *_titleLabel;
    UILabel *_textLabel;
    UILabel *_valueLabel;
    
    UIView *_leadingEdge;
}

- (void)setEvaluationEvent:(OCKEvaluationEvent *)evaluationEvent {
    _evaluationEvent = evaluationEvent;
    [self prepareView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangePreferredContentSize)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
}

- (void)prepareView {
    self.tintColor = _evaluationEvent.evaluation.color;
    
    if (_evaluationEvent.state == OCKCareEventStateCompleted) {
        self.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.numberOfLines = 1;
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:_titleLabel];
    }
    _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    _titleLabel.text = _evaluationEvent.evaluation.title;
    
    if (!_textLabel) {
        _textLabel = [UILabel new];
        _textLabel.numberOfLines = 2;
        _textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _textLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_textLabel];
    }
    _textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    _textLabel.text = _evaluationEvent.evaluation.text;
    
    if (!_valueLabel) {
        _valueLabel = [UILabel new];;
        _valueLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _valueLabel.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:_valueLabel];
    }
    _valueLabel.text = (_evaluationEvent.evaluationValueString.length > 0) ? _evaluationEvent.evaluationValueString : @"--";
    _valueLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle1];
    _valueLabel.textColor = _evaluationEvent.evaluation.color;
    
    if (!_leadingEdge) {
        _leadingEdge = [UIView new];
        [self.contentView addSubview:_leadingEdge];
    }
    _leadingEdge.backgroundColor = _evaluationEvent.evaluation.color;
    if (_evaluationEvent.state == OCKCareEventStateCompleted && !_evaluationEvent.evaluation.allowRetry) {
        _leadingEdge.alpha = 0.25;
    }
    
    [self setUpConstraints];
}

- (void)setUpConstraints {
    NSMutableArray *constraints = [NSMutableArray new];
    
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _leadingEdge.translatesAutoresizingMaskIntoConstraints = NO;
    
    [constraints addObjectsFromArray:@[
                                       [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.contentView
                                                                    attribute:NSLayoutAttributeLeading
                                                                   multiplier:1.0
                                                                     constant:LeadingMargin],
                                       [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                    attribute:NSLayoutAttributeCenterY
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.contentView
                                                                    attribute:NSLayoutAttributeCenterY
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_textLabel
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_titleLabel
                                                                    attribute:NSLayoutAttributeTrailing
                                                                   multiplier:1.0
                                                                     constant:HorizontalMargin],
                                       [NSLayoutConstraint constraintWithItem:_textLabel
                                                                    attribute:NSLayoutAttributeBaseline
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_titleLabel
                                                                    attribute:NSLayoutAttributeBaseline
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:self
                                                                    attribute:NSLayoutAttributeTrailing
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_valueLabel
                                                                    attribute:NSLayoutAttributeTrailing
                                                                   multiplier:1.0
                                                                     constant:TrailingMargin],
                                       [NSLayoutConstraint constraintWithItem:_valueLabel
                                                                    attribute:NSLayoutAttributeCenterY
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeCenterY
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_valueLabel
                                                                    attribute:NSLayoutAttributeWidth
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:nil
                                                                    attribute:NSLayoutAttributeNotAnAttribute
                                                                   multiplier:1.0
                                                                     constant:ValueLabelWidth],
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
    
    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)didChangePreferredContentSize {
    [self prepareView];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
