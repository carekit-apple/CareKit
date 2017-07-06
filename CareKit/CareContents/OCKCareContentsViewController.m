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


#import "OCKCareContentsViewController.h"
#import "OCKWeekView.h"
#import "OCKCareCardDetailViewController.h"
#import "OCKWeekViewController.h"
#import "NSDateComponents+CarePlanInternal.h"
#import "OCKHeaderView.h"
#import "OCKCareCardTableViewCell.h"
#import "OCKSymptomTrackerTableViewCell.h"
#import "OCKReadOnlyTableViewCell.h"
#import "OCKWeekLabelsView.h"
#import "OCKCarePlanStore_Internal.h"
#import "OCKHelpers.h"
#import "OCKDefines_Private.h"
#import "OCKGlyph_Internal.h"


#define RedColor() OCKColorFromRGB(0xEF445B);


@interface OCKCareContentsViewController() <OCKWeekViewDelegate, OCKCarePlanStoreDelegate, OCKCareCardCellDelegate, UITableViewDelegate, UITableViewDataSource, UIPageViewControllerDelegate, UIPageViewControllerDataSource, UIViewControllerPreviewingDelegate>

@property (nonatomic) NSDateComponents *selectedDate;

@end


@implementation OCKCareContentsViewController {
    UITableView *_tableView;
    NSMutableArray<NSMutableArray<OCKCarePlanEvent *> *> *_events;
    NSMutableArray *_weekValues;
    OCKHeaderView *_headerView;
    UIPageViewController *_pageViewController;
    OCKWeekViewController *_weekViewController;
    NSCalendar *_calendar;
    NSMutableArray *_constraints;
    NSMutableArray *_sectionTitles;
    NSMutableArray<NSMutableArray <NSMutableArray <OCKCarePlanEvent *> *> *> *_tableViewData;
    NSMutableDictionary *_allEvents;
    
    NSString *_otherString;
    NSString *_optionalString;
    NSString *_readOnlyString;
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithCarePlanStore:(OCKCarePlanStore *)store {
    self = [super init];
    if (self) {
        _store = store;
        _calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        _glyphTintColor = nil;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _otherString = OCKLocalizedString(@"ACTIVITY_TYPE_OTHER_SECTION_HEADER", nil);
    _optionalString = OCKLocalizedString(@"ACTIVITY_TYPE_OPTIONAL_SECTION_HEADER", nil);
    _readOnlyString = OCKLocalizedString(@"ACTIVITY_TYPE_READ_ONLY_SECTION_HEADER", nil);
    if (self.optionalSectionHeader && ![self.optionalSectionHeader  isEqual: @""]) {
        _optionalString = _optionalSectionHeader;
    }
    if (self.readOnlySectionHeader && ![self.readOnlySectionHeader  isEqual: @""]) {
        _readOnlyString = _readOnlySectionHeader;
    }
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.store.symptomTrackerUIDelegate = self;
    self.store.careCardUIDelegate = self;
    [self setGlyphTintColor: _glyphTintColor];
    NSDictionary *_initialDictionary = @{ @(OCKCarePlanActivityTypeAssessment): [NSMutableArray new],
                                         @(OCKCarePlanActivityTypeIntervention): [NSMutableArray new],
                                         @(OCKCarePlanActivityTypeReadOnly): [NSMutableArray new] };
    _allEvents = [_initialDictionary mutableCopy];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:OCKLocalizedString(@"TODAY_BUTTON_TITLE", nil)
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(showToday:)];
    self.navigationItem.rightBarButtonItem.tintColor = self.glyphTintColor;

    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [self.view addSubview:_tableView];
    
    [self prepareView];
    self.selectedDate = [NSDateComponents ock_componentsWithDate:[NSDate date] calendar:_calendar];
    _tableView.estimatedRowHeight = 90.0;
    _tableView.rowHeight = UITableViewAutomaticDimension;
    _tableView.tableFooterView = [UIView new];
    _tableView.estimatedSectionHeaderHeight = 0;
    _tableView.estimatedSectionFooterHeight = 0;
    
    self.navigationController.navigationBar.translucent = NO;
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:245.0/255.0 green:244.0/255.0 blue:246.0/255.0 alpha:1.0]];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSAssert(self.navigationController, @"OCKCareViewController must be embedded in a navigation controller.");
    _weekViewController.weekView.delegate = self;
}

