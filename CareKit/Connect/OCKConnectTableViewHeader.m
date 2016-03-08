//
//  OCKConnectHeaderView.m
//  CareKit
//
//  Created by Umer Khan on 2/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKConnectTableViewHeader.h"
#import "OCKContact.h"


static const CGFloat TopMargin = 15.0;
static const CGFloat VerticalMargin = 20.0;
static const CGFloat LeadingMargin = 20.0;

static const CGFloat ImageViewSize = 135.0;

@implementation OCKConnectTableViewHeader {
    UIImageView *_imageView;
    UILabel *_titleLabel;
    UILabel *_relationLabel;
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
    
    if (!_imageView) {
        _imageView = [UIImageView new];
        _imageView.layer.cornerRadius = 70.0;
        _imageView.clipsToBounds = YES;
        _imageView.layer.borderWidth = 1.0;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:_imageView];
    }
    _imageView.layer.borderColor = _contact.tintColor.CGColor;
    _imageView.image = (_contact.image) ? _contact.image : [UIImage imageNamed:@"contact" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        [self addSubview:_titleLabel];
    }
    _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    _titleLabel.text = _contact.name;
    
    if (!_relationLabel) {
        _relationLabel = [UILabel new];
        _relationLabel.textColor = [UIColor lightGrayColor];
        _relationLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightLight];
        [self addSubview:_relationLabel];
    }
    _relationLabel.text = _contact.relation;
    
    if (!_leadingEdge) {
        _leadingEdge = [UILabel new];
        [self addSubview:_leadingEdge];
    }
    _leadingEdge.backgroundColor = _contact.tintColor;
    
    [self setUpConstraints];
}

- (void)setUpConstraints {
    _constraints = [NSMutableArray new];
    
    _imageView.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _relationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _leadingEdge.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_constraints addObjectsFromArray:@[
                                        [NSLayoutConstraint constraintWithItem:_imageView
                                                                     attribute:NSLayoutAttributeCenterX
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeCenterX
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_imageView
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:TopMargin],
                                        [NSLayoutConstraint constraintWithItem:_imageView
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_titleLabel
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:-VerticalMargin],
                                        [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:LeadingMargin],
                                        [NSLayoutConstraint constraintWithItem:_relationLabel
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_titleLabel
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_relationLabel
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_imageView
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1.0
                                                                      constant:ImageViewSize],
                                        [NSLayoutConstraint constraintWithItem:_imageView
                                                                     attribute:NSLayoutAttributeWidth
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1.0
                                                                      constant:ImageViewSize],
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
    
    [NSLayoutConstraint activateConstraints:_constraints];
    
}

- (void)setContact:(OCKContact *)contact {
    _contact = contact;
    [self prepareView];
}

@end
