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


#import "OCKInsightsTableViewHeaderView.h"
#import "OCKHelpers.h"
#import "OCKPatientWidgetView.h"
#import "OCKPatientWidget_Internal.h"


@implementation OCKInsightsTableViewHeaderView {
    UIStackView *_stackView;
    NSMutableArray <NSLayoutConstraint *> *_constraints;
    NSMutableArray <OCKPatientWidgetView *> *_widgetViews;
    NSNumberFormatter *_numberFormatter;
}

- (instancetype)initWithWidgets:(NSArray<OCKPatientWidget *> *)widgets
                          store:(OCKCarePlanStore *)store {
    self = [super init];
    if (self) {
        _widgets = OCKArrayCopyObjects(widgets);
        _store = store;
        
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
    
    _widgetViews = [NSMutableArray new];
    
    for (OCKPatientWidget *widget in self.widgets) {
        OCKPatientWidgetView *widgetView = [OCKPatientWidgetView viewForWidget:widget];
        [_widgetViews addObject:widgetView];
    }
    
    
    _stackView = [[UIStackView alloc] initWithArrangedSubviews:_widgetViews];
    _stackView.alignment = UIStackViewAlignmentCenter;
    _stackView.distribution = UIStackViewDistributionFillEqually;
    _stackView.spacing = 10.0;
    
    [self addSubview:_stackView];
    
    [self setUpConstraints];
    [self updateWidgets];
    
}

- (void)setUpConstraints {
    [NSLayoutConstraint deactivateConstraints:_constraints];
    
    _constraints = [NSMutableArray new];
    
    _stackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_constraints addObjectsFromArray:@[
                                        [NSLayoutConstraint constraintWithItem:_stackView
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_stackView
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:20.0],
                                        [NSLayoutConstraint constraintWithItem:_stackView
                                                                     attribute:NSLayoutAttributeTrailing
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:-20.0],
                                        [NSLayoutConstraint constraintWithItem:_stackView
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_stackView
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1.0
                                                                      constant:90.0]
                                        ]];
    _constraints.lastObject.priority = 999;
    [NSLayoutConstraint activateConstraints:_constraints];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self setUpConstraints];
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    
    self.layer.shadowOffset = CGSizeMake(0, 1 / [UIScreen mainScreen].scale);
    self.layer.shadowRadius = 0;
    
    self.layer.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1].CGColor;
    self.layer.shadowOpacity = 0.25;
}

- (void)updateWidget:(OCKPatientWidget *)widget forWidgetView:(OCKPatientWidgetView *)widgetView {
    OCKPatientWidgetType type = widget.type;
    
    // Get content for widgets if it includes an activity identifier.
    NSString *activityIdentifier = widget.primaryIdentifier;
    if (activityIdentifier) {
        // Go get the activity for the activity identifier, if one exists.
        [self.store activityForIdentifier:activityIdentifier completion:^(BOOL success, OCKCarePlanActivity * _Nullable activity, NSError * _Nullable error) {
            if (success && activity) {
                NSDateComponents *components = [[NSDateComponents alloc] initWithDate:[NSDate date] calendar:[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian]];
                
                if (activity.type == OCKCarePlanActivityTypeIntervention) {
                    // Create widget with activity title and percentage string.
                    __block int totalEvents = 0;
                    __block int completedEvents = 0;
                    
                    [self.store enumerateEventsOfActivity:activity startDate:components endDate:components handler:^(OCKCarePlanEvent * _Nullable event, BOOL * _Nonnull stop) {
                        // Caluclate adherence
                        totalEvents++;
                        if (event.state == OCKCarePlanEventStateCompleted) {
                            completedEvents++;
                        }
                        
                    } completion:^(BOOL completed, NSError * _Nullable error) {
                        if (completed) {
                            double adherence = completedEvents/totalEvents;
                            if (!_numberFormatter) {
                                _numberFormatter = [NSNumberFormatter new];
                                _numberFormatter.numberStyle = NSNumberFormatterPercentStyle;
                                _numberFormatter.maximumFractionDigits = 0;
                            }
                            NSString *adherenceString = [NSString stringWithFormat:@"%@", [_numberFormatter stringFromNumber:@(adherence * 100)]];
                            
                            // Determine if we should apply tint color based on threshold exceeded or not.
                            [self.store evaluateAdheranceThresholdForActivity:activity date:components completion:^(BOOL success, OCKCarePlanThreshold * _Nullable threshold, NSError * _Nullable error) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    widgetView.shouldApplyTintColor = threshold ? YES : NO;
                                    
                                    if (type == OCKPatientWidgetTypeDefault) {
                                        widgetView.widget = [OCKPatientWidget defaultWidgetWithTitle:activity.title text:adherenceString tintColor:widget.tintColor];
                                    } else if (type == OCKPatientWidgetTypeBadge) {
                                        widgetView.widget = [OCKPatientWidget badgeWidgetWithTitle:activity.title value:@(adherence) tintColor:widget.tintColor];
                                    }
                                    
                                });
                            }];
                        } else {
                            OCK_Log_Error(@"%@", error.localizedDescription);
                        }
                    }];
                }
                
                else if (activity.type == OCKCarePlanActivityTypeAssessment) {
                    [self.store eventsForActivity:activity date:components completion:^(NSArray<OCKCarePlanEvent *> * _Nonnull events, NSError * _Nullable error) {
                        OCKCarePlanEvent *latestEvent = events.lastObject;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSArray<NSArray <OCKCarePlanThreshold *>*> *thresholds = [latestEvent evaluateNumericThresholds];
                            widgetView.shouldApplyTintColor = thresholds.firstObject.count > 0 ? YES : NO;
                            if (type == OCKPatientWidgetTypeDefault) {
                                NSMutableString *text = [NSMutableString new];
                                if (latestEvent.result.valueString) {
                                    [text appendString:latestEvent.result.valueString];
                                    if (latestEvent.result.unitString) {
                                        [text appendString:@" "];
                                        [text appendString:latestEvent.result.unitString];
                                    }
                                } else {
                                    [text appendString:@"--"];
                                }
                                
                                widgetView.widget = [OCKPatientWidget defaultWidgetWithTitle:activity.title text:text tintColor:widget.tintColor];
                            } else if (type == OCKPatientWidgetTypeBadge) {
                                NSNumber *value = @0;
                                if (latestEvent.result.values.count > 0) {
                                    value = latestEvent.result.values.firstObject;
                                }
                                widgetView.widget = [OCKPatientWidget badgeWidgetWithTitle:activity.title value:value tintColor:widget.tintColor];
                            }
                        });
                    }];
                }
                
            }
            else {
                OCK_Log_Error(@"No activities found with identifier: %@", activityIdentifier);
            }
        }];
    }
    else {
        widgetView.widget = widget;
        widgetView.shouldApplyTintColor = YES;
    }
}

- (void)updateWidgets {
    for (int i = 0; i < self.widgets.count; i++) {
        [self updateWidget:self.widgets[i] forWidgetView:_widgetViews[i]];
    }
}

@end
