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


static const CGFloat LeadingMargin = 15.0;
static const CGFloat TrailingMargin = 15.0;

@implementation OCKInsightsTableViewHeaderView {
    UILabel *_titleLabel;
    UILabel *_subtitleLabel;
    NSMutableArray *_constraints;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self prepareView];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateFonts)
                                                     name:UIContentSizeCategoryDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)prepareView {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.textColor = [UIColor darkGrayColor];
        [self addSubview:_titleLabel];
    }
    
    if (!_subtitleLabel) {
        _subtitleLabel = [UILabel new];
        _subtitleLabel.textColor = [UIColor darkGrayColor];
        [self addSubview:_subtitleLabel];
    }

    [self updateView];
    [self updateFonts];
    [self setUpConstraints];
}

- (void)updateView {
    _titleLabel.text = _title;
    _subtitleLabel.text = _subtitle;
}

- (void)updateFonts {
    _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    _subtitleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
}

- (void)setUpConstraints {
    [NSLayoutConstraint deactivateConstraints:_constraints];
    
    _constraints = [NSMutableArray new];
    
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_constraints addObjectsFromArray:@[
                                       [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                    attribute:NSLayoutAttributeCenterY
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeCenterY
                                                                   multiplier:1.0
                                                                     constant:-20.0],
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
                                       [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                    attribute:NSLayoutAttributeTrailing
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeTrailing
                                                                   multiplier:1.0
                                                                     constant:-TrailingMargin],
                                       [NSLayoutConstraint constraintWithItem:_subtitleLabel
                                                                    attribute:NSLayoutAttributeTrailing
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeTrailing
                                                                   multiplier:1.0
                                                                     constant:-TrailingMargin]
                                       ]];

    [NSLayoutConstraint activateConstraints:_constraints];
}

- (void)setTitle:(NSString *)title {
    _title = title;
    [self prepareView];
}

- (void)setSubtitle:(NSString *)subtitle {
    _subtitle = subtitle;
    [self prepareView];
}

@end
