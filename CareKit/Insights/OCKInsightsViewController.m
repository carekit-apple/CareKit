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


#import "OCKInsightsViewController.h"
#import "OCKInsightsTableViewHeaderView.h"
#import "OCKInsightsChartTableViewCell.h"
#import "OCKInsightsMessageTableViewCell.h"
#import "OCKInsightsRingTableViewCell.h"
#import "OCKChart.h"
#import "OCKHelpers.h"
#import "OCKDefines_Private.h"


@interface OCKInsightsViewController() <UITableViewDelegate, UITableViewDataSource>

@end


@implementation OCKInsightsViewController {
    UITableView *_tableView;
    OCKInsightsTableViewHeaderView *_headerView;
    NSMutableArray *_constraints;
    BOOL _hasAnimated;
    NSMutableArray *_triggeredThresholds;
    NSMutableArray *_triggeredThresholdActivities;
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithInsightItems:(NSArray<OCKInsightItem *> *)items
                      patientWidgets:(NSArray<OCKPatientWidget *> *)widgets
                          thresholds:(NSArray<NSString *> *)thresholds
                               store:(OCKCarePlanStore *)store {
    NSAssert(widgets.count < 4, @"A maximum of 3 patient widgets is allowed.");
    if (thresholds.count > 0) {
        NSAssert(store, @"A care plan store is required for thresholds.");
    }
    
    self = [super init];
    if (self) {
        _items = OCKArrayCopyObjects(items);
        _widgets = OCKArrayCopyObjects(widgets);
        _thresholds = OCKArrayCopyObjects(thresholds);
        _store = store;
        _hasAnimated = NO;
    }
    return self;
}

- (instancetype)initWithInsightItems:(NSArray<OCKInsightItem *> *)items {
    return [[OCKInsightsViewController alloc] initWithInsightItems:items
                                                    patientWidgets:nil
                                                        thresholds:nil
                                                             store:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    if (!_headerView) {
        _headerView = [[OCKInsightsTableViewHeaderView alloc] initWithWidgets:self.widgets
                                                                        store:self.store];
        [self.view addSubview:_headerView];
    }
    
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.estimatedRowHeight = 90.0;
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        _tableView.showsVerticalScrollIndicator = NO;
        
        [self.view addSubview:_tableView];
    }
    
    self.navigationController.navigationBar.translucent = NO;
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:245.0/255.0 green:244.0/255.0 blue:246.0/255.0 alpha:1.0]];
    
    [self setUpConstraints];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_headerView updateWidgets];
    [self evaluateThresholds];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!_hasAnimated) {
        _hasAnimated = YES;
        
        for (UITableViewCell *cell in _tableView.visibleCells) {
            if ([cell isKindOfClass:[OCKInsightsChartTableViewCell class]]) {
                OCKInsightsChartTableViewCell *chartCell = (OCKInsightsChartTableViewCell *)cell;
                [chartCell animateWithDuration:1.0];
            }
        }
    }
}

- (void)setItems:(NSArray<OCKInsightItem *> *)items {
    _items = OCKArrayCopyObjects(items);
    [_tableView reloadData];
}

- (void)setUpConstraints {
    [NSLayoutConstraint deactivateConstraints:_constraints];
    
    _constraints = [NSMutableArray new];
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _headerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    CGFloat headerViewHeight = (self.widgets.count > 0) ? 100 : 0;
    
    [_constraints addObjectsFromArray:@[
                                        [NSLayoutConstraint constraintWithItem: _headerView
                                                                     attribute: NSLayoutAttributeTop
                                                                     relatedBy: NSLayoutRelationEqual
                                                                        toItem: self.topLayoutGuide
                                                                     attribute: NSLayoutAttributeBottom
                                                                    multiplier: 1.0
                                                                      constant: 0.0],
                                        [NSLayoutConstraint constraintWithItem: _headerView
                                                                     attribute: NSLayoutAttributeLeading
                                                                     relatedBy: NSLayoutRelationEqual
                                                                        toItem: self.view
                                                                     attribute: NSLayoutAttributeLeading
                                                                    multiplier: 1.0
                                                                      constant: 0.0],
                                        [NSLayoutConstraint constraintWithItem: _headerView
                                                                     attribute: NSLayoutAttributeTrailing
                                                                     relatedBy: NSLayoutRelationEqual
                                                                        toItem: self.view
                                                                     attribute: NSLayoutAttributeTrailing
                                                                    multiplier: 1.0
                                                                      constant: 0.0],
                                        [NSLayoutConstraint constraintWithItem: _headerView
                                                                     attribute: NSLayoutAttributeHeight
                                                                     relatedBy: NSLayoutRelationEqual
                                                                        toItem: nil
                                                                     attribute: NSLayoutAttributeNotAnAttribute
                                                                    multiplier: 1.0
                                                                      constant: headerViewHeight],
                                        [NSLayoutConstraint constraintWithItem: _tableView
                                                                     attribute: NSLayoutAttributeTop
                                                                     relatedBy: NSLayoutRelationEqual
                                                                        toItem: _headerView
                                                                     attribute: NSLayoutAttributeBottom
                                                                    multiplier: 1.0
                                                                      constant: 0.0],
                                        [NSLayoutConstraint constraintWithItem: _tableView
                                                                     attribute: NSLayoutAttributeLeading
                                                                     relatedBy: NSLayoutRelationEqual
                                                                        toItem: self.view
                                                                     attribute: NSLayoutAttributeLeading
                                                                    multiplier: 1.0
                                                                      constant: 0.0],
                                        [NSLayoutConstraint constraintWithItem: _tableView
                                                                     attribute: NSLayoutAttributeTrailing
                                                                     relatedBy: NSLayoutRelationEqual
                                                                        toItem: self.view
                                                                     attribute: NSLayoutAttributeTrailing
                                                                    multiplier: 1.0
                                                                      constant: 0.0],
                                        [NSLayoutConstraint constraintWithItem: _tableView
                                                                     attribute: NSLayoutAttributeBottom
                                                                     relatedBy: NSLayoutRelationEqual
                                                                        toItem: self.bottomLayoutGuide
                                                                     attribute: NSLayoutAttributeTop
                                                                    multiplier: 1.0
                                                                      constant: 0.0]
                                        ]];
    
    [NSLayoutConstraint activateConstraints:_constraints];
    
    
}

