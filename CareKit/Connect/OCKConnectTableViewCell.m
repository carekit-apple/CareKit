//
//  OCKConnectTableViewCell.m
//  CareKit
//
//  Created by Umer Khan on 2/1/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKConnectTableViewCell.h"
#import "OCKContact.h"


static const CGFloat LeadingMargin = 20.0;
static const CGFloat HorizontalMargin = 5.0;
static const CGFloat VerticalMargin = 2.5;

static const CGFloat ImageViewSize = 35.0;

@implementation OCKConnectTableViewCell {
    UIImageView *_imageView;
    UILabel *_nameLabel;
    UILabel *_relationLabel;
    NSArray<UIButton *> *_buttons;
    UILabel *_leadingEdge;
}

- (void)setContact:(OCKContact *)contact {
    _contact = contact;
    [self prepareView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangePreferredContentSize)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
}

- (void)prepareView {
    if (!_imageView) {
        _imageView = [UIImageView new];
        _imageView.layer.cornerRadius = 30.0;
        _imageView.clipsToBounds = YES;
        _imageView.layer.borderWidth = 1.0;
        _imageView.layer.borderColor = [UIColor grayColor].CGColor;
        [self.contentView addSubview:_imageView];
    }
    _imageView.image = (_contact.image) ? _contact.image : [UIImage imageNamed:@"heart" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    
    if (!_nameLabel) {
        _nameLabel = [UILabel new];
        _nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:_nameLabel];
    }
    _nameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    _nameLabel.text = _contact.name;
    
    if (!_relationLabel) {
        _relationLabel = [UILabel new];
        _relationLabel.textColor = [UIColor lightGrayColor];
        _relationLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:_relationLabel];
    }
    _relationLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    _relationLabel.text = _contact.relation;
    
    NSMutableArray *buttons = [NSMutableArray new];
    if (_contact.phoneNumber) {
        UIButton *phoneButton = [UIButton new];
        phoneButton.backgroundColor = _contact.tintColor;
        phoneButton.tag = OCKConnectTypePhone;
        phoneButton.translatesAutoresizingMaskIntoConstraints = NO;
        [phoneButton setTitle:@"P" forState:UIControlStateNormal];
        [phoneButton addTarget:self
                        action:@selector(buttonSelected:)
              forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:phoneButton];
        [buttons addObject:phoneButton];
    }
    if (_contact.messageNumber) {
        UIButton *messageButton = [UIButton new];
        messageButton.backgroundColor = _contact.tintColor;
        messageButton.tag = OCKConnectTypeMessage;
        messageButton.translatesAutoresizingMaskIntoConstraints = NO;
        [messageButton setTitle:@"M" forState:UIControlStateNormal];
        [messageButton addTarget:self
                          action:@selector(buttonSelected:)
                forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:messageButton];
        [buttons addObject:messageButton];
    }
    if (_contact.emailAddress) {
        UIButton *emailButton = [UIButton new];
        emailButton.backgroundColor = _contact.tintColor;
        emailButton.tag = OCKConnectTypeEmail;
        emailButton.translatesAutoresizingMaskIntoConstraints = NO;
        [emailButton setTitle:@"E" forState:UIControlStateNormal];
        [emailButton addTarget:self
                        action:@selector(buttonSelected:)
              forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:emailButton];
        [buttons addObject:emailButton];
    }
    _buttons = [buttons copy];

    if (!_leadingEdge) {
        _leadingEdge = [UILabel new];
        [self addSubview:_leadingEdge];
    }
    _leadingEdge.backgroundColor = _contact.tintColor;
    
    [self setUpConstraints];
}

- (void)buttonSelected:(id)sender {
    UIButton *button = (UIButton *)sender;
    if (_delegate &&
        [_delegate respondsToSelector:@selector(connectTableViewCell:didSelectConnectType:)]) {
        [_delegate connectTableViewCell:self
                   didSelectConnectType:button.tag];
    }
}

- (void)setUpConstraints {
    NSMutableArray *constraints = [NSMutableArray new];

    _imageView.translatesAutoresizingMaskIntoConstraints = NO;
    _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _relationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _leadingEdge.translatesAutoresizingMaskIntoConstraints = NO;
    
    [constraints addObjectsFromArray:@[
                                       [NSLayoutConstraint constraintWithItem:_imageView
                                                                    attribute:NSLayoutAttributeCenterY
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeCenterY
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_imageView
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeLeading
                                                                   multiplier:1.0
                                                                     constant:LeadingMargin],
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
                                       [NSLayoutConstraint constraintWithItem:_nameLabel
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_imageView
                                                                    attribute:NSLayoutAttributeTrailing
                                                                   multiplier:1.0
                                                                     constant:2*HorizontalMargin],
                                       [NSLayoutConstraint constraintWithItem:_relationLabel
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_nameLabel
                                                                    attribute:NSLayoutAttributeLeading
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:self
                                                                    attribute:NSLayoutAttributeCenterY
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_nameLabel
                                                                    attribute:NSLayoutAttributeCenterY
                                                                   multiplier:1.0
                                                                     constant:2*(_nameLabel.frame.size.height + VerticalMargin)],
                                       [NSLayoutConstraint constraintWithItem:_relationLabel
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_nameLabel
                                                                    attribute:NSLayoutAttributeBottom
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_leadingEdge
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeLeading
                                                                   multiplier:1.0
                                                                     constant:5.0],
                                       [NSLayoutConstraint constraintWithItem:_leadingEdge
                                                                    attribute:NSLayoutAttributeCenterY
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeCenterY
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
                                                                     constant:-20.0]
                                       ]];
    
    for (int i = 0; i < _buttons.count; i++) {
        if (i == 0) {
            [constraints addObjectsFromArray:@[
                                               [NSLayoutConstraint constraintWithItem:_buttons[i]
                                                                            attribute:NSLayoutAttributeTrailing
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:self.contentView
                                                                            attribute:NSLayoutAttributeTrailing
                                                                           multiplier:1.0
                                                                             constant:-LeadingMargin],
                                               [NSLayoutConstraint constraintWithItem:_buttons[i]
                                                                            attribute:NSLayoutAttributeCenterY
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:self.contentView
                                                                            attribute:NSLayoutAttributeCenterY
                                                                           multiplier:1.0
                                                                             constant:0.0]
                                               ]];
        } else {
            [constraints addObjectsFromArray:@[
                                               [NSLayoutConstraint constraintWithItem:_buttons[i]
                                                                            attribute:NSLayoutAttributeTrailing
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:_buttons[i-1]
                                                                            attribute:NSLayoutAttributeLeading
                                                                           multiplier:1.0
                                                                             constant:-HorizontalMargin],
                                               [NSLayoutConstraint constraintWithItem:_buttons[i]
                                                                            attribute:NSLayoutAttributeBottom
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:_buttons[i-1]
                                                                            attribute:NSLayoutAttributeBottom
                                                                           multiplier:1.0
                                                                             constant:0.0]
                                               ]];
        }
    }
    
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

@end
