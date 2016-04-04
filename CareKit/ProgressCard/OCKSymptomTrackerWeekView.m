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


#import "OCKSymptomTrackerWeekView.h"
#import "OCKWeekLabelsView.h"
#import "OCKRingButton.h"
#import "OCKRingView.h"
#import "OCKWeekViewController.h"
#import "OCKHelpers.h"
#import "OCKDefines_Private.h"

const static CGFloat RingButtonSize = 20.0;

@implementation OCKSymptomTrackerWeekView {
    OCKWeekLabelsView *_weekView;
    NSMutableArray<OCKRingButton *> *_ringButtons;
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
        
        NSInteger weekday = [[NSCalendar currentCalendar] component:NSCalendarUnitWeekday fromDate:[NSDate date]] - 1;
        [_weekView highlightDay:weekday];
        _selectedIndex = weekday;
    }
    
    if (!_ringButtons) {
        _ringButtons = [NSMutableArray new];
        for (int i = 0; i < 7; i++) {
            OCKRingButton *ringButton = [[OCKRingButton alloc] initWithFrame:CGRectMake(0, 0, RingButtonSize, RingButtonSize)];
            ringButton.translatesAutoresizingMaskIntoConstraints = NO;
            
            OCKRingView *ringView = [[OCKRingView alloc] initWithFrame:CGRectMake(0, 0, RingButtonSize + 10, RingButtonSize + 10)];
            ringView.userInteractionEnabled = NO;
            ringView.disableAnimation = YES;
            ringView.hideLabel = YES;
            ringButton.ringView = ringView;
            
            [ringButton addTarget:self
                           action:@selector(updateDayOfWeek:)
                 forControlEvents:UIControlEventTouchDown];
            
            UILabel *dayLabel = (UILabel *)_weekView.weekLabels[i];
            ringButton.accessibilityLabel = [dayLabel accessibilityLabel];
            
            [self addSubview:ringButton];
            [_ringButtons addObject:ringButton];
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
    
    for (int i = 0; i < _ringButtons.count; i++) {
        UILabel *dayLabel = (UILabel *)_weekView.weekLabels[i];
        [_constraints addObjectsFromArray:@[
                                            [NSLayoutConstraint constraintWithItem:dayLabel
                                                                         attribute:NSLayoutAttributeBottom
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:_ringButtons[i]
                                                                         attribute:NSLayoutAttributeTop
                                                                        multiplier:1.0
                                                                          constant:-3.0],
                                            [NSLayoutConstraint constraintWithItem:dayLabel
                                                                         attribute:NSLayoutAttributeCenterX
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:_ringButtons[i]
                                                                         attribute:NSLayoutAttributeCenterX
                                                                        multiplier:1.0
                                                                          constant:0.0]
                                            ]];
    }
    
    
    [NSLayoutConstraint activateConstraints:_constraints];
}

- (void)setValues:(NSArray<NSNumber *> *)values {
    _values = values;
    
    for (int i = 0; i < _values.count; i++) {
        CGFloat value = [_values[i] floatValue];
        _ringButtons[i].value = value;
        
        NSString *progressString = [OCKPercentFormatter(0, 0) stringFromNumber:[NSNumber numberWithFloat:value]];
        _ringButtons[i].accessibilityValue = [NSString stringWithFormat:OCKLocalizedString(@"AX_WEEK_BUTTON_PROGRESS", nil), progressString];
        
        if (_delegate &&
            [_delegate respondsToSelector:@selector(weekViewCanSelectDayAtIndex:)]) {
            if (![_delegate weekViewCanSelectDayAtIndex:(NSUInteger)i]) {
                _ringButtons[i].accessibilityTraits |= UIAccessibilityTraitNotEnabled;
            }
        }
    }
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    _selectedIndex = selectedIndex;
    [_weekView highlightDay:selectedIndex];
    
    for ( int i = 0; i < [_ringButtons count]; i++ ) {
        UIAccessibilityTraits axTraits = UIAccessibilityTraitButton | (i == selectedIndex ?  UIAccessibilityTraitSelected : 0);
        [_ringButtons[i] setAccessibilityTraits:axTraits];
    }
    
}

- (void)updateDayOfWeek:(id)sender {
    OCKRingButton *button = (OCKRingButton *)sender;
    NSInteger index = [_ringButtons indexOfObject:button];
    _selectedIndex = index;
    
    if (_delegate &&
        [_delegate respondsToSelector:@selector(weekViewSelectionDidChange:)]) {
        [_delegate weekViewSelectionDidChange:self];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self setUpConstraints];
}

@end
