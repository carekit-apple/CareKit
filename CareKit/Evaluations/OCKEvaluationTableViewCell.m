//
//  OCKEvaluationTableViewCell.m
//  CareKit
//
//  Created by Umer Khan on 2/2/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKEvaluationTableViewCell.h"
#import "OCKEvaluation.h"


const static CGFloat LeadingMargin = 20.0;
const static CGFloat HorizontalMargin = 5.0;
const static CGFloat TrailingMargin = 35.0;

@implementation OCKEvaluationTableViewCell {
    UILabel *_titleLabel;
    UILabel *_textLabel;
    UILabel *_valueLabel;
    
    UILabel *_leadingEdge;
}

- (void)setEvaluation:(OCKEvaluation *)evaluation {
    _evaluation = evaluation;
    [self prepareView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangePreferredContentSize)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
}

- (void)prepareView {
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.numberOfLines = 1;
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:_titleLabel];
    }
    _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    _titleLabel.text = _evaluation.title;
    
    if (!_textLabel) {
        _textLabel = [UILabel new];
        _textLabel.textColor = [UIColor lightGrayColor];
        _textLabel.numberOfLines = 2;
        _textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _textLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_textLabel];
    }
    _textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    _textLabel.text = _evaluation.text;
    
    if (!_valueLabel) {
        _valueLabel = [UILabel new];;
        _valueLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _valueLabel.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:_valueLabel];
    }
    _valueLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle1];
//    _valueLabel.text = [self stringFromSliderValue:_evaluation.value];
//    _valueLabel.textColor = _evaluation.tintColor;
    
    if (!_leadingEdge) {
        _leadingEdge = [UILabel new];
        [self addSubview:_leadingEdge];
    }
//    _leadingEdge.backgroundColor = _evaluation.tintColor;
    
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

- (UITableViewCellSelectionStyle)selectionStyle {
    return UITableViewCellSelectionStyleNone;
}

- (UIEdgeInsets)layoutMargins {
    return UIEdgeInsetsZero;
}

- (void)didChangePreferredContentSize {
    [self prepareView];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Helpers

- (NSString *)stringFromSliderValue:(CGFloat)value {
    NSNumber *number = [NSNumber numberWithFloat:10*value];
    return [NSString stringWithFormat:@"%d", number.intValue];
}

@end
