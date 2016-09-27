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
#import "OCKHelpers.h"
#import "OCKDefines_Private.h"


static const CGFloat HeartButtonSize = 20.0;
static const CGFloat TopMargin = 15.0;
static const CGFloat LeadingMargin = 15.0;
static const CGFloat TrailingMargin = 15.0;

@implementation OCKCareCardWeekView {
    OCKWeekLabelsView *_weekView;
    NSMutableArray<OCKHeartButton *> *_heartButtons;
    NSMutableArray *_constraints;
    UIStackView *_stackView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];        
        [self prepareView];
    }
    return self;
}

- (void)prepareView {
    if (!_weekView) {
        _weekView = [[OCKWeekLabelsView alloc] initWithFrame:CGRectZero];
        [self addSubview:_weekView];
    }
    
    if (!_heartButtons) {
        _heartButtons = [NSMutableArray new];
        for (int i = 0; i < 7; i++) {
            OCKHeartButton *heartButton = [[OCKHeartButton alloc] initWithFrame:CGRectMake(0, 0, HeartButtonSize, HeartButtonSize)];
            
            OCKHeartView *heartView = [[OCKHeartView alloc] initWithFrame:CGRectMake(0, 0, HeartButtonSize + 10, HeartButtonSize + 10)];
            heartView.userInteractionEnabled = NO;
            heartView.maskImage = self.smallMaskImage;
            heartView.tintColor = self.tintColor;
            
            heartButton.heartView = heartView;
            [heartButton addTarget:self
                            action:@selector(updateDayOfWeek:)
                  forControlEvents:UIControlEventTouchDown];
            
            UILabel *dayLabel = (UILabel *)_weekView.weekLabels[i];
            heartButton.accessibilityLabel = [dayLabel accessibilityLabel];
            
            [_heartButtons addObject:heartButton];
        }
    }
    
    if (!_stackView) {
        _stackView = [[UIStackView alloc] initWithArrangedSubviews:_heartButtons];
        _stackView.distribution = UIStackViewDistributionEqualSpacing;
        [self addSubview:_stackView];
    }
    
    [self setUpConstraints];
}

- (void)setUpConstraints {
    [NSLayoutConstraint deactivateConstraints:_constraints];
    
    _constraints = [NSMutableArray new];
    
    _weekView.translatesAutoresizingMaskIntoConstraints = NO;
    _stackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_constraints addObjectsFromArray:@[
                                        [NSLayoutConstraint constraintWithItem:_weekView
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:-TopMargin],
                                        [NSLayoutConstraint constraintWithItem:_weekView
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:LeadingMargin],
                                        [NSLayoutConstraint constraintWithItem:_weekView
                                                                     attribute:NSLayoutAttributeTrailing
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:-TrailingMargin],
                                        [NSLayoutConstraint constraintWithItem:_stackView
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:LeadingMargin],
                                        [NSLayoutConstraint constraintWithItem:_stackView
                                                                     attribute:NSLayoutAttributeTrailing
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:-TrailingMargin],
                                        [NSLayoutConstraint constraintWithItem:_stackView
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_stackView
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0
                                                                      constant:0.0]
                                        ]];
    
    [NSLayoutConstraint activateConstraints:_constraints];
}

- (void)setValues:(NSArray<NSNumber*> *)values {
    _values = values;
    
    for (int i = 0; i < _values.count; i++) {
        double value = [_values[i] doubleValue];
        _heartButtons[i].heartView.value = value;
        
        NSString *progress = [OCKPercentFormatter(0, 0) stringFromNumber:[NSNumber numberWithDouble:value]];
        _heartButtons[i].accessibilityValue = [NSString stringWithFormat:OCKLocalizedString(@"AX_WEEK_BUTTON_PROGRESS", nil), progress];
        
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(weekViewCanSelectDayAtIndex:)]) {
            if (![self.delegate weekViewCanSelectDayAtIndex:(NSUInteger)i]) {
                _heartButtons[i].accessibilityTraits |= UIAccessibilityTraitNotEnabled;
            }
        }
    }
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    _selectedIndex = selectedIndex;
    [_weekView highlightDay:selectedIndex];
    for (int i = 0; i < [_heartButtons count]; i++) {
        UIAccessibilityTraits axTraits = UIAccessibilityTraitButton | (i == selectedIndex ?  UIAccessibilityTraitSelected : 0);
        [_heartButtons[i] setAccessibilityTraits:axTraits];
    }
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
    self.selectedIndex = dayOfWeek;
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(weekViewSelectionDidChange:)]) {
        [self.delegate weekViewSelectionDidChange:self];
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
    _weekView.tintColor = self.tintColor;
}

@end