- (void)showToday:(id)sender {
    self.selectedDate = [NSDateComponents ock_componentsWithDate:[NSDate date] calendar:_calendar];
    [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:NSNotFound inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

- (void)prepareView {
    if (!_headerView) {
        _headerView = [[OCKHeaderView alloc] initWithFrame:CGRectZero];
        [self.view addSubview:_headerView];
    }
    
    _headerView.tintColor = self.glyphTintColor;
    if (self.glyphType == OCKGlyphTypeCustom) {
        UIImage *glyphImage = [self createCustomImageName:self.customGlyphImageName];
        _headerView.glyphImage = glyphImage;
    }
    _headerView.isCareCard = YES;
    _headerView.glyphType = self.glyphType;
    
    if (!_pageViewController) {
        _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                              navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                            options:nil];
        _pageViewController.dataSource = self;
        _pageViewController.delegate = self;
        
        if (!UIAccessibilityIsReduceTransparencyEnabled()) {
            _pageViewController.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
            
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleProminent];
            UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            blurEffectView.frame = _pageViewController.view.bounds;
            blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [_pageViewController.view insertSubview:blurEffectView atIndex:_pageViewController.view.subviews.count-1];
        }
        else {
            _pageViewController.view.backgroundColor = [UIColor whiteColor];
        }
        
        OCKWeekViewController *weekController = [OCKWeekViewController new];
        weekController.weekView.delegate = _weekViewController.weekView.delegate;
        weekController.weekView.ringTintColor = self.glyphTintColor;
        weekController.weekView.isCareCard = YES;
        weekController.weekView.glyphType = self.glyphType;
        _weekViewController = weekController;
        
        [_pageViewController setViewControllers:@[weekController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
        [self.view addSubview:_pageViewController.view];
    }
    
    _tableView.showsVerticalScrollIndicator = NO;
    
    [self setUpConstraints];
}

- (void)setUpConstraints {
    [NSLayoutConstraint deactivateConstraints:_constraints];
    
    _constraints = [NSMutableArray new];
    
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _pageViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    _headerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    
    [_constraints addObjectsFromArray:@[
                                        [NSLayoutConstraint constraintWithItem:_pageViewController.view
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.topLayoutGuide
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_pageViewController.view
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_headerView
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:10.0],
                                        [NSLayoutConstraint constraintWithItem:_pageViewController.view
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.view
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_pageViewController.view
                                                                     attribute:NSLayoutAttributeTrailing
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.view
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_pageViewController.view
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1.0
                                                                      constant:65.0],
                                        [NSLayoutConstraint constraintWithItem:_headerView
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1.0
                                                                      constant:140.0],
                                        [NSLayoutConstraint constraintWithItem:_headerView
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_tableView
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_tableView
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.view
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_tableView
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.view
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_tableView
                                                                     attribute:NSLayoutAttributeTrailing
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.view
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_headerView
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.view
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_headerView
                                                                     attribute:NSLayoutAttributeTrailing
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.view
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:0.0]
                                        ]];
    
    [NSLayoutConstraint activateConstraints:_constraints];
}

- (void)setSelectedDate:(NSDateComponents *)selectedDate {
    _selectedDate = selectedDate;
    
    _weekViewController.weekView.isToday = [[self today] isEqualToDate:selectedDate];
    _weekViewController.weekView.selectedIndex = self.selectedDate.weekday - 1;
    
    [self fetchEvents];
}

- (void)setGlyphTintColor:(UIColor *)glyphTintColor {
    _glyphTintColor = glyphTintColor;
    if (!_glyphTintColor) {
        _glyphTintColor = [OCKGlyph defaultColorForGlyph:self.glyphType];
    }
    _weekViewController.weekView.tintColor = _glyphTintColor;
    _headerView.tintColor = _glyphTintColor;
    self.navigationItem.rightBarButtonItem.tintColor = _glyphTintColor;
}


#pragma mark - Helpers

- (void)fetchEvents {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self fetchEventsOfType:OCKCarePlanActivityTypeIntervention];
        [self fetchEventsOfType:OCKCarePlanActivityTypeAssessment];
        [self fetchEventsOfType:OCKCarePlanActivityTypeReadOnly];
    });
}

