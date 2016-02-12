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
static const CGFloat TopMargin = 13.0;
static const CGFloat VerticalMargin = 5.0;
static const CGFloat HorizontalMargin = 5.0;

@implementation OCKConnectTableViewCell {
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

    _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _relationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _leadingEdge.translatesAutoresizingMaskIntoConstraints = NO;
    
    [constraints addObjectsFromArray:@[
                                       [NSLayoutConstraint constraintWithItem:_nameLabel
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeLeading
                                                                   multiplier:1.0
                                                                     constant:LeadingMargin],
                                       [NSLayoutConstraint constraintWithItem:_relationLabel
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_nameLabel
                                                                    attribute:NSLayoutAttributeTrailing
                                                                   multiplier:1.0
                                                                     constant:HorizontalMargin],
                                       [NSLayoutConstraint constraintWithItem:_nameLabel
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeTop
                                                                   multiplier:1.0
                                                                     constant:TopMargin],
                                       [NSLayoutConstraint constraintWithItem:_relationLabel
                                                                    attribute:NSLayoutAttributeBaseline
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_nameLabel
                                                                    attribute:NSLayoutAttributeBaseline
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
    
    for (int i = 0; i < _buttons.count; i++) {
        if (i == 0) {
            [constraints addObjectsFromArray:@[
                                               [NSLayoutConstraint constraintWithItem:_buttons[i]
                                                                            attribute:NSLayoutAttributeLeading
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:_nameLabel
                                                                            attribute:NSLayoutAttributeLeading
                                                                           multiplier:1.0
                                                                             constant:0.0],
                                               [NSLayoutConstraint constraintWithItem:_buttons[i]
                                                                            attribute:NSLayoutAttributeTop
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:_nameLabel
                                                                            attribute:NSLayoutAttributeBottom
                                                                           multiplier:1.0
                                                                             constant:VerticalMargin]
                                               ]];
        } else {
            [constraints addObjectsFromArray:@[
                                               [NSLayoutConstraint constraintWithItem:_buttons[i]
                                                                            attribute:NSLayoutAttributeLeading
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:_buttons[i-1]
                                                                            attribute:NSLayoutAttributeTrailing
                                                                           multiplier:1.0
                                                                             constant:HorizontalMargin],
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
