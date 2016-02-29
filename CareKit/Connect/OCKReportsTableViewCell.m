//
//  OCKReportTableViewCell.m
//  CareKit
//
//  Created by Umer Khan on 2/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKReportsTableViewCell.h"
#import "OCKContact.h"


static const CGFloat LeadingMargin = 20.0;
static const CGFloat TrailingMargin = 20.0;


@implementation OCKReportsTableViewCell {
    UILabel *_titleLabel;
    UIButton *_shareButton;
}

- (void)setTitle:(NSString *)title {
    _title = title;
    [self prepareView];
}

- (void)setContact:(OCKContact *)contact {
    _contact = contact;
    [self prepareView];
}

- (void)prepareView {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
        [self.contentView addSubview:_titleLabel];
    }
    _titleLabel.text = _title;
    
    if (!_shareButton) {
        _shareButton = [UIButton new];
        [_shareButton addTarget:self
                         action:@selector(buttonSelected:)
               forControlEvents:UIControlEventTouchUpInside];
        UIImage *shareIcon = [[UIImage imageNamed:@"share" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_shareButton setImage:shareIcon forState:UIControlStateNormal];
        [self.contentView addSubview:_shareButton];
    }
    _shareButton.tintColor = _contact.tintColor;
    
    [self setUpConstraints];
}

- (void)setUpConstraints {
    NSMutableArray *constraints = [NSMutableArray new];
    
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _shareButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [constraints addObjectsFromArray:@[
                                       [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                    attribute:NSLayoutAttributeCenterY
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeCenterY
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeLeading
                                                                   multiplier:1.0
                                                                     constant:LeadingMargin],
                                       [NSLayoutConstraint constraintWithItem:_shareButton
                                                                    attribute:NSLayoutAttributeTrailing
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeTrailing
                                                                   multiplier:1.0
                                                                     constant:-TrailingMargin],
                                       [NSLayoutConstraint constraintWithItem:_shareButton
                                                                    attribute:NSLayoutAttributeCenterY
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeCenterY
                                                                   multiplier:1.0
                                                                     constant:0.0]
                                       ]];
    
    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)buttonSelected:(id)sender {
    if (_delegate &&
        [_delegate respondsToSelector:@selector(reportsTableViewCellDidSelectShareButton:)]) {
        [_delegate reportsTableViewCellDidSelectShareButton:self];
    }
}

@end
