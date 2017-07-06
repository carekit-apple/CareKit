/*
 Copyright (c) 2017, Apple Inc. All rights reserved.
 
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


#import "OCKConnectMessageTableViewCell.h"
#import "OCKLabel.h"


static const CGFloat VerticalMargin = 13.0;
static const CGFloat HorizontalMargin = 13.0;
static const CGFloat PaddingMargin = 125.0;

@implementation OCKConnectMessageTableViewCell {
    OCKLabel *_nameLabel;
    OCKLabel *_dateLabel;
    OCKLabel *_messageLabel;
    UIView *_containerView;
    NSMutableArray *_constraints;
}

- (void)setMessageItem:(OCKConnectMessageItem *)messageItem {
    _messageItem = messageItem;
    _usePadding = YES;
    [self prepareView];
}

- (void)setUsePadding:(BOOL)usePadding {
    _usePadding = usePadding;
    [self setUpConstraints];
}

- (void)prepareView {
    self.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    OCKConnectMessageType type = self.messageItem.type;
    UIColor *backgroundColor = (type == OCKConnectMessageTypeReceived) ? [UIColor whiteColor] : self.tintColor;
    UIColor *primaryTextColor = (type == OCKConnectMessageTypeReceived) ? [UIColor blackColor] : [UIColor whiteColor];
    UIColor *secondaryTextColor = (type == OCKConnectMessageTypeReceived) ? [UIColor lightGrayColor] : [UIColor lightTextColor];
    UIColor *bodyTextColor = (type == OCKConnectMessageTypeReceived) ? [UIColor darkGrayColor] : [UIColor lightTextColor];
    
    if (!_containerView) {
        _containerView = [UIView new];
        _containerView.backgroundColor = backgroundColor;
        _containerView.layer.cornerRadius = 5.0;
        [self addSubview:_containerView];
    }
    
    if (!_nameLabel) {
        _nameLabel = [OCKLabel new];
        _nameLabel.textStyle = UIFontTextStyleSubheadline;
        _nameLabel.backgroundColor = backgroundColor;
        _nameLabel.textColor = primaryTextColor;
        _nameLabel.textAlignment = NSTextAlignmentLeft;
        _nameLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [_containerView addSubview:_nameLabel];
    }
    
    if (!_dateLabel) {
        _dateLabel = [OCKLabel new];
        _dateLabel.textStyle = UIFontTextStyleSubheadline;
        _dateLabel.backgroundColor = backgroundColor;
        _dateLabel.textColor = secondaryTextColor;
        _dateLabel.textAlignment = NSTextAlignmentRight;
        _dateLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [_containerView addSubview:_dateLabel];
    }
    
    if (!_messageLabel) {
        _messageLabel = [OCKLabel new];
        _messageLabel.textStyle = UIFontTextStyleSubheadline;
        _messageLabel.backgroundColor = backgroundColor;
        _messageLabel.textColor = bodyTextColor;
        _messageLabel.numberOfLines = 0;
        _messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [_containerView addSubview:_messageLabel];
    }

    [self updateView];
    [self setUpConstraints];
}

- (void)updateView {
    _nameLabel.text = self.messageItem.name;
    _messageLabel.text = self.messageItem.message;
    _dateLabel.text = self.messageItem.dateString;
}

- (void)setUpConstraints {
    [NSLayoutConstraint deactivateConstraints:_constraints];
    
    _constraints = [NSMutableArray new];
    
    _containerView.translatesAutoresizingMaskIntoConstraints = NO;
    _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _messageLabel.translatesAutoresizingMaskIntoConstraints  = NO;
    
    CGFloat paddingMargin = self.usePadding ? PaddingMargin : 75.0;
    
    if (self.messageItem.type == OCKConnectMessageTypeSent) {
        [_constraints addObjectsFromArray:@[
                                            [NSLayoutConstraint constraintWithItem:_containerView
                                                                         attribute:NSLayoutAttributeLeading
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self
                                                                         attribute:NSLayoutAttributeLeading
                                                                        multiplier:1.0
                                                                          constant:paddingMargin],
                                            [NSLayoutConstraint constraintWithItem:self
                                                                         attribute:NSLayoutAttributeTrailing
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:_containerView
                                                                         attribute:NSLayoutAttributeTrailing
                                                                        multiplier:1.0
                                                                          constant:HorizontalMargin]
                                            ]];
    } else {
        [_constraints addObjectsFromArray:@[
                                            [NSLayoutConstraint constraintWithItem:_containerView
                                                                         attribute:NSLayoutAttributeLeading
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self
                                                                         attribute:NSLayoutAttributeLeading
                                                                        multiplier:1.0
                                                                          constant:HorizontalMargin],
                                            [NSLayoutConstraint constraintWithItem:self
                                                                         attribute:NSLayoutAttributeTrailing
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:_containerView
                                                                         attribute:NSLayoutAttributeTrailing
                                                                        multiplier:1.0
                                                                          constant:paddingMargin]
                                            ]];
    }
    
    [_constraints addObjectsFromArray:@[
                                        [NSLayoutConstraint constraintWithItem:_containerView
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:VerticalMargin],
                                        [NSLayoutConstraint constraintWithItem:self
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                        toItem:_containerView
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0
                                                                      constant:0.0]
                                        ]];
    
    [_constraints addObjectsFromArray:@[
                                        [NSLayoutConstraint constraintWithItem:_nameLabel
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_containerView
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:VerticalMargin],
                                        [NSLayoutConstraint constraintWithItem:_messageLabel
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_nameLabel
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0
                                                                      constant:VerticalMargin/2],
                                        [NSLayoutConstraint constraintWithItem:_containerView
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_messageLabel
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0
                                                                      constant:VerticalMargin],
                                        [NSLayoutConstraint constraintWithItem:_dateLabel
                                                                     attribute:NSLayoutAttributeBaseline
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_nameLabel
                                                                     attribute:NSLayoutAttributeBaseline
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        
                                        [NSLayoutConstraint constraintWithItem:_nameLabel
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_containerView
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:HorizontalMargin],
                                        [NSLayoutConstraint constraintWithItem:_dateLabel
                                                                     attribute:NSLayoutAttributeTrailing
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_containerView
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:-HorizontalMargin],
                                        [NSLayoutConstraint constraintWithItem:_nameLabel
                                                                     attribute:NSLayoutAttributeTrailing
                                                                     relatedBy:NSLayoutRelationLessThanOrEqual
                                                                        toItem:_dateLabel
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:-HorizontalMargin],
                                        [NSLayoutConstraint constraintWithItem:_messageLabel
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_containerView
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:HorizontalMargin],
                                        [NSLayoutConstraint constraintWithItem:_messageLabel
                                                                     attribute:NSLayoutAttributeTrailing
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_containerView
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:-HorizontalMargin]
                                        ]];

    
    [NSLayoutConstraint activateConstraints:_constraints];
}

@end
