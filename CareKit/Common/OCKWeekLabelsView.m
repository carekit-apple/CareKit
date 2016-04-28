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


static const CGFloat TopMargin = 15.0;
static const CGFloat LeadingMargin = 6.0;
static const CGFloat TrailingMargin = 6.0;
static const NSInteger InvalidIndex = -1;

@implementation OCKWeekLabelsView {
    NSArray<NSString *> *_weekStrings;
    NSArray<NSString *> *_axWeekStrings;
    NSInteger _selectedIndex;
    UIStackView *_stackView;
    NSMutableArray *_constraints;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _selectedIndex = InvalidIndex;
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
            dayLabel.layer.cornerRadius = 3;
            dayLabel.clipsToBounds = YES;
            dayLabel.text = _weekStrings[i];
            dayLabel.textAlignment = NSTextAlignmentCenter;
            dayLabel.accessibilityLabel = _axWeekStrings[i];
            [_weekLabels addObject:dayLabel];
        }
    }
    
    if (!_stackView) {
        _stackView = [[UIStackView alloc] initWithArrangedSubviews:self.weekLabels];
        _stackView.distribution = UIStackViewDistributionEqualCentering;
        [self addSubview:_stackView];
    }
    
    [self setUpConstraints];
}

- (void)setUpConstraints {
    [NSLayoutConstraint deactivateConstraints:_constraints];
    
    _constraints = [NSMutableArray new];
    
    _stackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    for (int i = 0; i < self.weekLabels.count; i++) {
        [_constraints addObjectsFromArray:@[
                                            [NSLayoutConstraint constraintWithItem:self.weekLabels[i]
                                                                         attribute:NSLayoutAttributeWidth
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:nil
                                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                                        multiplier:1.0
                                                                          constant:18.0]
                                            ]];
    }
    
    [_constraints addObjectsFromArray:@[
                                        [NSLayoutConstraint constraintWithItem:_stackView
                                                                     attribute:NSLayoutAttributeTopMargin
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeTopMargin
                                                                    multiplier:1.0
                                                                      constant:TopMargin],
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
                                                                      constant:-TrailingMargin]
                                        ]];
    
    [NSLayoutConstraint activateConstraints:_constraints];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self setUpConstraints];
}

- (void)highlightDay:(NSInteger)selectedIndex {
    _selectedIndex = selectedIndex;
    
    for (UILabel *label in self.weekLabels) {
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor blackColor];
    }
    self.weekLabels[selectedIndex].backgroundColor = self.tintColor;
    self.weekLabels[selectedIndex].textColor = [UIColor whiteColor];
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    if (_selectedIndex != InvalidIndex) {
        [self highlightDay:_selectedIndex];
    }
}

@end
