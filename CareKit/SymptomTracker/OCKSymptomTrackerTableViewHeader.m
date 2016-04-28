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


#import "OCKSymptomTrackerTableViewHeader.h"
#import "OCKRingView.h"
#import "OCKHelpers.h"
#import "OCKDefines_Private.h"
#import "OCKLabel.h"


static const CGFloat TopMargin = 50.0;
static const CGFloat BottomMargin = 50.0;
static const CGFloat HorizontalMargin = 10.0;
static const CGFloat TrailingMargin = 20.0;
static const CGFloat RingViewSize = 110.0;

@implementation OCKSymptomTrackerTableViewHeader {
    OCKLabel *_titleLabel;
    OCKLabel *_dateLabel;
    UIView *_topEdge;
    UIView *_bottomEdge;
    NSMutableArray *_constraints;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        if (!UIAccessibilityIsReduceTransparencyEnabled()) {
            self.backgroundColor = [UIColor clearColor];
            
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
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
        _ringView = [[OCKRingView alloc] initWithFrame:CGRectMake(0, 0, RingViewSize, RingViewSize)];
        [self addSubview:_ringView];
    }
    
    if (!_titleLabel) {
        _titleLabel = [OCKLabel new];
        _titleLabel.textStyle = UIFontTextStyleHeadline;
        _titleLabel.text = OCKLocalizedString(@"SYMPTOM_TRACKER_HEADER_TITLE", nil);
        _titleLabel.numberOfLines = 2;
        [self addSubview:_titleLabel];
    }
    
    if (!_dateLabel) {
        _dateLabel = [OCKLabel new];
        _dateLabel.textStyle = UIFontTextStyleSubheadline;
        _dateLabel.textColor = [UIColor darkGrayColor];
        _dateLabel.numberOfLines = 2;
        [self addSubview:_dateLabel];
    }
    
    if (!_topEdge) {
        _topEdge = [UIView new];
        _topEdge.backgroundColor = [UIColor groupTableViewBackgroundColor];
        [self addSubview:_topEdge];
    }
    
    if (!_bottomEdge) {
        _bottomEdge = [UILabel new];
        _bottomEdge.backgroundColor = [UIColor groupTableViewBackgroundColor];
        [self addSubview:_bottomEdge];
    }
    
    [self updateView];
    [self setUpConstraints];
}

- (void)updateView {
    self.ringView.tintColor = self.tintColor;
    self.ringView.value = self.value;
    _dateLabel.text = self.date;
}

- (void)setUpConstraints {
    [NSLayoutConstraint deactivateConstraints:_constraints];
    
    _constraints = [NSMutableArray new];
    
    self.ringView.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _topEdge.translatesAutoresizingMaskIntoConstraints = NO;
    _bottomEdge.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_constraints addObjectsFromArray:@[
                                        [NSLayoutConstraint constraintWithItem:self.ringView
                                                                     attribute:NSLayoutAttributeCenterX
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeCenterX
                                                                    multiplier:1.0
                                                                      constant:-RingViewSize/1.25],
                                        [NSLayoutConstraint constraintWithItem:self.ringView
                                                                     attribute:NSLayoutAttributeCenterY
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeCenterY
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:self.ringView
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1.0
                                                                      constant:RingViewSize],
                                        [NSLayoutConstraint constraintWithItem:self.ringView
                                                                     attribute:NSLayoutAttributeWidth
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1.0
                                                                      constant:RingViewSize],
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
                                                                        toItem:self.ringView
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:HorizontalMargin],
                                        [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                     attribute:NSLayoutAttributeTrailing
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:-TrailingMargin],
                                        [NSLayoutConstraint constraintWithItem:_dateLabel
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_titleLabel
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_dateLabel
                                                                     attribute:NSLayoutAttributeTrailing
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:-TrailingMargin],
                                        [NSLayoutConstraint constraintWithItem:_dateLabel
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0
                                                                      constant:-BottomMargin],
                                        [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_dateLabel
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_bottomEdge
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_bottomEdge
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1.0
                                                                      constant:1.0],
                                        [NSLayoutConstraint constraintWithItem:_bottomEdge
                                                                     attribute:NSLayoutAttributeWidth
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeWidth
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_topEdge
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_topEdge
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1.0
                                                                      constant:1.0],
                                        [NSLayoutConstraint constraintWithItem:_topEdge
                                                                     attribute:NSLayoutAttributeWidth
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeWidth
                                                                    multiplier:1.0
                                                                      constant:0.0]
                                        ]];
    
    [NSLayoutConstraint activateConstraints:_constraints];
}

- (void)setValue:(double)value {
    _value = value;
    [self updateView];
}

- (void)setDate:(NSString *)date {
    _date = date;
    [self updateView];
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
    return OCKAccessibilityStringForVariables(self.ringView, _titleLabel, _dateLabel);
}

@end
