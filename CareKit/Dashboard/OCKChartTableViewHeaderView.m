//
//  OCKChartTableViewHeaderView.m
//  CareKit
//
//  Created by Umer Khan on 1/25/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKChartTableViewHeaderView.h"


static const CGFloat LeadingMargin = 15.0;

@implementation OCKChartTableViewHeaderView {
    UILabel *_titleLabel;
    UILabel *_textLabel;
    
    NSMutableArray *_constraints;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self prepareView];
    }
    return self;
}

- (void)prepareView {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _titleLabel.textColor = [UIColor darkGrayColor];
        [self addSubview:_titleLabel];
    }
    _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    
    if (!_textLabel) {
        _textLabel = [UILabel new];
        _textLabel.numberOfLines = 2;
        _textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _textLabel.textColor = [UIColor darkGrayColor];
        [self addSubview:_textLabel];
    }
    _textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    
    [self setUpConstraints];
}

- (void)setUpConstraints {
    [NSLayoutConstraint activateConstraints:_constraints];
    
    _constraints = [NSMutableArray new];
    
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_constraints addObjectsFromArray:@[
                                       [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                    attribute:NSLayoutAttributeCenterY
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeCenterY
                                                                   multiplier:1.0
                                                                     constant:-10.0],
                                       [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeLeading
                                                                   multiplier:1.0
                                                                     constant:LeadingMargin],
                                       [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                    attribute:NSLayoutAttributeBottom
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_textLabel
                                                                    attribute:NSLayoutAttributeTop
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_textLabel
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeLeading
                                                                   multiplier:1.0
                                                                     constant:LeadingMargin]
                                       ]];

    [NSLayoutConstraint activateConstraints:_constraints];

}

- (void)setTitle:(NSString *)title {
    _title = title;
    _titleLabel.text = _title;
    [_titleLabel sizeToFit];
    [self setUpConstraints];
}

- (void)setText:(NSString *)text {
    _text = text;
    _textLabel.text = _text;
    [_textLabel sizeToFit];
    [self setUpConstraints];
}

@end
