//
//  OCKCareCardDetailHeaderView.m
//  CareKit
//
//  Created by Umer Khan on 3/4/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKCareCardDetailHeaderView.h"
#import "OCKCarePlanActivity.h"


static const CGFloat BottomMargin = 15.0;
static const CGFloat LeadingMargin = 20.0;

@implementation OCKCareCardDetailHeaderView {
    UILabel *_titleLabel;
    UILabel *_textLabel;
    UILabel *_leadingEdge;
    
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
    self.backgroundColor = [UIColor whiteColor];
    
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        [self addSubview:_titleLabel];
    }
    _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle1];
    _titleLabel.text = _treatment.title;
    
    if (!_textLabel) {
        _textLabel = [UILabel new];
        _textLabel.textColor = [UIColor lightGrayColor];
        _textLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightLight];
        [self addSubview:_textLabel];
    }
    _textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3];
    _textLabel.text = _treatment.text;
    
    if (!_leadingEdge) {
        _leadingEdge = [UILabel new];
        [self addSubview:_leadingEdge];
    }
    _leadingEdge.backgroundColor = _treatment.tintColor;
    
    [self setUpConstraints];
}

- (void)setUpConstraints {
    _constraints = [NSMutableArray new];
    
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _leadingEdge.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_constraints addObjectsFromArray:@[
                                        [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:LeadingMargin],
                                        [NSLayoutConstraint constraintWithItem:_textLabel
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_titleLabel
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_textLabel
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:self
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_textLabel
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0
                                                                      constant:BottomMargin],
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
    
    [NSLayoutConstraint activateConstraints:_constraints];
    
}

- (void)setTreatment:(OCKCarePlanActivity *)treatment {
    _treatment = treatment;
    [self prepareView];
}

@end
