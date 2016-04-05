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


#import "OCKWeekLabelsView.h"


const static CGFloat TopMargin = 12.0;

@implementation OCKWeekLabelsView {
    NSMutableArray<UILabel *> *_weekLabels;
    NSMutableArray *_constraints;
    NSArray<NSString *> *_weekStrings;
    NSArray<NSString *> *_axWeekStrings;
    NSInteger _selectedIndex;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self prepareView];
    }
    return self;
}

- (void)prepareView {
    if (!_weekStrings) {
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        _weekStrings = dateFormatter.veryShortWeekdaySymbols;
        _axWeekStrings = dateFormatter.weekdaySymbols;
    }
    
    if (!_weekLabels) {
        _weekLabels = [NSMutableArray new];
        for (int i = 0; i < 7; i++) {
            UILabel *dayLabel = [UILabel new];
            dayLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightThin];
            dayLabel.translatesAutoresizingMaskIntoConstraints = NO;
            dayLabel.layer.cornerRadius = 3;
            dayLabel.clipsToBounds = YES;
            dayLabel.text = _weekStrings[i];
            dayLabel.accessibilityLabel = _axWeekStrings[i];
            dayLabel.textAlignment = NSTextAlignmentCenter;
            
            [self addSubview:dayLabel];
            [_weekLabels addObject:dayLabel];
        }
    }
    
    [self setUpConstraints];
}

- (void)setUpConstraints {
    [NSLayoutConstraint deactivateConstraints:_constraints];
    
    _constraints = [NSMutableArray new];
    
    const CGFloat HorizontalMargin = self.bounds.size.width/9;
    
    for (int i = 0; i < _weekLabels.count; i++) {
        if (i == 0) {
            [_constraints addObject:[NSLayoutConstraint constraintWithItem:_weekLabels[i]
                                                                 attribute:NSLayoutAttributeWidth
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:_weekLabels[i+1]
                                                                 attribute:NSLayoutAttributeWidth
                                                                multiplier:1.0
                                                                  constant:0.0]];
        } else {
            [_constraints addObject:[NSLayoutConstraint constraintWithItem:_weekLabels[i]
                                                                 attribute:NSLayoutAttributeWidth
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:_weekLabels[i-1]
                                                                 attribute:NSLayoutAttributeWidth
                                                                multiplier:1.0
                                                                  constant:0.0]];
        }
        
        [_constraints addObjectsFromArray:@[[NSLayoutConstraint constraintWithItem:_weekLabels[i]
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self
                                                                         attribute:NSLayoutAttributeTop
                                                                        multiplier:1.0
                                                                          constant:TopMargin]
                                            ]];
    }
    
    {
        [_constraints addObjectsFromArray:@[
                                            // Monday
                                            [NSLayoutConstraint constraintWithItem:_weekLabels[0]
                                                                         attribute:NSLayoutAttributeTrailing
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:_weekLabels[1]
                                                                         attribute:NSLayoutAttributeLeading
                                                                        multiplier:1.0
                                                                          constant:-HorizontalMargin],
                                            // Tuesday
                                            [NSLayoutConstraint constraintWithItem:_weekLabels[1]
                                                                         attribute:NSLayoutAttributeTrailing
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:_weekLabels[2]
                                                                         attribute:NSLayoutAttributeLeading
                                                                        multiplier:1.0
                                                                          constant:-HorizontalMargin],
                                            // Wednesday
                                            [NSLayoutConstraint constraintWithItem:_weekLabels[2]
                                                                         attribute:NSLayoutAttributeTrailing
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:_weekLabels[3]
                                                                         attribute:NSLayoutAttributeLeading
                                                                        multiplier:1.0
                                                                          constant:-HorizontalMargin],
                                            // Thursday (Centered on screen, anchor point).
                                            [NSLayoutConstraint constraintWithItem:_weekLabels[3]
                                                                         attribute:NSLayoutAttributeCenterX
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self
                                                                         attribute:NSLayoutAttributeCenterX
                                                                        multiplier:1.0
                                                                          constant:0.0],
                                            // Friday
                                            [NSLayoutConstraint constraintWithItem:_weekLabels[3]
                                                                         attribute:NSLayoutAttributeTrailing
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:_weekLabels[4]
                                                                         attribute:NSLayoutAttributeLeading
                                                                        multiplier:1.0
                                                                          constant:-HorizontalMargin],
                                            // Saturday
                                            [NSLayoutConstraint constraintWithItem:_weekLabels[4]
                                                                         attribute:NSLayoutAttributeTrailing
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:_weekLabels[5]
                                                                         attribute:NSLayoutAttributeLeading
                                                                        multiplier:1.0
                                                                          constant:-HorizontalMargin],
                                            // Sunday
                                            [NSLayoutConstraint constraintWithItem:_weekLabels[5]
                                                                         attribute:NSLayoutAttributeTrailing
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:_weekLabels[6]
                                                                         attribute:NSLayoutAttributeLeading
                                                                        multiplier:1.0
                                                                          constant:-HorizontalMargin]
                                            ]];
    }
    
    [NSLayoutConstraint activateConstraints:_constraints];
}

- (void)highlightDay:(NSInteger)selectedIndex {
    _selectedIndex = selectedIndex;
    
    for (UILabel *label in _weekLabels) {
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor blackColor];
    }
    _weekLabels[selectedIndex].backgroundColor = self.tintColor;
    _weekLabels[selectedIndex].textColor = [UIColor whiteColor];
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    [self highlightDay:_selectedIndex];
}

@end
