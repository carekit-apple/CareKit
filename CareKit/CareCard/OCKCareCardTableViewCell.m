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


#import "OCKCareCardTableViewCell.h"
#import "OCKCarePlanActivity.h"
#import "OCKCarePlanActivity_Internal.h"
#import "OCKCarePlanEvent.h"
#import "OCKCareCardButton.h"
#import "OCKHelpers.h"
#import "OCKDefines_Private.h"
#import "OCKLabel.h"


static const CGFloat TopMargin = 20.0;
static const CGFloat BottomMargin = 10.0;
static const CGFloat VerticalMargin = 5.0;
static const CGFloat HorizontalMargin = 5.0;
static const CGFloat ButtonViewSize = 40.0;

@interface OCKCareCardTableViewCell ()

@property (nonatomic, retain) NSMutableArray *axChildren;

@end


@implementation OCKCareCardTableViewCell {
    OCKLabel *_titleLabel;
    OCKLabel *_textLabel;
    UIView *_leadingEdge;
    NSArray <OCKCareCardButton *> *_frequencyButtons;
    OCKCarePlanActivity *_intervention;
    NSMutableArray *_constraints;
}

- (void)setInterventionEvents:(NSArray<OCKCarePlanEvent *> *)interventionEvents {
    if (interventionEvents.count > 14) {
        @throw [NSException exceptionWithName:NSGenericException reason:@"OCKCareCardViewController only supports up to 14 events for an intervention activity." userInfo:nil];
    }
    _interventionEvents = OCKArrayCopyObjects(interventionEvents);
    _intervention = _interventionEvents.firstObject.activity;
    self.tintColor = _intervention.tintColor;
    [self prepareView];
}

- (void)prepareView {
    [super prepareView];
    
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if (!_titleLabel) {
        _titleLabel = [OCKLabel new];
        _titleLabel.textStyle = UIFontTextStyleHeadline;
        [self addSubview:_titleLabel];
    }
    
    if (!_textLabel) {
        _textLabel = [OCKLabel new];
        _textLabel.textColor = [UIColor lightGrayColor];
        _textLabel.textStyle = UIFontTextStyleSubheadline;
        [self addSubview:_textLabel];
    }
    
    for (OCKCareCardButton *button in _frequencyButtons) {
        [button removeFromSuperview];
    }
    
    _frequencyButtons = [NSArray new];
    NSMutableArray *buttons = [NSMutableArray new];
    for (OCKCarePlanEvent *event in self.interventionEvents) {
        OCKCareCardButton *frequencyButton = [[OCKCareCardButton alloc] initWithFrame:CGRectZero];
        frequencyButton.tintColor = self.tintColor;
        frequencyButton.selected = (event.state == OCKCarePlanEventStateCompleted);
        frequencyButton.translatesAutoresizingMaskIntoConstraints = NO;
        
        [frequencyButton addTarget:self
                            action:@selector(toggleFrequencyButton:)
                  forControlEvents:UIControlEventTouchUpInside];
        [buttons addObject:frequencyButton];
        
        [self addSubview:frequencyButton];
    }
    _frequencyButtons = [buttons copy];
    
    [self updateView];
    [self setUpConstraints];
    [self updateAccessibilityInfo];
}

- (void)updateView {
    _titleLabel.text = _intervention.title;
    _textLabel.text = _intervention.text;
}