- (void)fetchEventsOfType:(OCKCarePlanActivityType)type {
    [self.store eventsOnDate:self.selectedDate
                        type:type
                  completion:^(NSArray<NSArray<OCKCarePlanEvent *> *> *eventsGroupedByActivity, NSError *error) {
                      NSAssert(!error, error.localizedDescription);
                      dispatch_async(dispatch_get_main_queue(), ^{
                          _events = [NSMutableArray new];
                          for (NSArray<OCKCarePlanEvent *> *events in eventsGroupedByActivity) {
                              [_events addObject:[events mutableCopy]];
                          }
                          [_allEvents setObject:_events forKey:@(type)];
                          
                          if (self.delegate &&
                              [self.delegate respondsToSelector:@selector(careContentsViewController:willDisplayEvents:dateComponents:)]) {
                              [self.delegate careContentsViewController:self willDisplayEvents:[_events copy] dateComponents:_selectedDate];
                          }
                          [self createGroupedEventDictionaryForEvents];
                          if (type == OCKCarePlanActivityTypeIntervention || type == OCKCarePlanActivityTypeAssessment) {
                              [self updateHeaderView];
                              [self updateWeekView];
                          }
                          [_tableView reloadData];
                      });
                  }];

}

- (void)updateHeaderView {
    _headerView.date = [NSDateFormatter localizedStringFromDate:[_calendar dateFromComponents:self.selectedDate]
                                                      dateStyle:NSDateFormatterLongStyle
                                                      timeStyle:NSDateFormatterNoStyle];
    NSMutableArray *values = [NSMutableArray new];
    __block NSUInteger completedEvents;
    __block NSUInteger totalEvents;
    
    __weak __typeof__(self) weakSelf = self;
    
    [self.store dailyCompletionStatusWithType:OCKCarePlanActivityTypeIntervention
                                    startDate:self.selectedDate
                                      endDate:self.selectedDate
                                      handler:^(NSDateComponents *date, NSUInteger completedInterventionEvents, NSUInteger totalInterventionEvents) {
                                          
                                          completedEvents = completedInterventionEvents;
                                          totalEvents = totalInterventionEvents;
                                          
                                      } completion:^(BOOL completed, NSError *error) {
                                          NSAssert(!error, error.localizedDescription);
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              __typeof__(self) strongSelf = weakSelf;
                                              [strongSelf.store dailyCompletionStatusWithType:OCKCarePlanActivityTypeAssessment
                                                                                    startDate:strongSelf.selectedDate
                                                                                      endDate:strongSelf.selectedDate
                                                                                      handler:^(NSDateComponents *date, NSUInteger completedAssessmentEvents, NSUInteger totalAssessmentEvents) {
                                                                                          completedEvents = completedEvents + completedAssessmentEvents;
                                                                                          totalEvents = totalEvents + totalAssessmentEvents;
                                                                                          if (totalEvents == 0) {
                                                                                              [values addObject:@(1)];
                                                                                          } else {
                                                                                              [values addObject:@((float)completedEvents/totalEvents)];
                                                                                          }
                                                                                          
                                                                                      } completion:^(BOOL completed, NSError *error) {
                                                                                          NSAssert(!error, error.localizedDescription);
                                                                                          dispatch_async(dispatch_get_main_queue(), ^{
                                                                                              NSInteger selectedIndex = _weekViewController.weekView.selectedIndex;
                                                                                              [_weekValues replaceObjectAtIndex:selectedIndex withObject:values.firstObject];
                                                                                              _weekViewController.weekView.values = _weekValues;
                                                                                              _headerView.value = [values.firstObject doubleValue];
                                                                                          });
                                                                                      }];
                                          });
                                      }];
}

