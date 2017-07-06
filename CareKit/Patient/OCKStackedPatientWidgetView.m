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


#import "OCKStackedPatientWidgetView.h"
#import "OCKPatientWidget_Internal.h"


@implementation OCKStackedPatientWidgetView {
    UIImageView *_primaryIconImageView;
    UILabel *_primaryTextLabel;
    UIImageView *_secondaryIconImageView;
    UILabel *_secondaryTextLabel;
    UIStackView *_verticalStackView;
    UIStackView *_primaryHorizontalStackView;
    UIStackView *_secondaryHorizontalStackView;
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
    if (!_primaryIconImageView) {
        _primaryIconImageView = [UIImageView new];
        _primaryIconImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    
    if (!_primaryTextLabel) {
        _primaryTextLabel = [UILabel new];
        _primaryTextLabel.numberOfLines = 1;
        _primaryTextLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _primaryTextLabel.font = [UIFont systemFontOfSize:14.0];
    }
    
    if (!_primaryHorizontalStackView) {
        _primaryHorizontalStackView = [[UIStackView alloc] initWithArrangedSubviews:@[_primaryIconImageView, _primaryTextLabel]];
        _primaryHorizontalStackView.distribution = UIStackViewDistributionFillProportionally;
        _primaryHorizontalStackView.alignment = UIStackViewAlignmentCenter;
        _primaryHorizontalStackView.spacing = 10.0;
    }
    
    if (!_secondaryIconImageView) {
        _secondaryIconImageView = [UIImageView new];
        _secondaryIconImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    
    if (!_secondaryTextLabel) {
        _secondaryTextLabel = [UILabel new];
        _secondaryTextLabel.numberOfLines = 1;
        _secondaryTextLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _secondaryTextLabel.font = [UIFont systemFontOfSize:14.0];
    }
    
    if (!_secondaryHorizontalStackView) {
        _secondaryHorizontalStackView = [[UIStackView alloc] initWithArrangedSubviews:@[_secondaryIconImageView, _secondaryTextLabel]];
        _secondaryHorizontalStackView.distribution = UIStackViewDistributionFillProportionally;
        _secondaryHorizontalStackView.alignment = UIStackViewAlignmentCenter;
        _secondaryHorizontalStackView.spacing = 10.0;
    }
    
    if (!_verticalStackView) {
        _verticalStackView = [[UIStackView alloc] initWithArrangedSubviews:@[_primaryHorizontalStackView, _secondaryHorizontalStackView]];
        _verticalStackView.axis = UILayoutConstraintAxisVertical;
        _verticalStackView.distribution = UIStackViewDistributionFillEqually;
        _verticalStackView.alignment = UIStackViewAlignmentLeading;
        _verticalStackView.spacing = 2.0;
        [self addSubview:_verticalStackView];
    }
    
    [self updateView];
    [self setUpConstraints];
}

- (void)updateView {
    
    if (self.animate) {
        CATransition *animation = [CATransition animation];
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        animation.type = kCATransitionFade;
        animation.duration = 0.75;
        [_primaryIconImageView.layer addAnimation:animation forKey:@"kCATransitionFade"];
        [_secondaryIconImageView.layer addAnimation:animation forKey:@"kCATransitionFade"];
        [_primaryTextLabel.layer addAnimation:animation forKey:@"kCATransitionFade"];
        [_secondaryTextLabel.layer addAnimation:animation forKey:@"kCATransitionFade"];
    }
    
    _primaryIconImageView.image = self.widget.primaryImage;
    _secondaryIconImageView.image = self.widget.secondaryImage;
    _primaryTextLabel.text = self.widget.primaryText;
    _secondaryTextLabel.text = self.widget.secondaryText;
    
    _primaryTextLabel.textColor = self.shouldApplyTintColor ? self.widget.tintColor : [UIColor blackColor];
    _secondaryTextLabel.textColor = self.shouldApplyTintColor ? self.widget.tintColor : [UIColor blackColor];
}

- (void)setUpConstraints {
    [NSLayoutConstraint deactivateConstraints:_constraints];
    
    _constraints = [NSMutableArray new];
    
    _verticalStackView.translatesAutoresizingMaskIntoConstraints = NO;
    _primaryIconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    _secondaryIconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_constraints addObjectsFromArray:@[
                                        [NSLayoutConstraint constraintWithItem:_verticalStackView
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_verticalStackView
                                                                     attribute:NSLayoutAttributeTrailing
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_verticalStackView
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_verticalStackView
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_primaryIconImageView
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1.0
                                                                      constant:10.0],
                                        [NSLayoutConstraint constraintWithItem:_primaryIconImageView
                                                                     attribute:NSLayoutAttributeWidth
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1.0
                                                                      constant:10.0],
                                        [NSLayoutConstraint constraintWithItem:_secondaryIconImageView
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1.0
                                                                      constant:10.0],
                                        [NSLayoutConstraint constraintWithItem:_secondaryIconImageView
                                                                     attribute:NSLayoutAttributeWidth
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1.0
                                                                      constant:10.0],
                                        
                                        ]];
    
    [NSLayoutConstraint activateConstraints:_constraints];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self setUpConstraints];
}

@end
