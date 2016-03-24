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


#import "OCKCareCardWeekView.h"
#import "OCKWeekLabelsView.h"
#import "OCKHeartView.h"
#import "OCKHeartButton.h"
#import "OCKWeekViewController.h"


const static CGFloat HeartButtonSize = 20.0;

@implementation OCKCareCardWeekView {
    OCKWeekLabelsView *_weekView;
    NSMutableArray<OCKHeartButton *> *_heartButtons;
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
        } else {
            self.backgroundColor = [UIColor whiteColor];
        }
    
        [self prepareView];
    }
    return self;
}

- (void)prepareView {
    if (!_weekView) {
        _weekView = [[OCKWeekLabelsView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 25.0)];
        [self addSubview:_weekView];
    }
    
    if (!_heartButtons) {
        _heartButtons = [NSMutableArray new];
        for (int i = 0; i < 7; i++) {
            OCKHeartButton *heartButton = [[OCKHeartButton alloc] initWithFrame:CGRectMake(0, 0, HeartButtonSize, HeartButtonSize)];
            heartButton.translatesAutoresizingMaskIntoConstraints = NO;
            
            OCKHeartView *heartView = [[OCKHeartView alloc] initWithFrame:CGRectMake(0, 0, HeartButtonSize + 10, HeartButtonSize + 10)];
            heartView.translatesAutoresizingMaskIntoConstraints = NO;
            heartView.userInteractionEnabled = NO;
            heartView.maskImage = _smallMaskImage;
            heartView.tintColor = self.tintColor;
            heartButton.heartView = heartView;
            
            [heartButton addTarget:self
                            action:@selector(updateDayOfWeek:)
                  forControlEvents:UIControlEventTouchDown];
            
            [self addSubview:heartButton];
            [_heartButtons addObject:heartButton];
        }
    }
    
    [self setUpConstraints];
}

- (void)setUpConstraints {
    [NSLayoutConstraint deactivateConstraints:_constraints];
    
    _constraints = [NSMutableArray new];
    
    _weekView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_constraints addObjectsFromArray:@[
                                        [NSLayoutConstraint constraintWithItem:_weekView
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:-5.0],
                                        [NSLayoutConstraint constraintWithItem:_weekView
                                                                     attribute:NSLayoutAttributeCenterX
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeCenterX
                                                                    multiplier:1.0
                                                                      constant:0.0]
                                        ]];
    
    for (int i = 0; i < _heartButtons.count; i++) {
        UILabel *dayLabel = (UILabel *)_weekView.weekLabels[i];
        [_constraints addObjectsFromArray:@[
                                            [NSLayoutConstraint constraintWithItem:dayLabel
                                                                         attribute:NSLayoutAttributeBottom
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:_heartButtons[i]
                                                                         attribute:NSLayoutAttributeTop
                                                                        multiplier:1.0
                                                                          constant:-3.0],
                                            [NSLayoutConstraint constraintWithItem:dayLabel
                                                                         attribute:NSLayoutAttributeCenterX
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:_heartButtons[i]
                                                                         attribute:NSLayoutAttributeCenterX
                                                                        multiplier:1.0
                                                                          constant:0.0],
                                            [NSLayoutConstraint constraintWithItem:_heartButtons[i]
                                                                         attribute:NSLayoutAttributeWidth
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:nil
                                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                                        multiplier:1.0
                                                                          constant:HeartButtonSize + 10],
                                            [NSLayoutConstraint constraintWithItem:_heartButtons[i]
                                                                         attribute:NSLayoutAttributeHeight
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:nil
                                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                                        multiplier:1.0
                                                                          constant:HeartButtonSize + 10]
                                            ]];
    }
    
    [NSLayoutConstraint activateConstraints:_constraints];
}

- (void)setValues:(NSArray<NSNumber*> *)values {
    _values = values;
    
    for (int i = 0; i < _values.count; i++) {
        double value = [_values[i] doubleValue];
        _heartButtons[i].heartView.value = value;
    }
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    _selectedIndex = selectedIndex;
    [_weekView highlightDay:selectedIndex];
}

- (void)setSmallMaskImage:(UIImage *)smallMaskImage {
    _smallMaskImage = smallMaskImage;
    for (OCKHeartButton *button in _heartButtons) {
        button.heartView.maskImage = _smallMaskImage;
    }
    [self prepareView];
}

- (void)updateDayOfWeek:(id)sender {
    OCKHeartButton *button = (OCKHeartButton *)sender;
    NSInteger dayOfWeek = [_heartButtons indexOfObject:button];
    _selectedIndex = dayOfWeek;
    
    if (_delegate &&
        [_delegate respondsToSelector:@selector(weekViewSelectionDidChange:)]) {
        [_delegate weekViewSelectionDidChange:self];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self setUpConstraints];
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    for (OCKHeartButton *button in _heartButtons) {
        button.heartView.tintColor = self.tintColor;
    }
}

@end
