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


#import "OCKPatientHeaderView.h"
#import "OCKLabel.h"
#import "OCKHelpers.h"


static const CGFloat VerticalMargin = 10.0;
static const CGFloat HorizontalMargin = 10.0;
static const CGFloat TopMargin = 12.5;
static const CGFloat BottomMargin = 12.5;
static const CGFloat ImageViewSize = 125.0;

@implementation OCKPatientHeaderView {
    UIImageView *_imageView;
    OCKLabel *_monogramLabel;
    OCKLabel *_nameLabel;
    OCKLabel *_detailLabel;
    UIView *_bottomEdge;
    NSMutableArray *_constraints;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _showSeparator = YES;
        
        if (!UIAccessibilityIsReduceTransparencyEnabled()) {
            self.contentView.backgroundColor = [UIColor clearColor];
            
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
            UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            blurEffectView.frame = self.bounds;
            blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            self.backgroundView = blurEffectView;
        } else {
            self.contentView.backgroundColor = [UIColor whiteColor];
        }
        
        [self prepareView];
    }
    return self;
}

- (void)setPatient:(OCKPatient *)patient {
    _patient = patient;
    self.tintColor = _patient.tintColor;
    [self updateView];
}

- (void)setShowSeparator:(BOOL)showSeparator {
    _showSeparator = showSeparator;
    _bottomEdge.hidden = !_showSeparator;
}

- (void)prepareView {
    if (!_imageView) {
        _imageView = [UIImageView new];
        _imageView.layer.cornerRadius = ImageViewSize/2;
        _imageView.clipsToBounds = YES;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:_imageView];
    }

    if (!_monogramLabel) {
        _monogramLabel = [OCKLabel new];
        _monogramLabel.textColor = [UIColor whiteColor];
        _monogramLabel.textAlignment = NSTextAlignmentCenter;
        _monogramLabel.font = [UIFont boldSystemFontOfSize:20.0];
        _monogramLabel.adjustsFontSizeToFitWidth = YES;
        [self addSubview:_monogramLabel];
    }
    
    if (!_nameLabel) {
        _nameLabel = [OCKLabel new];
        _nameLabel.textStyle = UIFontTextStyleHeadline;
        [self addSubview:_nameLabel];
    }
    
    if (!_detailLabel) {
        _detailLabel = [OCKLabel new];
        _detailLabel.textStyle = UIFontTextStyleSubheadline;
        [self addSubview:_detailLabel];
    }
    
    if (!_bottomEdge) {
        _bottomEdge = [UIView new];
        _bottomEdge.backgroundColor = [UIColor groupTableViewBackgroundColor];
        [self addSubview:_bottomEdge];
    }
    
    [self setUpConstraints];
}

- (void)updateView {
    if (self.patient.image) {
        _imageView.image = self.patient.image;
        _monogramLabel.text = nil;
    } else {
        _imageView.image = nil;
        _monogramLabel.text = self.patient.monogram;
    }
    
    [self updateImageViewBackgroundColor];
    
    _nameLabel.text = self.patient.name;
    _detailLabel.text = self.patient.detailInfo;
}

- (void)setUpConstraints {
    [NSLayoutConstraint deactivateConstraints:_constraints];
    _constraints = [NSMutableArray new];
    
    _imageView.translatesAutoresizingMaskIntoConstraints = NO;
    _monogramLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _detailLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _bottomEdge.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_constraints addObjectsFromArray:@[
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
                                                                        toItem:_nameLabel
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:-VerticalMargin],
                                        [NSLayoutConstraint constraintWithItem:_detailLabel
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_nameLabel
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:self
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                        toItem:_detailLabel
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0
                                                                      constant:BottomMargin],
                                        [NSLayoutConstraint constraintWithItem:_nameLabel
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:self
                                                                     attribute:NSLayoutAttributeTrailing
                                                                     relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                        toItem:_nameLabel
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_nameLabel
                                                                     attribute:NSLayoutAttributeCenterX
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeCenterX
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_detailLabel
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:self
                                                                     attribute:NSLayoutAttributeTrailing
                                                                     relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                        toItem:_detailLabel
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_detailLabel
                                                                     attribute:NSLayoutAttributeCenterX
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeCenterX
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_imageView
                                                                     attribute:NSLayoutAttributeCenterX
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeCenterX
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_imageView
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:self
                                                                     attribute:NSLayoutAttributeTrailing
                                                                     relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                        toItem:_imageView
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:0.0],
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
                                                                      constant:-HorizontalMargin],
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
                                                                      constant:0.0]
                                        ]];
    
    [NSLayoutConstraint activateConstraints:_constraints];
}

- (void)updateImageViewBackgroundColor {
    _imageView.backgroundColor = self.patient.image ? [UIColor clearColor] : OCKSystemGrayColor();
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    [self updateView];
}

@end
