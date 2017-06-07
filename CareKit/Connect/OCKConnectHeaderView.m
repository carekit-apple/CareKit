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


#import "OCKConnectHeaderView.h"
#import "OCKHelpers.h"
#import "OCKLabel.h"


static const CGFloat TopMargin = 15.0;
static const CGFloat BottomMargin = 15.0;
static const CGFloat LeadingMargin = 20.0;
static const CGFloat TrailingMargin = 20.0;
static const CGFloat VerticalMargin = 10.0;
static const CGFloat HorizontalMargin = 10.0;
static const CGFloat ImageViewSize = 75.0;

@implementation OCKConnectHeaderView {
    UIImageView *_imageView;
    OCKLabel *_monogramLabel;
    OCKLabel *_titleLabel;
    OCKLabel *_detailLabel;
    UIButton *_disclosureIndicator;

    NSMutableArray *_constraints;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _hideChevron = YES;

        [self prepareView];
    }
    return self;
}

- (void)prepareView {
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
    
    if (!_disclosureIndicator) {
        _disclosureIndicator = [UIButton new];
        
        UITableViewCell *disclosure = [UITableViewCell new];
        disclosure.frame = _disclosureIndicator.bounds;
        disclosure.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        disclosure.userInteractionEnabled = NO;
        [_disclosureIndicator addSubview:disclosure];
        _disclosureIndicator.hidden = _hideChevron;
        [self addSubview:_disclosureIndicator];
    }
    
    if (!_imageView) {
        _imageView = [UIImageView new];
        _imageView.layer.cornerRadius = 38.0;
        _imageView.clipsToBounds = YES;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:_imageView];
    }
    
    if (!_titleLabel) {
        _titleLabel = [OCKLabel new];
        _titleLabel.textStyle = UIFontTextStyleHeadline;
        _titleLabel.numberOfLines = 0;
        _titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_titleLabel];
    }
    
    if (!_detailLabel) {
        _detailLabel = [OCKLabel new];
        _detailLabel.textStyle = UIFontTextStyleSubheadline;
        _detailLabel.textColor = [UIColor lightGrayColor];
        _detailLabel.numberOfLines = 0;
        _detailLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _detailLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_detailLabel];
    }
    
    if (!_monogramLabel) {
        _monogramLabel = [OCKLabel new];
        _monogramLabel.textColor = [UIColor whiteColor];
        _monogramLabel.textAlignment = NSTextAlignmentCenter;
        _monogramLabel.font = [UIFont boldSystemFontOfSize:40.0];
        _monogramLabel.adjustsFontSizeToFitWidth = YES;
        [self addSubview:_monogramLabel];
    }
    
    [self updateView];
    [self setUpConstraints];
}

- (void)updateView {
    if (self.patient.image) {
        _imageView.image = self.patient.image;
        _imageView.backgroundColor = [UIColor clearColor];
        _monogramLabel.hidden = YES;
    } else {
        _monogramLabel.text = self.patient.monogram;
        _imageView.backgroundColor = [UIColor grayColor];
        _monogramLabel.hidden = NO;
    }
    
    _detailLabel.text = self.patient.detailInfo;
    _titleLabel.text = self.patient.name;
    _disclosureIndicator.hidden = self.hideChevron;
}

- (void)setUpConstraints {
    [NSLayoutConstraint deactivateConstraints:_constraints];
    
    _constraints = [NSMutableArray new];
    
    _imageView.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _detailLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _monogramLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _disclosureIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_constraints addObjectsFromArray:@[
                                        [NSLayoutConstraint constraintWithItem:_imageView
                                                                     attribute:NSLayoutAttributeCenterX
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeCenterX
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_imageView
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:TopMargin],
                                        [NSLayoutConstraint constraintWithItem:_imageView
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_titleLabel
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:-VerticalMargin],
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
                                        [NSLayoutConstraint constraintWithItem:_titleLabel
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
                                        [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_detailLabel
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_detailLabel
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:LeadingMargin],
                                        [NSLayoutConstraint constraintWithItem:_detailLabel
                                                                     attribute:NSLayoutAttributeTrailing
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:-TrailingMargin],
                                        [NSLayoutConstraint constraintWithItem:_detailLabel
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0
                                                                      constant:-BottomMargin],
                                        [NSLayoutConstraint constraintWithItem:_monogramLabel
                                                                     attribute:NSLayoutAttributeCenterX
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_imageView
                                                                     attribute:NSLayoutAttributeCenterX
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_monogramLabel
                                                                     attribute:NSLayoutAttributeCenterY
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_imageView
                                                                     attribute:NSLayoutAttributeCenterY
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_monogramLabel
                                                                     attribute:NSLayoutAttributeWidth
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_imageView
                                                                     attribute:NSLayoutAttributeWidth
                                                                    multiplier:1.0
                                                                      constant:-HorizontalMargin],[NSLayoutConstraint constraintWithItem:_disclosureIndicator
                                                                                                                               attribute:NSLayoutAttributeCenterY
                                                                                                                               relatedBy:NSLayoutRelationEqual
                                                                                                                                  toItem:self
                                                                                                                               attribute:NSLayoutAttributeCenterY
                                                                                                                              multiplier:1.0
                                                                                                                                constant:10.0],
                                        [NSLayoutConstraint constraintWithItem:_disclosureIndicator
                                                                     attribute:NSLayoutAttributeTrailing
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:25.0]]];
    
    [NSLayoutConstraint activateConstraints:_constraints];
}

- (void)setPatient:(OCKPatient *)patient {
    _patient = patient;
    [self updateView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _titleLabel.preferredMaxLayoutWidth = _titleLabel.bounds.size.width;
    _detailLabel.preferredMaxLayoutWidth = _detailLabel.bounds.size.width;
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    [self updateView];
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    
    self.layer.shadowOffset = CGSizeMake(0, 1 / [UIScreen mainScreen].scale);
    self.layer.shadowRadius = 0;
    
    self.layer.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1].CGColor;
    self.layer.shadowOpacity = 0.25;
}

@end