- (void)setUpConstraints {
    [NSLayoutConstraint deactivateConstraints:_constraints];
    
    _constraints = [NSMutableArray new];
    
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_titleLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    
    CGFloat LeadingMargin = self.separatorInset.left;
    CGFloat TrailingMargin = (self.separatorInset.right > 0) ? self.separatorInset.right : 25;
    
    [_constraints addObjectsFromArray:@[
                                        [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:TopMargin],
                                        [NSLayoutConstraint constraintWithItem:_textLabel
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:TopMargin],
                                        [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:LeadingMargin],
                                        [NSLayoutConstraint constraintWithItem:_textLabel
                                                                     attribute:NSLayoutAttributeBaseline
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_titleLabel
                                                                     attribute:NSLayoutAttributeBaseline
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_textLabel
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_titleLabel
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:HorizontalMargin],
                                        [NSLayoutConstraint constraintWithItem:self
                                                                     attribute:NSLayoutAttributeTrailing
                                                                     relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                        toItem:_textLabel
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:TrailingMargin]
                                        ]];
    
    for (int i = 0; i < _frequencyButtons.count; i++) {
        if (i == 0) {
            [_constraints addObjectsFromArray:@[
                                                [NSLayoutConstraint constraintWithItem:_frequencyButtons[i]
                                                                             attribute:NSLayoutAttributeLeading
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:self
                                                                             attribute:NSLayoutAttributeLeading
                                                                            multiplier:1.0
                                                                              constant:LeadingMargin],
                                                [NSLayoutConstraint constraintWithItem:_frequencyButtons[i]
                                                                             attribute:NSLayoutAttributeTop
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:_titleLabel
                                                                             attribute:NSLayoutAttributeBottom
                                                                            multiplier:1.0
                                                                              constant:VerticalMargin],
                                                ]];
        } else if (i == 7) {
            [_constraints addObjectsFromArray:@[
                                                [NSLayoutConstraint constraintWithItem:_frequencyButtons[i]
                                                                             attribute:NSLayoutAttributeLeading
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:self
                                                                             attribute:NSLayoutAttributeLeading
                                                                            multiplier:1.0
                                                                              constant:LeadingMargin],
                                                [NSLayoutConstraint constraintWithItem:_frequencyButtons[i]
                                                                             attribute:NSLayoutAttributeTop
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:_frequencyButtons[0]
                                                                             attribute:NSLayoutAttributeBottom
                                                                            multiplier:1.0
                                                                              constant:0.0]
                                                ]];
        } else {
            [_constraints addObjectsFromArray:@[
                                                [NSLayoutConstraint constraintWithItem:_frequencyButtons[i]
                                                                             attribute:NSLayoutAttributeLeading
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:_frequencyButtons[i-1]
                                                                             attribute:NSLayoutAttributeTrailing
                                                                            multiplier:1.0
                                                                              constant:0.0],
                                                [NSLayoutConstraint constraintWithItem:_frequencyButtons[i]
                                                                             attribute:NSLayoutAttributeTop
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:_frequencyButtons[i-1]
                                                                             attribute:NSLayoutAttributeTop
                                                                            multiplier:1.0
                                                                              constant:0.0]
                                                ]];
        }
        
        [_constraints addObjectsFromArray:@[
                                            [NSLayoutConstraint constraintWithItem:_frequencyButtons[i]
                                                                         attribute:NSLayoutAttributeWidth
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:nil
                                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                                        multiplier:1.0
                                                                          constant:ButtonViewSize],
                                            [NSLayoutConstraint constraintWithItem:_frequencyButtons[i]
                                                                         attribute:NSLayoutAttributeHeight
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:nil
                                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                                        multiplier:1.0
                                                                          constant:ButtonViewSize]
                                            ]];
    }
    
    int index = (_frequencyButtons.count < 7) ? 0 : 7;
    for (int i = index; i <_frequencyButtons.count; i++) {
        [_constraints addObjectsFromArray:@[
                                            [NSLayoutConstraint constraintWithItem:_frequencyButtons[i]
                                                                         attribute:NSLayoutAttributeBottom
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self
                                                                         attribute:NSLayoutAttributeBottom
                                                                        multiplier:1.0
                                                                          constant:-BottomMargin]
                                            ]];
    }
    
    [NSLayoutConstraint activateConstraints:_constraints];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self setUpConstraints];
}

- (void)toggleFrequencyButton:(id)sender {
    OCKCareCardButton *button = (OCKCareCardButton *)sender;
    [self updateAccessibilityInfo];
    
    NSInteger index = [_frequencyButtons indexOfObject:button];
    OCKCarePlanEvent *selectedEvent = self.interventionEvents[index];
    
    if (_delegate &&
        [_delegate respondsToSelector:@selector(careCardTableViewCell:didUpdateFrequencyofInterventionEvent:)]) {
        [_delegate careCardTableViewCell:self didUpdateFrequencyofInterventionEvent:selectedEvent];
    }
    
}


#pragma mark - Accessibility

- (void)updateAccessibilityInfo {
    self.axChildren = nil;
    for (int i = 0; i < _frequencyButtons.count; i++) {
        OCKCareCardButton *frequencyButton = _frequencyButtons[i];
        NSString *completionStr = frequencyButton.isSelected ? OCKLocalizedString(@"AX_CARE_CARD_COMPLETED", nil) : OCKLocalizedString(@"AX_CARE_CARD_INCOMPLETE", nil);
        frequencyButton.accessibilityTraits = UIAccessibilityTraitButton;
        frequencyButton.accessibilityLabel = [NSString stringWithFormat:OCKLocalizedString(@"AX_CARE_CARD_EVENT_LABEL", nil), completionStr, i+1, self.interventionEvents.count, _intervention.title];
    }
}

- (NSArray *)accessibilityElements {
    if (self.axChildren == nil) {
        CareCardAccessibilityElement *cellElement = [[CareCardAccessibilityElement alloc] initWithAccessibilityContainer:self];
        cellElement.accessibilityLabel = OCKAccessibilityStringForVariables(_titleLabel, _textLabel);
        cellElement.accessibilityHint = OCKLocalizedString(@"AX_CARE_CARD_HINT", nil);
        self.axChildren = [NSMutableArray arrayWithObject:cellElement];
        [self.axChildren addObjectsFromArray:_frequencyButtons];
    }
    return self.axChildren;
}

@end


@implementation CareCardAccessibilityElement

- (CGRect)accessibilityFrame {
    return [[self accessibilityContainer] accessibilityFrame];
}

- (NSString *)accessibilityValue {
    OCKCareCardTableViewCell *careCardContainer = [self accessibilityContainer];
    
    NSUInteger numTasksCompleted = 0;
    for (OCKCarePlanEvent *event in careCardContainer.interventionEvents) {
        if (event.state == OCKCarePlanEventStateCompleted) {
            numTasksCompleted++;
        }
    }
    return [NSString stringWithFormat:OCKLocalizedString(@"AX_CARE_CARD_VALUE", nil), numTasksCompleted, careCardContainer.interventionEvents.count];
}

@end