- (void)updateWeekView {
    NSDate *selectedDate = [_calendar dateFromComponents:self.selectedDate];
    NSDate *startOfWeek;
    NSTimeInterval interval;
    [_calendar rangeOfUnit:NSCalendarUnitWeekOfMonth
                 startDate:&startOfWeek
                  interval:&interval
                   forDate:selectedDate];
    NSDate *endOfWeek = [startOfWeek dateByAddingTimeInterval:interval-1];
    
    NSMutableArray *values = [NSMutableArray new];
    NSMutableArray *interventionCompleted = [NSMutableArray new];
    NSMutableArray *interventionTotal = [NSMutableArray new];
    NSMutableArray *assessmentCompleted = [NSMutableArray new];
    NSMutableArray *assessmentTotal = [NSMutableArray new];
    __weak __typeof__(self) weakSelf = self;
    [self.store dailyCompletionStatusWithType:OCKCarePlanActivityTypeIntervention
                                    startDate:[NSDateComponents ock_componentsWithDate:startOfWeek calendar:_calendar]
                                      endDate:[NSDateComponents ock_componentsWithDate:endOfWeek calendar:_calendar]
                                      handler:^(NSDateComponents *date, NSUInteger completedEvents, NSUInteger totalEvents) {
                                          [interventionCompleted addObject:@((float)completedEvents)];
                                          [interventionTotal addObject:@((float)totalEvents)];
                                      } completion:^(BOOL completed, NSError *error) {
                                          NSAssert(!error, error.localizedDescription);
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              __typeof__(self) strongSelf = weakSelf;
                                              [strongSelf.store dailyCompletionStatusWithType:OCKCarePlanActivityTypeAssessment
                                                                                    startDate:[NSDateComponents ock_componentsWithDate:startOfWeek calendar:_calendar]
                                                                                      endDate:[NSDateComponents ock_componentsWithDate:endOfWeek calendar:_calendar]
                                                                                      handler:^(NSDateComponents *date, NSUInteger completedEvents, NSUInteger totalEvents) {
                                                                                          [assessmentCompleted addObject:@((float)completedEvents)];
                                                                                          [assessmentTotal addObject:@((float)totalEvents)];
                                                                                      } completion:^(BOOL completed, NSError *error) {
                                                                                          NSAssert(!error, error.localizedDescription);
                                                                                          dispatch_async(dispatch_get_main_queue(), ^{
                                                                                              for (int i = 0; i<7; i++) {
                                                                                                  if (([interventionTotal[i] floatValue] + [assessmentTotal[i] floatValue]) == 0) {
                                                                                                      [values addObject:@(1)];
                                                                                                  } else {
                                                                                                      float completed = [interventionCompleted[i] floatValue] + [assessmentCompleted[i] floatValue];
                                                                                                      float total = [interventionTotal[i] floatValue] + [assessmentTotal[i] floatValue];
                                                                                                      [values addObject:@(completed/total)];
                                                                                                  }
                                                                                              }
                                                                                              _weekViewController.weekView.values = values;
                                                                                              _weekValues = [values mutableCopy];
                                                                                          });
                                                                                      }];
                                          });
                                      }];
}