- (void)evaluateThresholds {
    NSDateComponents *dateComponents = [[NSDateComponents alloc] initWithDate:[NSDate date]
                                                                     calendar:[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian]];
    
    _triggeredThresholds = [NSMutableArray new];
    _triggeredThresholdActivities = [NSMutableArray new];
    
    for (NSString *identifier in self.thresholds) {
        [self.store activityForIdentifier:identifier completion:^(BOOL success, OCKCarePlanActivity * _Nullable activity, NSError * _Nullable error) {
            if (success && activity) {
                [self.store eventsForActivity:activity date:dateComponents completion:^(NSArray<OCKCarePlanEvent *> * _Nonnull events, NSError * _Nullable error) {
                    if (activity.type == OCKCarePlanActivityTypeIntervention) {
                        [self.store evaluateAdheranceThresholdForActivity:activity date:dateComponents completion:^(BOOL success, OCKCarePlanThreshold * _Nullable threshold, NSError * _Nullable error) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (success && threshold) {
                                    [_triggeredThresholds addObject:threshold];
                                    [_triggeredThresholdActivities addObject:activity];
                                }
                                
                                if ([identifier isEqualToString:self.thresholds.lastObject]) {
                                    [_tableView reloadData];
                                }
                            });
                        }];
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            for (OCKCarePlanEvent *event in events) {
                                NSArray<NSArray<OCKCarePlanThreshold *> *> *thresholds = [event evaluateNumericThresholds];
                                for (NSArray<OCKCarePlanThreshold *> *thresholdArray in thresholds) {
                                    for (OCKCarePlanThreshold *threshold in thresholdArray) {
                                        if (threshold) {
                                            [_triggeredThresholds addObject:threshold];
                                            [_triggeredThresholdActivities addObject:activity];
                                        }
                                    }
                                }
                            }
                            
                            if ([identifier isEqualToString:self.thresholds.lastObject]) {
                                [_tableView reloadData];
                            }
                        });
                    }
                }];
            }
        }];
    }
    if (_triggeredThresholds.count <= 0) {
        [_tableView reloadData];
    }
}


#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger numberOfSections = 0;
    
    if (_triggeredThresholds.count > 0) {
        numberOfSections++;
    }
    
    if (self.items.count > 0) {
        numberOfSections++;
    }
    
    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    
    if (_triggeredThresholds.count > 0 && self.items.count > 0) {
        numberOfRows = (section == 0) ? _triggeredThresholds.count : self.items.count;
    } else if (_triggeredThresholds.count > 0) {
        numberOfRows = _triggeredThresholds.count;
    } else if (self.items.count > 0) {
        numberOfRows = self.items.count;
    }
    
    return numberOfRows;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return tableView.numberOfSections - 1 == section ? OCKLocalizedString(@"INSIGHTS_SECTION_HEADER_TITLE_INSIGHTS", nil) : OCKLocalizedString(@"INSIGHTS_SECTION_HEADER_TITLE_THRESHOLD_ALERTS", nil);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0 && tableView.numberOfSections == 2) {
        if (_triggeredThresholds.count > 0) {
            static NSString *ThresholdCellIdentifier = @"ThresholdCellIdentifier";
            OCKInsightsMessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ThresholdCellIdentifier];
            if (!cell) {
                cell = [[OCKInsightsMessageTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                              reuseIdentifier:ThresholdCellIdentifier];
            }
            OCKCarePlanThreshold *threshold = _triggeredThresholds[indexPath.row];
            OCKCarePlanActivity *activity = _triggeredThresholdActivities[indexPath.row];
            OCKMessageItem *messageItem = [[OCKMessageItem alloc] initWithTitle:activity.title text:threshold.title tintColor:nil messageType:OCKMessageItemTypePlain];
            cell.messageItem = messageItem;
            return cell;
            
        }
    } else {
        OCKInsightItem *item = self.items[indexPath.row];
        
        if ([item isKindOfClass:[OCKChart class]]) {
            static NSString *ChartCellIdentifier = @"ChartCell";
            OCKInsightsChartTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ChartCellIdentifier];
            if (!cell) {
                cell = [[OCKInsightsChartTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                            reuseIdentifier:ChartCellIdentifier];
            }
            cell.chart = (OCKChart *)item;
            return cell;
        }
        else if ([item isKindOfClass:[OCKMessageItem class]]) {
            static NSString *MessageCellIdentifier = @"MessageCell";
            OCKInsightsMessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MessageCellIdentifier];
            if (!cell) {
                cell = [[OCKInsightsMessageTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                              reuseIdentifier:MessageCellIdentifier];
            }
            cell.messageItem = (OCKMessageItem *)item;
            return cell;
        }
        else if ([item isKindOfClass:[OCKRingItem class]]) {
            static NSString *RingCellIdentifier = @"RingCell";
            OCKInsightsRingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:RingCellIdentifier];
            if (!cell) {
                cell = [[OCKInsightsRingTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                           reuseIdentifier:RingCellIdentifier];
            }
            cell.ringItem = (OCKRingItem *)item;
            return cell;
        }
        
    }
    
    return nil;
}

@end
