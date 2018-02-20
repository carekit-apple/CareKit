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


#import "OCKHeaderView.h"
#import "OCKRingView.h"
#import "OCKHelpers.h"
#import "OCKDefines_Private.h"
#import "OCKLabel.h"


static const CGFloat RingViewSize = 110.0;

@implementation OCKHeaderView {
    OCKLabel *_dateLabel;
    OCKLabel *_titleLabel;
    UIStackView *_horizontalStackView;
    UIStackView *_verticalStackView;
    NSNumberFormatter *_numberFormatter;
    NSMutableArray *_constraints;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        if (!UIAccessibilityIsReduceTransparencyEnabled()) {
            self.backgroundColor = [UIColor groupTableViewBackgroundColor];
            
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleProminent];
            UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            blurEffectView.frame = self.bounds;
            blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self addSubview:blurEffectView];
        }
        else {
            self.backgroundColor = [UIColor whiteColor];
        }
        
        [self prepareView];
    }
    return self;
}

- (void)prepareView {
    if (!_ringView) {
        _ringView = [[OCKRingView alloc] initWithFrame:CGRectMake(0, 0, RingViewSize, RingViewSize)
                                          useSmallRing:NO];
        [self addSubview:_ringView];
    }
    
    if (!_dateLabel) {
        _dateLabel = [OCKLabel new];
        _dateLabel.textStyle = UIFontTextStyleCaption1;
        _dateLabel.textColor = [UIColor lightGrayColor];
        _dateLabel.numberOfLines = 0;
    }
    
    if (!_titleLabel) {
        _titleLabel = [OCKLabel new];
        _titleLabel.numberOfLines = 0;
        _titleLabel.textStyle = UIFontTextStyleHeadline;
    }
    
    if (!_verticalStackView) {
        _verticalStackView = [[UIStackView alloc] initWithArrangedSubviews:@[_dateLabel, _titleLabel]];
        _verticalStackView.spacing = 5.0;
        _verticalStackView.axis = UILayoutConstraintAxisVertical;
        _verticalStackView.distribution = UIStackViewDistributionEqualCentering;
        [self addSubview:_verticalStackView];
    }
    
    [self updateView];
    [self setUpConstraints];
}

- (void)updateView {
    if (self.title.length > 0) {
        _titleLabel.text = self.title;
    } else if (self.isCareCard) {
        _titleLabel.text = [NSString stringWithFormat:OCKLocalizedString(@"HEADER_TITLE_CARE_OVERVIEW", nil), [self valuePercentageString]];
    } else {
        _titleLabel.text = [NSString stringWithFormat:OCKLocalizedString(@"HEADER_TITLE_ACTIVITY_STATUS", nil), [self valuePercentageString]];
    }
    _dateLabel.text = self.date;
    
    self.ringView.tintColor = self.tintColor;
    self.ringView.glyphImage = self.glyphImage;
    self.ringView.isCareCard = self.isCareCard;
    self.ringView.glyphType = self.glyphType;
    self.ringView.value = self.value;
}

- (void)setUpConstraints {
    [NSLayoutConstraint deactivateConstraints:_constraints];
    
    _constraints = [NSMutableArray new];
    
    _ringView.translatesAutoresizingMaskIntoConstraints = NO;
    _verticalStackView.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_constraints addObjectsFromArray:@[
                                        [NSLayoutConstraint constraintWithItem:_verticalStackView
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_ringView
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:15.0],
                                        [NSLayoutConstraint constraintWithItem:_verticalStackView
                                                                     attribute:NSLayoutAttributeTrailing
                                                                     relatedBy:NSLayoutRelationLessThanOrEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:-10.0],
                                        [NSLayoutConstraint constraintWithItem:_verticalStackView
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:10.0],
                                        [NSLayoutConstraint constraintWithItem:_verticalStackView
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationLessThanOrEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0
                                                                      constant:-10.0],
                                        [NSLayoutConstraint constraintWithItem:_verticalStackView
                                                                     attribute:NSLayoutAttributeCenterY
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeCenterY
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_verticalStackView
                                                                     attribute:NSLayoutAttributeCenterX
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeCenterX
                                                                    multiplier:1.0
                                                                      constant:RingViewSize/2 + 5],
                                        [NSLayoutConstraint constraintWithItem:_ringView
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:10.0],
                                        [NSLayoutConstraint constraintWithItem:_ringView
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationLessThanOrEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0
                                                                      constant:-10.0],
                                        [NSLayoutConstraint constraintWithItem:_ringView
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:10.0],
                                        [NSLayoutConstraint constraintWithItem:_ringView
                                                                     attribute:NSLayoutAttributeCenterY
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeCenterY
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_ringView
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1.0
                                                                      constant:RingViewSize],
                                        [NSLayoutConstraint constraintWithItem:_ringView
                                                                     attribute:NSLayoutAttributeWidth
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1.0
                                                                      constant:RingViewSize],
                                        [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                     attribute:NSLayoutAttributeWidth
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1.0
                                                                      constant:160.0],
                                        ]];
    
    [NSLayoutConstraint activateConstraints:_constraints];
}

- (NSString *)valuePercentageString {
    if (!_numberFormatter) {
        _numberFormatter = [NSNumberFormatter new];
        _numberFormatter.numberStyle = NSNumberFormatterPercentStyle;
        _numberFormatter.maximumFractionDigits = 0;
    }
    return [_numberFormatter stringFromNumber:@(self.value)];
}

- (void)setValue:(double)value {
    _value = value;
    [self updateView];
}

- (void)setDate:(NSString *)date {
    _date = date;
    [self updateView];
}

- (void)setText:(NSString *)text {
    _text = text;
    [self updateView];
}

- (void)setTitle:(NSString *)title {
    _title = title;
    [self updateView];
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    [self updateView];
}

- (void)setGlyphType:(OCKGlyphType)glyphType {
    _glyphType = glyphType;
    [self updateView];
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    
    self.layer.shadowOffset = CGSizeMake(0, 1 / [UIScreen mainScreen].scale);
    self.layer.shadowRadius = 0;
    
    self.layer.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1].CGColor;
    self.layer.shadowOpacity = 0.25;
}


#pragma mark - Accessibility

- (BOOL)isAccessibilityElement {
    return YES;
}

- (NSString *)accessibilityLabel {
    return OCKAccessibilityStringForVariables(_titleLabel, _dateLabel);
}

@end