- (UIImage *)createCustomImageName:(NSString*)customImageName {
    UIImage *customImageToReturn;
    if (customImageName != nil) {
        NSBundle *bundle = [NSBundle mainBundle];
        customImageToReturn = [UIImage imageNamed: customImageName inBundle:bundle compatibleWithTraitCollection:nil];
    } else {
        OCKGlyphType defaultGlyph = OCKGlyphTypeHeart;
        customImageToReturn = [[OCKGlyph glyphImageForType:defaultGlyph] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return customImageToReturn;
}

- (NSDateComponents *)dateFromSelectedIndex:(NSInteger)index {
    NSDateComponents *newComponents = [NSDateComponents new];
    newComponents.year = self.selectedDate.year;
    newComponents.month = self.selectedDate.month;
    newComponents.weekOfMonth = self.selectedDate.weekOfMonth;
    newComponents.weekday = index + 1;
    
    NSDate *newDate = [_calendar dateFromComponents:newComponents];
    return [NSDateComponents ock_componentsWithDate:newDate calendar:_calendar];
}

- (NSDateComponents *)today {
    return [NSDateComponents ock_componentsWithDate:[NSDate date] calendar:_calendar];
}

- (void)createGroupedEventDictionaryForEvents {
    
    NSArray<OCKCarePlanEvent *> *interventions = _allEvents[@(OCKCarePlanActivityTypeIntervention)];
    NSArray<OCKCarePlanEvent *> *assessments = _allEvents[@(OCKCarePlanActivityTypeAssessment)];
    NSArray<OCKCarePlanEvent *> *readOnly = _allEvents[@(OCKCarePlanActivityTypeReadOnly)];
    
    NSMutableArray *interventionGroupIdentifiers = [[NSMutableArray alloc] init];
    NSMutableArray *assessmentGroupIdentifiers = [[NSMutableArray alloc] init];
    
    NSArray<NSArray<OCKCarePlanEvent *> *> *events = [NSArray arrayWithArray:[interventions arrayByAddingObjectsFromArray:[assessments arrayByAddingObjectsFromArray:readOnly]]];
    NSMutableDictionary *groupedEvents = [NSMutableDictionary new];
    
    for (NSArray<OCKCarePlanEvent *> *activityEvents in events) {
        OCKCarePlanEvent *firstEvent = activityEvents.firstObject;
        
        if (firstEvent.activity.groupIdentifier && firstEvent.activity.type == OCKCarePlanActivityTypeIntervention) {
            if (![interventionGroupIdentifiers containsObject:firstEvent.activity.groupIdentifier]) {
                [interventionGroupIdentifiers addObject:firstEvent.activity.groupIdentifier];
            }
        }
        
        if (firstEvent.activity.groupIdentifier && firstEvent.activity.type == OCKCarePlanActivityTypeAssessment) {
            if (![assessmentGroupIdentifiers containsObject:firstEvent.activity.groupIdentifier]) {
                [assessmentGroupIdentifiers addObject:firstEvent.activity.groupIdentifier];
            }
        }
        
        NSString *groupIdentifier = firstEvent.activity.groupIdentifier ? firstEvent.activity.groupIdentifier : _otherString;
        
        if (firstEvent.activity.optional) {
            groupIdentifier = firstEvent.activity.type == OCKCarePlanActivityTypeReadOnly ? _readOnlyString : _optionalString;
        }
        
        if (groupedEvents[groupIdentifier]) {
            NSMutableArray<NSArray *> *objects = [groupedEvents[groupIdentifier] mutableCopy];
            [objects addObject:activityEvents];
            groupedEvents[groupIdentifier] = objects;
        } else {
            NSMutableArray<NSArray *> *objects = [activityEvents mutableCopy];
            groupedEvents[groupIdentifier] = @[objects];
        }
    }
    
    NSMutableArray *sortedKeys = [[groupedEvents.allKeys sortedArrayUsingSelector:@selector(compare:)] mutableCopy];
    
    for (NSString *groupIdentifier in interventionGroupIdentifiers) {
        if ([sortedKeys containsObject:groupIdentifier]) {
            [sortedKeys removeObject:groupIdentifier];
            [sortedKeys addObject:groupIdentifier];
        }
    }
    
    for (NSString *groupIdentifier in assessmentGroupIdentifiers) {
        if ([sortedKeys containsObject:groupIdentifier]) {
            [sortedKeys removeObject:groupIdentifier];
            [sortedKeys addObject:groupIdentifier];
        }
    }
    
    if ([sortedKeys containsObject:_otherString]) {
        [sortedKeys removeObject:_otherString];
        [sortedKeys addObject:_otherString];
    }
    
    if ([sortedKeys containsObject:_optionalString]) {
        [sortedKeys removeObject:_optionalString];
        [sortedKeys addObject:_optionalString];
    }
    
    if ([sortedKeys containsObject:_readOnlyString]) {
        [sortedKeys removeObject:_readOnlyString];
        [sortedKeys addObject:_readOnlyString];
    }
    
    _sectionTitles = [sortedKeys copy];
    
    NSMutableArray *array = [NSMutableArray new];
    for (NSString *key in _sectionTitles) {
        NSMutableArray *groupArray = [NSMutableArray new];
        NSArray *groupedEventsArray = groupedEvents[key];
        
        NSMutableDictionary *activitiesDictionary = [NSMutableDictionary new];
        for (NSArray<OCKCarePlanEvent *> *events in groupedEventsArray) {
            NSString *activityTitle = events.firstObject.activity.title;
            activitiesDictionary[activityTitle] = events;
        }
        
        NSArray *sortedActivitiesKeys = [activitiesDictionary.allKeys sortedArrayUsingSelector:@selector(compare:)];
        for (NSString *activityKey in sortedActivitiesKeys) {
            [groupArray addObject:activitiesDictionary[activityKey]];
        }
        [array addObject:groupArray];
    }
    _tableViewData = [array mutableCopy];
}


#pragma mark - OCKWeekViewDelegate

- (void)weekViewSelectionDidChange:(UIView *)weekView {
    OCKWeekView *currentWeekView = (OCKWeekView *)weekView;
    NSDateComponents *selectedDate = [self dateFromSelectedIndex:currentWeekView.selectedIndex];
    self.selectedDate = selectedDate;
}


#pragma mark - OCKCarePlanStoreDelegate

- (void)carePlanStore:(OCKCarePlanStore *)store didReceiveUpdateOfEvent:(OCKCarePlanEvent *)event {
    for (int i = 0; i < _tableViewData.count; i++) {
        NSMutableArray<NSMutableArray <OCKCarePlanEvent *> *> *groupedEvents = _tableViewData[i];
        
        for (int j = 0; j < groupedEvents.count; j++) {
            NSMutableArray<OCKCarePlanEvent *> *events = groupedEvents[j];
            
            if ([events.firstObject.activity.identifier isEqualToString:event.activity.identifier]) {
                if (events[event.occurrenceIndexOfDay].numberOfDaysSinceStart == event.numberOfDaysSinceStart) {
                    [events replaceObjectAtIndex:event.occurrenceIndexOfDay withObject:event];
                    _tableViewData[i][j] = events;
                    [self updateHeaderView];
                    
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:j inSection:i];
                    OCKCarePlanActivityType type = _tableViewData[indexPath.section][indexPath.row].firstObject.activity.type;
                    if ( type == OCKCarePlanActivityTypeIntervention) {
                        OCKCareCardTableViewCell *cell = [_tableView cellForRowAtIndexPath:indexPath];
                        cell.interventionEvents = events;
                    } else if (type == OCKCarePlanActivityTypeAssessment) {
                        OCKSymptomTrackerTableViewCell *cell = [_tableView cellForRowAtIndexPath:indexPath];
                        cell.assessmentEvent = events.firstObject;
                    }
                }
                break;
            }
        }
    }
    
    if ([event.date isInSameWeekAsDate: self.selectedDate]) {
        [self updateWeekView];
    }
}

- (void)carePlanStoreActivityListDidChange:(OCKCarePlanStore *)store {
    [self fetchEvents];
}


#pragma mark - UIPageViewControllerDelegate

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed {
    if (completed) {
        OCKWeekViewController *controller = (OCKWeekViewController *)pageViewController.viewControllers.firstObject;
        controller.weekView.delegate = _weekViewController.weekView.delegate;
        
        NSDateComponents *components = [NSDateComponents new];
        components.day = (controller.weekIndex > _weekViewController.weekIndex) ? 7 : -7;
        NSDate *newDate = [_calendar dateByAddingComponents:components toDate:[_calendar dateFromComponents:self.selectedDate] options:0];
        
        _weekViewController = controller;
        self.selectedDate = [NSDateComponents ock_componentsWithDate:newDate calendar:_calendar];
    }
}


#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    OCKWeekViewController *controller = [OCKWeekViewController new];
    controller.weekIndex = ((OCKWeekViewController *)viewController).weekIndex - 1;
    controller.weekView.tintColor = self.glyphTintColor;
    controller.weekView.isCareCard = YES;
    controller.weekView.glyphType = self.glyphType;
    return controller;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    OCKWeekViewController *controller = [OCKWeekViewController new];
    controller.weekIndex = ((OCKWeekViewController *)viewController).weekIndex + 1;
    controller.weekView.tintColor = self.glyphTintColor;
    controller.weekView.isCareCard = YES;
    controller.weekView.glyphType = self.glyphType;
    return controller;
}


