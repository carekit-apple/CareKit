//
//  OCKContactInfoTableViewCell.m
//  CareKit
//
//  Created by Umer Khan on 2/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKContactInfoTableViewCell.h"
#import "OCKContact.h"


static const CGFloat TopMargin = 15.0;
static const CGFloat LeadingMargin = 20.0;
static const CGFloat TrailingMargin = 20.0;

static const CGFloat IconButtonSize = 35.0;

@implementation OCKContactInfoTableViewCell {
    UILabel *_connectTypeLabel;
    UILabel *_textLabel;
    UIButton *_iconButton;
}

- (void)setContact:(OCKContact *)contact {
    _contact = contact;
    [self prepareView];
}

- (void)setConnectType:(OCKConnectType)connectType {
    _connectType = connectType;
    [self prepareView];
}

- (void)prepareView {
    if (!_iconButton) {
        _iconButton = [UIButton new];
        [_iconButton addTarget:self
                        action:@selector(buttonSelected:)
              forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_iconButton];
    }
    _iconButton.tintColor = _contact.tintColor;
    
    NSString *imageNamed;
    NSString *title;
    NSString *connectTypeText;
    switch (_connectType) {
        case OCKConnectTypePhone:
            imageNamed = @"phone";
            connectTypeText = @"phone";
            title = _contact.phoneNumber;
            break;
            
        case OCKConnectTypeEmail:
            imageNamed = @"email";
            connectTypeText = @"email";
            title = _contact.emailAddress;
            break;
            
        case OCKConnectTypeMessage:
            imageNamed = @"message";
            connectTypeText = @"message";
            title = _contact.messageNumber;
            break;
    }
    UIImage *image = [[UIImage imageNamed:imageNamed inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [_iconButton setImage:image forState:UIControlStateNormal];
    
    if (!_connectTypeLabel) {
        _connectTypeLabel = [UILabel new];
        [self addSubview:_connectTypeLabel];
    }
    _connectTypeLabel.textColor = _contact.tintColor;
    _connectTypeLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    _connectTypeLabel.text = connectTypeText;
    
    if (!_textLabel) {
        _textLabel = [UILabel new];
        _textLabel.textColor = [UIColor blackColor];
        _textLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
        [self.contentView addSubview:_textLabel];
    }
    _textLabel.text = title;
    
    [self setUpConstraints];
}

- (void)setUpConstraints {
    NSMutableArray *constraints = [NSMutableArray new];
    
    _iconButton.translatesAutoresizingMaskIntoConstraints = NO;
    _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _connectTypeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [constraints addObjectsFromArray:@[
                                       [NSLayoutConstraint constraintWithItem:_connectTypeLabel
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeTop
                                                                   multiplier:1.0
                                                                     constant:TopMargin],
                                       [NSLayoutConstraint constraintWithItem:_connectTypeLabel
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeLeading
                                                                   multiplier:1.0
                                                                     constant:LeadingMargin],
                                       [NSLayoutConstraint constraintWithItem:_iconButton
                                                                    attribute:NSLayoutAttributeCenterY
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeCenterY
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_iconButton
                                                                    attribute:NSLayoutAttributeTrailing
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeTrailing
                                                                   multiplier:1.0
                                                                     constant:-TrailingMargin],
                                       [NSLayoutConstraint constraintWithItem:_iconButton
                                                                    attribute:NSLayoutAttributeWidth
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:nil
                                                                    attribute:NSLayoutAttributeNotAnAttribute
                                                                   multiplier:1.0
                                                                     constant:IconButtonSize],
                                       [NSLayoutConstraint constraintWithItem:_iconButton
                                                                    attribute:NSLayoutAttributeHeight
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:nil
                                                                    attribute:NSLayoutAttributeNotAnAttribute
                                                                   multiplier:1.0
                                                                     constant:IconButtonSize],
                                       [NSLayoutConstraint constraintWithItem:_textLabel
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeLeading
                                                                   multiplier:1.0
                                                                     constant:LeadingMargin],
                                       [NSLayoutConstraint constraintWithItem:_textLabel
                                                                    attribute:NSLayoutAttributeCenterY
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeCenterY
                                                                   multiplier:1.0
                                                                     constant:5.0]
                                       ]];
    
    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)buttonSelected:(id)sender {
    if (_delegate &&
        [_delegate respondsToSelector:@selector(contactInfoTableViewCellDidSelectConnection:)]) {
        [_delegate contactInfoTableViewCellDidSelectConnection:self];
    }
}

@end
