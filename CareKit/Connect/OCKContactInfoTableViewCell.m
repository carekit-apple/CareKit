/*
 Copyright (c) 2016, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "OCKContactInfoTableViewCell.h"
#import "OCKContact.h"
#import "OCKDefines_Private.h"
#import "OCKHelpers.h"
#import "OCKLabel.h"


static const CGFloat TopMargin = 20.0;
static const CGFloat BottomMargin = 20.0;
static const CGFloat HorizontalMargin = 5.0;
static const CGFloat IconButtonSize = 35.0;

@implementation OCKContactInfoTableViewCell {
    OCKLabel *_connectTypeLabel;
    OCKLabel *_textLabel;
    UIButton *_iconButton;
    NSMutableArray *_constraints;
}

- (void)setContact:(OCKContact *)contact {
    _contact = contact;
    self.tintColor = _contact.tintColor;
    [self prepareView];
}

- (void)setConnectType:(OCKConnectType)connectType {
    _connectType = connectType;
    [self prepareView];
}

- (void)prepareView {
    if (!_iconButton) {
        _iconButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_iconButton addTarget:self
                        action:@selector(buttonSelected:)
              forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_iconButton];
    }
    
    if (!_connectTypeLabel) {
        _connectTypeLabel = [OCKLabel new];
        _connectTypeLabel.textStyle = UIFontTextStyleFootnote;
        [self addSubview:_connectTypeLabel];
    }
    
    if (!_textLabel) {
        _textLabel = [OCKLabel new];
        _textLabel.textStyle = UIFontTextStyleBody;
        [self addSubview:_textLabel];
    }
    
    [self updateView];
    [self setUpConstraints];
}

- (void)updateView {
    NSString *imageNamed;
    NSString *title;
    NSString *connectTypeText;
    switch (self.connectType) {
        case OCKConnectTypePhone:
            imageNamed = @"phone";
            connectTypeText = OCKLocalizedString(@"CONTACT_INFO_PHONE_TITLE", nil);
            title = self.contact.phoneNumber.stringValue;
            break;
            
        case OCKConnectTypeMessage:
            imageNamed = @"message";
            connectTypeText = OCKLocalizedString(@"CONTACT_INFO_MESSAGE_TITLE", nil);
            title = self.contact.messageNumber.stringValue;
            break;
            
        case OCKConnectTypeEmail:
            imageNamed = @"email";
            connectTypeText = OCKLocalizedString(@"CONTACT_INFO_EMAIL_TITLE", nil);
            title = self.contact.emailAddress;
            break;
    }
    UIImage *image = [[UIImage imageNamed:imageNamed inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [_iconButton setImage:image forState:UIControlStateNormal];
    
    _iconButton.tintColor = self.tintColor;
    _connectTypeLabel.textColor = self.tintColor;
    _connectTypeLabel.text = connectTypeText;
    _textLabel.text = title;
}

- (void)setUpConstraints {
    [NSLayoutConstraint deactivateConstraints:_constraints];
    
    _constraints = [NSMutableArray new];
    
    _iconButton.translatesAutoresizingMaskIntoConstraints = NO;
    _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _connectTypeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    CGFloat LeadingMargin = self.separatorInset.left;
    CGFloat TrailingMargin = (self.separatorInset.right > 0) ? self.separatorInset.right : 20;
    
    [_constraints addObjectsFromArray:@[
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
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_connectTypeLabel
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_textLabel
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0
                                                                      constant:-BottomMargin],
                                        [NSLayoutConstraint constraintWithItem:_textLabel
                                                                     attribute:NSLayoutAttributeTrailing
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_iconButton
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:-HorizontalMargin],
                                        ]];
    
    [NSLayoutConstraint activateConstraints:_constraints];
}

- (void)buttonSelected:(id)sender {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(contactInfoTableViewCellDidSelectConnection:)]) {
        [self.delegate contactInfoTableViewCellDidSelectConnection:self];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self setUpConstraints];
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    [self updateView];
}


#pragma mark - Accessibility

- (BOOL)isAccessibilityElement {
    return YES;
}

- (NSString *)accessibilityLabel {
    return OCKAccessibilityStringForVariables(_connectTypeLabel, _textLabel);
}

- (UIAccessibilityTraits)accessibilityTraits {
    return UIAccessibilityTraitButton;
}

- (CGPoint)accessibilityActivationPoint {
    return [_iconButton accessibilityActivationPoint];
}

@end