#pragma mark - UITableViewDelegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *sectionTitle = _sectionTitles[section];
    if ([sectionTitle isEqualToString:_otherString] && (_sectionTitles.count == 1 || (_sectionTitles.count == 2 && [_sectionTitles containsObject:_optionalString]))) {
        sectionTitle = @"";
    }
    return sectionTitle;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    OCKCarePlanEvent *selectedEvent = _tableViewData[indexPath.section][indexPath.row].firstObject;
    _lastSelectedEvent = selectedEvent;
    _lastSelectedActivity = selectedEvent.activity;
    
    OCKCarePlanActivityType type = selectedEvent.activity.type;
    
    if (type == OCKCarePlanActivityTypeAssessment) {
        if (_delegate &&
            [_delegate respondsToSelector:@selector(careContentsViewController:didSelectRowWithAssessmentEvent:)]) {
            [_delegate careContentsViewController:self didSelectRowWithAssessmentEvent:selectedEvent];
        }
    }
    else if (type == OCKCarePlanActivityTypeReadOnly) {
        if ([self delegateCustomizesRowReadOnlySelection]) {
            [self.delegate careContentsViewController:self didSelectRowWithReadOnlyActivity:selectedEvent.activity];
        } else {
            [self.navigationController pushViewController:[self detailViewControllerForActivity:selectedEvent.activity] animated:YES];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_tableViewData[indexPath.section][indexPath.row].firstObject.activity.type == OCKCarePlanActivityTypeIntervention) {
        return NO;
    } else {
        return YES;
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _tableViewData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _tableViewData[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray <OCKCarePlanEvent *> *events = _tableViewData[indexPath.section][indexPath.row];
    
    OCKCarePlanEvent *event = events.firstObject;
    OCKCarePlanActivity *activity = event.activity;
    OCKCarePlanActivityType type = activity.type;
    
    if (type == OCKCarePlanActivityTypeAssessment) {
        
        static NSString *CellIdentifier = @"SymptomTrackerCell";
        OCKSymptomTrackerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            cell = [[OCKSymptomTrackerTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                         reuseIdentifier:CellIdentifier];
        }
        
        cell.assessmentEvent = event;
        
        return cell;
    }
    else if (type == OCKCarePlanActivityTypeReadOnly) {
        
        static NSString *CellIdentifier = @"ReadOnlyCell";
        OCKReadOnlyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            cell = [[OCKReadOnlyTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                   reuseIdentifier:CellIdentifier];
        }
        
        cell.readOnlyEvent = event;

        return cell;
    }
    else {
        
        static NSString *CellIdentifier = @"CareCardCell";
        OCKCareCardTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            cell = [[OCKCareCardTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                   reuseIdentifier:CellIdentifier];
        }
        
        cell.interventionEvents = events;
        cell.delegate = self;
        
        return cell;
    }
    
    return nil;
}

- (UIViewController *)detailViewControllerForActivity:(OCKCarePlanActivity *)activity {
    OCKCareCardDetailViewController *detailViewController = [[OCKCareCardDetailViewController alloc] initWithIntervention:activity];
    return detailViewController;
}

- (OCKCarePlanActivity *)activityForIndexPath:(NSIndexPath *)indexPath {
    return _tableViewData[indexPath.section][indexPath.row].firstObject.activity;
}

- (BOOL)delegateCustomizesRowSelection {
    return self.delegate && [self.delegate respondsToSelector:@selector(careContentsViewController:didSelectRowWithInterventionActivity:)];
}

- (BOOL)delegateCustomizesRowReadOnlySelection {
    return self.delegate && [self.delegate respondsToSelector:@selector(careContentsViewController:didSelectRowWithReadOnlyActivity:)];
}


#pragma mark - OCKCareCardCellDelegate

- (void)careCardTableViewCell:(OCKCareCardTableViewCell *)cell didUpdateFrequencyofInterventionEvent:(OCKCarePlanEvent *)event {
    _lastSelectedEvent = event;
    _lastSelectedActivity = event.activity;
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(careContentsViewController:didSelectButtonWithInterventionEvent:)]) {
        [self.delegate careContentsViewController:self didSelectButtonWithInterventionEvent:event];
    }
    
    BOOL shouldHandleEventCompletion = YES;
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(careContentsViewController:shouldHandleEventCompletionForInterventionActivity:)]) {
        shouldHandleEventCompletion = [self.delegate careContentsViewController:self shouldHandleEventCompletionForInterventionActivity:event.activity];
    }
    
    if (shouldHandleEventCompletion) {
        OCKCarePlanEventState state = (event.state == OCKCarePlanEventStateCompleted) ? OCKCarePlanEventStateNotCompleted : OCKCarePlanEventStateCompleted;
        
        [self.store updateEvent:event
                     withResult:nil
                          state:state
                     completion:^(BOOL success, OCKCarePlanEvent * _Nonnull event, NSError * _Nonnull error) {
                         NSAssert(success, error.localizedDescription);
                         dispatch_async(dispatch_get_main_queue(), ^{
                             NSMutableArray *events = [cell.interventionEvents mutableCopy];
                             [events replaceObjectAtIndex:event.occurrenceIndexOfDay withObject:event];
                             cell.interventionEvents = events;
                         });
                     }];
    }
}

