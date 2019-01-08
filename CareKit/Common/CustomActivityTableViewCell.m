//
//  CustomActivityTableViewCell.m
//  CareKit
//
//  Created by Damian Dara on 9/1/19.
//  Copyright © 2019 carekit.org. All rights reserved.
//

#import "OCKLabel.h"
#import "CustomActivityTableViewCell.h"

static const CGFloat TopMargin = 5.0;
static const CGFloat BottomMargin = -5.0;
static const CGFloat HorizontalMargin = 5.0;

@implementation CustomActivityTableViewCell {
    OCKLabel *_titleLabel;
    OCKLabel *_valueLabel;
    OCKLabel *_updatedAtLabel;
    UIView *_roundedView;
    NSMutableArray *_constraints;
}

- (void)setCellBackgroundColor:(UIColor *)cellBackgroundColor {
    if (_roundedView) {
        _roundedView.backgroundColor = cellBackgroundColor;
    }
}

- (void)setEvent:(OCKCarePlanEvent *)event {
    _event = event;
    [self prepareView];
}

- (void)prepareView {
    self.accessoryType = UITableViewCellAccessoryNone;
    self.backgroundColor = nil;

    if (!_roundedView) {
        _roundedView = [UIView new];
        _roundedView.layer.cornerRadius = 5.0;
        _roundedView.layer.masksToBounds = YES;
        [self.contentView addSubview:_roundedView];
    }

    if (!_titleLabel) {
        _titleLabel = [OCKLabel new];
        _titleLabel.textStyle = UIFontTextStyleHeadline;
        _titleLabel.textColor = [UIColor whiteColor];
        [_roundedView addSubview:_titleLabel];
    }

    if (!_valueLabel) {
        _valueLabel = [OCKLabel new];
        _valueLabel.textColor = [UIColor whiteColor];
        _valueLabel.font = [UIFont systemFontOfSize:49 weight:UIFontWeightRegular];
        _valueLabel.textAlignment = NSLayoutAttributeRight;
        [_roundedView addSubview:_valueLabel];
    }

    if (!_updatedAtLabel) {
        _updatedAtLabel = [OCKLabel new];
        _updatedAtLabel.textColor = [UIColor whiteColor];
        _updatedAtLabel.textStyle = UIFontTextStyleFootnote;
        _updatedAtLabel.textAlignment = NSLayoutAttributeRight;
        [_roundedView addSubview:_updatedAtLabel];
    }

    [self updateView];
    [self setUpConstraints];
}

- (void)updateView {
    _titleLabel.text = _event.activity.title;
    _valueLabel.text = _event.result.valueString;
    _updatedAtLabel.text = _event.activity.text;
}

- (void)setUpConstraints {
    [NSLayoutConstraint deactivateConstraints:_constraints];

    _constraints = [NSMutableArray new];

    _roundedView.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _updatedAtLabel.translatesAutoresizingMaskIntoConstraints = NO;

    CGFloat LeadingMargin = self.separatorInset.left;
    CGFloat TrailingMargin = (self.separatorInset.right > 0) ? -self.separatorInset.right : -15;

    [_constraints addObjectsFromArray:@[
                                        [NSLayoutConstraint constraintWithItem:_roundedView
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.contentView
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:TopMargin],

                                        [NSLayoutConstraint constraintWithItem:_roundedView
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.contentView
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:LeadingMargin],

                                        [NSLayoutConstraint constraintWithItem:_roundedView
                                                                     attribute:NSLayoutAttributeTrailing
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.contentView
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:TrailingMargin],

                                        [NSLayoutConstraint constraintWithItem:_roundedView
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.contentView
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0
                                                                      constant:-2.5],

                                        [NSLayoutConstraint constraintWithItem:_valueLabel
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_roundedView
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:TopMargin],

                                        [NSLayoutConstraint constraintWithItem:_valueLabel
                                                                     attribute:NSLayoutAttributeTrailing
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_roundedView
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:-12.0],

                                        [NSLayoutConstraint constraintWithItem:_valueLabel
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_titleLabel
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:HorizontalMargin],

                                        [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_roundedView
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:8.0],

                                        [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_valueLabel
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:0.0],

                                        [NSLayoutConstraint constraintWithItem:_updatedAtLabel
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_titleLabel
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:0.0],

                                        [NSLayoutConstraint constraintWithItem:_updatedAtLabel
                                                                     attribute:NSLayoutAttributeTrailing
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_valueLabel
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:0.0],

                                        [NSLayoutConstraint constraintWithItem:_updatedAtLabel
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_valueLabel
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0
                                                                      constant:HorizontalMargin],

                                        [NSLayoutConstraint constraintWithItem:_updatedAtLabel
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_roundedView
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0
                                                                      constant:BottomMargin]
                                        ]];

    [NSLayoutConstraint activateConstraints:_constraints];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self setUpConstraints];
}

@end
