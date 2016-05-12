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


#import "OCKInsightsTableViewHeaderView.h"
#import "OCKHelpers.h"
#import "OCKLabel.h"


static const CGFloat TopMargin = 20.0;
static const CGFloat LeadingMargin = 15.0;
static const CGFloat TrailingMargin = 15.0;
static const CGFloat BottomMargin = 20.0;

@implementation OCKInsightsTableViewHeaderView {
    OCKLabel *_titleLabel;
    OCKLabel *_subtitleLabel;
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
        _titleLabel = [OCKLabel new];
        _titleLabel.backgroundColor = OCKSystemGrayColor();
        _titleLabel.textColor = [UIColor darkGrayColor];
        _titleLabel.textStyle = UIFontTextStyleHeadline;
        [self addSubview:_titleLabel];
    }
    
    if (!_subtitleLabel) {
        _subtitleLabel = [OCKLabel new];
        _subtitleLabel.backgroundColor = OCKSystemGrayColor();
        _subtitleLabel.textStyle = UIFontTextStyleSubheadline;
        _subtitleLabel.numberOfLines = 2;
        _subtitleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _subtitleLabel.textColor = [UIColor darkGrayColor];
        [self addSubview:_subtitleLabel];
    }
    
    [self updateView];
    [self setUpConstraints];
}

- (void)updateView {
    _titleLabel.text = self.title;
    _subtitleLabel.text = self.subtitle;
}

- (void)setUpConstraints {
    [NSLayoutConstraint deactivateConstraints:_constraints];
    
    _constraints = [NSMutableArray new];
    
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_constraints addObjectsFromArray:@[
                                        [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:TopMargin],
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
                                                                        toItem:_subtitleLabel
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_subtitleLabel
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:LeadingMargin],
                                        [NSLayoutConstraint constraintWithItem:self
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_subtitleLabel
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0
                                                                      constant:BottomMargin]
                                        ]];
    
    
    NSLayoutConstraint *titleTrailingConstraint = [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                               attribute:NSLayoutAttributeTrailing
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:self
                                                                               attribute:NSLayoutAttributeTrailing
                                                                              multiplier:1.0
                                                                                constant:-TrailingMargin];
    titleTrailingConstraint.priority = 999;
    
    NSLayoutConstraint *subtitleTrailingConstraint = [NSLayoutConstraint constraintWithItem:_subtitleLabel
                                                                                  attribute:NSLayoutAttributeTrailing
                                                                                  relatedBy:NSLayoutRelationEqual
                                                                                     toItem:self
                                                                                  attribute:NSLayoutAttributeTrailing
                                                                                 multiplier:1.0
                                                                                   constant:-TrailingMargin];
    subtitleTrailingConstraint.priority = 999;
    
    [_constraints addObject:titleTrailingConstraint];
    [_constraints addObject:subtitleTrailingConstraint];
    
    [NSLayoutConstraint activateConstraints:_constraints];
}

- (void)setTitle:(NSString *)title {
    _title = [title copy];
    [self updateView];
}

- (void)setSubtitle:(NSString *)subtitle {
    _subtitle = [subtitle copy];
    [self updateView];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    _titleLabel.backgroundColor = backgroundColor;
    _subtitleLabel.backgroundColor = backgroundColor;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _titleLabel.preferredMaxLayoutWidth = _titleLabel.bounds.size.width;
    _subtitleLabel.preferredMaxLayoutWidth = _subtitleLabel.bounds.size.width;
}


#pragma mark - Accessibility

- (BOOL)isAccessibilityElement {
    return YES;
}

- (NSString *)accessibilityLabel {
    return OCKAccessibilityStringForVariables(_titleLabel, _subtitleLabel);
}

@end