- (void)careCardTableViewCell:(OCKCareCardTableViewCell *)cell didSelectInterventionActivity:(OCKCarePlanActivity *)activity {
    NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
    OCKCarePlanActivity *selectedActivity = [self activityForIndexPath:indexPath];
    
    _lastSelectedEvent = nil;
    _lastSelectedActivity = selectedActivity;
    
    if ([self delegateCustomizesRowSelection]) {
        [self.delegate careContentsViewController:self didSelectRowWithInterventionActivity:selectedActivity];
    } else {
        [self.navigationController pushViewController:[self detailViewControllerForActivity:selectedActivity] animated:YES];
    }
}


#pragma mark - UIViewControllerPreviewingDelegate

- (UIViewController *)previewingContext:(id <UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    NSIndexPath *indexPath = [_tableView indexPathForRowAtPoint:location];
    CGRect headerFrame = [_tableView headerViewForSection:0].frame;
    
    if (indexPath &&
        !CGRectContainsPoint(headerFrame, location) &&
        ![self delegateCustomizesRowSelection]) {
        CGRect cellFrame = [_tableView cellForRowAtIndexPath:indexPath].frame;
        previewingContext.sourceRect = cellFrame;
        return [self detailViewControllerForActivity:[self activityForIndexPath:indexPath]];
    }
    
    return nil;
}

- (void)previewingContext:(id <UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    [self.navigationController pushViewController:viewControllerToCommit animated:YES];
}

@end
