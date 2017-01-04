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


#import "OCKSymptomTrackerViewController.h"
#import "OCKWeekViewController.h"
#import "OCKSymptomTrackerWeekView.h"
#import "NSDateComponents+CarePlanInternal.h"
#import "OCKSymptomTrackerTableViewHeader.h"
#import "OCKSymptomTrackerTableViewCell.h"
#import "OCKHeartView.h"
#import "OCKWeekLabelsView.h"
#import "OCKCarePlanStore_Internal.h"
#import "OCKHelpers.h"
#import "OCKDefines_Private.h"


@interface OCKSymptomTrackerViewController() <OCKWeekViewDelegate, OCKCarePlanStoreDelegate, UITableViewDelegate, UITableViewDataSource, UIPageViewControllerDelegate, UIPageViewControllerDataSource>

@property (nonatomic) NSDateComponents *selectedDate;

@end


@implementation OCKSymptomTrackerViewController {
    UITableView *_tableView;
    NSMutableArray<OCKCarePlanEvent *> *_events;
    NSMutableArray *_weekValues;
    OCKSymptomTrackerTableViewHeader *_headerView;
    UIPageViewController *_pageViewController;
    OCKWeekViewController *_weekViewController;
    NSCalendar *_calendar;
    NSMutableArray *_constraints;
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithCarePlanStore:(OCKCarePlanStore *)store {
    self = [super init];
    if (self) {
        _store = store;
        _showEdgeIndicators = NO;
        _calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _store.symptomTrackerUIDelegate = self;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:OCKLocalizedString(@"TODAY_BUTTON_TITLE", nil)
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(showToday:)];
    self.navigationItem.rightBarButtonItem.tintColor = self.progressRingTintColor;
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [self.view addSubview:_tableView];
    
    [self prepareView];
    
    self.selectedDate = [NSDateComponents ock_componentsWithDate:[NSDate date] calendar:_calendar];
    
    _tableView.estimatedRowHeight = 90.0;
    _tableView.rowHeight = UITableViewAutomaticDimension;
    _tableView.estimatedSectionHeaderHeight = 100;
    _tableView.sectionHeaderHeight = UITableViewAutomaticDimension;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSAssert(self.navigationController, @"OCKSymptomTrackerViewController must be embedded in a navigation controller.");
    _weekViewController.symptomTrackerWeekView.delegate = self;
}

- (void)showToday:(id)sender {
    self.selectedDate = [NSDateComponents ock_componentsWithDate:[NSDate date] calendar:_calendar];
    [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:NSNotFound inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

- (void)prepareView {
    if (!_headerView) {
        _headerView = [[OCKSymptomTrackerTableViewHeader alloc] initWithFrame:CGRectZero];
    }
    _headerView.tintColor = self.progressRingTintColor;
    
    if (!_pageViewController) {
        _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                              navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                            options:nil];
        _pageViewController.dataSource = self;
        _pageViewController.delegate = self;
        
        OCKWeekViewController *weekController = [[OCKWeekViewController alloc] initWithShowCareCardWeekView:NO];
        weekController.symptomTrackerWeekView.delegate = _weekViewController.symptomTrackerWeekView.delegate;
        weekController.symptomTrackerWeekView.tintColor = self.progressRingTintColor;
        _weekViewController = weekController;
        
        [_pageViewController setViewControllers:@[weekController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    }
    
    _tableView.tableHeaderView = _pageViewController.view;
    _tableView.tableFooterView = [UIView new];
    
    [self setUpConstraints];
}

- (void)setUpConstraints {
    [NSLayoutConstraint deactivateConstraints:_constraints];
    
    _constraints = [NSMutableArray new];
    
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _pageViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_constraints addObjectsFromArray:@[
                                        [NSLayoutConstraint constraintWithItem:_tableView
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.view
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
                                        [NSLayoutConstraint constraintWithItem:_pageViewController.view
                                                                     attribute:NSLayoutAttributeWidth
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.view
                                                                     attribute:NSLayoutAttributeWidth
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_pageViewController.view
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1.0
                                                                      constant:60.0]
                                        ]];
    
    [NSLayoutConstraint activateConstraints:_constraints];
}

- (void)setSelectedDate:(NSDateComponents *)selectedDate {
    NSDateComponents *today = [self today];
    _selectedDate = [selectedDate isLaterThan:today] ? today : selectedDate;
    
    _weekViewController.symptomTrackerWeekView.selectedIndex = self.selectedDate.weekday - 1;
    
    [self fetchEvents];
}

- (void)setProgressRingTintColor:(UIColor *)progressRingTintColor {
    _progressRingTintColor = progressRingTintColor;
    if (!_progressRingTintColor) {
        _progressRingTintColor = self.view.tintColor;
    }
    
    _weekViewController.symptomTrackerWeekView.tintColor = _progressRingTintColor;
    _headerView.tintColor = _progressRingTintColor;
    self.navigationItem.rightBarButtonItem.tintColor = _progressRingTintColor;
}

- (void)setShowEdgeIndicators:(BOOL)showEdgeIndicators {
    _showEdgeIndicators = showEdgeIndicators;
    [_tableView reloadData];
}


#pragma mark - Helpers

- (void)fetchEvents {
    __weak typeof(self) weakSelf = self;
    [_store eventsOnDate:_selectedDate
                    type:OCKCarePlanActivityTypeAssessment
              completion:^(NSArray<NSArray<OCKCarePlanEvent *> *> * _Nonnull eventsGroupedByActivity, NSError * _Nonnull error) {
                  NSAssert(!error, error.localizedDescription);
                  dispatch_async(dispatch_get_main_queue(), ^{
                      if (_delegate &&
                          [_delegate respondsToSelector:@selector(symptomTrackerViewController:willDisplayEvents:dateComponents:)]) {
                          [_delegate symptomTrackerViewController:self willDisplayEvents:[eventsGroupedByActivity copy] dateComponents:_selectedDate];
                      }
                      
                      NSMutableArray<OCKCarePlanEvent *> *allEvents = [NSMutableArray new];
                      //_events = [NSMutableArray new];
                      
                      for (NSArray<OCKCarePlanEvent *> *events in eventsGroupedByActivity) {
                          for (OCKCarePlanEvent *event in events) {
                              //[_events addObject:event];
                              
                              // Remove the temp events we created previously
                              if ([event.activity.title isEqualToString:@"Morning"] ||
                                  [event.activity.title isEqualToString:@"Noon"] ||
                                  [event.activity.title isEqualToString:@"Afternoon"] ||
                                  [event.activity.title isEqualToString:@"Evening"]) {
                                  [_store removeActivity:event.activity completion:^(BOOL success, NSError * _Nullable error) {}];
                              }
                              [allEvents addObject:event];
                          }
                      }
                      
                      NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                      [dateFormat setDateFormat:@"hh:mm a"];
                      
                      //[_events sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                      [allEvents sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                          OCKCarePlanEvent *event1 = (OCKCarePlanEvent*)obj1;
                          OCKCarePlanEvent *event2 = (OCKCarePlanEvent*)obj2;
                          
                          NSDate *date1 = [dateFormat dateFromString:event1.activity.text];
                          NSDate *date2 = [dateFormat dateFromString:event2.activity.text];
                          
                          if ([date1 compare:date2] == NSOrderedAscending) {
                              return NSOrderedAscending;
                          } else {
                              return NSOrderedDescending;
                          }
                      }];
                      
                      
                      // TODO: Check if works
                      // TODO: Need to create a map of info and then when all the user info has
                      // been inserted, then create the care plan activity
                      NSMutableDictionary *tempUserInfo = [NSMutableDictionary new];
                      
                      // Start the current date and index to invalid values
                      NSDate *currDate = nil;
                      OCKCarePlanEvent *currEvent = nil;
                      int timeIndex = -1;
                      
                      // Get tint color
                      int hexColor = 0x7ec2b7;
                      UIColor *eventColor = [[UIColor alloc] initWithRed:((hexColor >> 16) & 0xff)/255.0 green:((hexColor >> 8) & 0xff)/255.0 blue:(hexColor & 0xff)/255.0 alpha:1.0];
                      
                      for (OCKCarePlanEvent *event in allEvents) {
                          NSDate *tempDate = [dateFormat dateFromString:event.activity.text];
                          currEvent = event;
                          
                          if ([tempDate isEqual:currDate]) {
                              // Modify user info to include other events at the same time of day
                              NSMutableArray *tempDictArray = [[NSMutableArray alloc] initWithArray:[tempUserInfo valueForKey:@"events"]];
                              [tempDictArray addObject:event];
                              [tempUserInfo setValue:tempDictArray forKey:@"events"];
                          } else {
                              // Set new date and insert new event
                              currDate = tempDate;
                              
                              // Add activity to store
                              if (timeIndex >= 0) {
                                  [weakSelf addActivityToStore:timeIndex dict:tempUserInfo color:eventColor schedule:event.activity.schedule];
                              }
                              
                              // Set new date and insert new event
                              timeIndex++;
                              
                              // Start user info dictionary
                              NSMutableArray *tempDictArray = [NSMutableArray new];
                              [tempDictArray addObject:event];
                              [tempUserInfo setObject:tempDictArray forKey:@"events"];
                          }
                      }
                      
                      if (timeIndex >= 0) {
                          [weakSelf addActivityToStore:timeIndex dict:tempUserInfo color:eventColor schedule:currEvent.activity.schedule];
                      }
                      
                      [weakSelf fetchCreatedEvents];
                  });
              }];
}

- (void)addActivityToStore:(int) timeIndex dict:(NSMutableDictionary*) userInfo color:(UIColor*) eventColor schedule:(OCKCareSchedule*)schedule {
    NSString *eventId = @"";
    
    // Get event id
    switch (timeIndex) {
        case 0:
            eventId = @"Morning";
            break;
        case 1:
            eventId = @"Noon";
            break;
        case 2:
            eventId = @"Afternoon";
            break;
        case 3:
            eventId = @"Evening";
            break;
        default:
            break;
    }
    
    // Set up the activity
    OCKCarePlanActivity *tempActivity = [OCKCarePlanActivity assessmentWithIdentifier:eventId groupIdentifier:@"Measurement" title:eventId text:eventId tintColor:eventColor resultResettable:NO schedule:schedule userInfo: userInfo];
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    [_store addActivity:tempActivity completion:^(BOOL success, NSError * _Nullable error) {
        if (!success) {
            [NSException raise:@"CarePlanStore Error" format:@"Failed to save activity"];
        }
        dispatch_group_leave(group);
    }];
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
}

- (void)fetchCreatedEvents {
    [_store eventsOnDate:_selectedDate
                    type:OCKCarePlanActivityTypeAssessment
              completion:^(NSArray<NSArray<OCKCarePlanEvent *> *> * _Nonnull eventsGroupedByActivity, NSError * _Nonnull error) {
                  NSAssert(!error, error.localizedDescription);
                  dispatch_async(dispatch_get_main_queue(), ^{
                      if (_delegate &&
                          [_delegate respondsToSelector:@selector(symptomTrackerViewController:willDisplayEvents:dateComponents:)]) {
                          [_delegate symptomTrackerViewController:self willDisplayEvents:[eventsGroupedByActivity copy] dateComponents:_selectedDate];
                      }
                      
                      NSMutableArray<OCKCarePlanEvent *> *allEvents = [NSMutableArray new];
                      
                      for (NSArray<OCKCarePlanEvent *> *events in eventsGroupedByActivity) {
                          for (OCKCarePlanEvent *event in events) {
                              // Add only the temp events we created previously
                              if ([event.activity.title isEqualToString:@"Morning"] ||
                                  [event.activity.title isEqualToString:@"Noon"] ||
                                  [event.activity.title isEqualToString:@"Afternoon"] ||
                                  [event.activity.title isEqualToString:@"Evening"]) {
                                  [allEvents addObject:event];
                              }
                          }
                      }
                      
                      NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                      [dateFormat setDateFormat:@"hh:mm a"];
                      
                      [allEvents sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                          OCKCarePlanEvent *event1 = (OCKCarePlanEvent*)obj1;
                          OCKCarePlanEvent *event2 = (OCKCarePlanEvent*)obj2;
                          
                          NSDate *date1 = [dateFormat dateFromString:event1.activity.text];
                          NSDate *date2 = [dateFormat dateFromString:event2.activity.text];
                          
                          if ([date1 compare:date2] == NSOrderedAscending) {
                              return NSOrderedAscending;
                          } else {
                              return NSOrderedDescending;
                          }
                      }];
                      
                      _events = allEvents;
                      
                      [self updateHeaderView];
                      [self updateWeekView];
                      [_tableView reloadData];
                  });
              }];
}

- (void)updateHeaderView {
    _headerView.date = [NSDateFormatter localizedStringFromDate:[_calendar dateFromComponents:self.selectedDate]
                                                      dateStyle:NSDateFormatterLongStyle
                                                      timeStyle:NSDateFormatterNoStyle];
    
    NSInteger totalEvents = _events.count;
    NSInteger completedEvents = 0;
    for (OCKCarePlanEvent *event in _events) {
        if (event.state == OCKCarePlanEventStateCompleted) {
            completedEvents++;
        }
    }
    
    float progress = (totalEvents > 0) ? (float)completedEvents/totalEvents : 1;
    _headerView.value = progress;
    
    NSInteger selectedIndex = _weekViewController.symptomTrackerWeekView.selectedIndex;
    [_weekValues replaceObjectAtIndex:selectedIndex withObject:@(progress)];
    _weekViewController.symptomTrackerWeekView.values = _weekValues;
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
    
    [_store dailyCompletionStatusWithType:OCKCarePlanActivityTypeAssessment
                                startDate:[NSDateComponents ock_componentsWithDate:startOfWeek calendar:_calendar]
                                  endDate:[NSDateComponents ock_componentsWithDate:endOfWeek calendar:_calendar]
                                  handler:^(NSDateComponents * _Nonnull date, NSUInteger completedEvents, NSUInteger totalEvents) {
                                      if ([date isLaterThan:[self today]]) {
                                          [values addObject:@(0)];
                                      } else if (totalEvents == 0) {
                                          [values addObject:@(1)];
                                      } else {
                                          [values addObject:@((float)completedEvents/totalEvents)];
                                      }
                                  } completion:^(BOOL completed, NSError * _Nullable error) {
                                      NSAssert(!error, error.localizedDescription);
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          _weekViewController.symptomTrackerWeekView.values = values;
                                          _weekValues = [values mutableCopy];
                                      });
                                  }];
    
}

- (NSDateComponents *)dateFromSelectedIndex:(NSInteger)index {
    NSDateComponents *newComponents = [NSDateComponents new];
    newComponents.year = _selectedDate.year;
    newComponents.month = _selectedDate.month;
    newComponents.weekOfMonth = _selectedDate.weekOfMonth;
    newComponents.weekday = index + 1;
    
    NSDate *newDate = [_calendar dateFromComponents:newComponents];
    return [NSDateComponents ock_componentsWithDate:newDate calendar:_calendar];
}

- (NSDateComponents *)today {
    return [NSDateComponents ock_componentsWithDate:[NSDate date] calendar:_calendar];
}


#pragma mark - OCKWeekViewDelegate

- (void)weekViewSelectionDidChange:(UIView *)weekView {
    OCKSymptomTrackerWeekView *progressCardWeekView = (OCKSymptomTrackerWeekView *)weekView;
    NSDateComponents *selectedDate = [self dateFromSelectedIndex:progressCardWeekView.selectedIndex];
    self.selectedDate = selectedDate;
}

- (BOOL)weekViewCanSelectDayAtIndex:(NSUInteger)index {
    NSDateComponents *today = [self today];
    NSDateComponents *selectedDate = [self dateFromSelectedIndex:index];
    return ![selectedDate isLaterThan:today];
}


#pragma mark - OCKCarePlanStoreDelegate

- (void)carePlanStore:(OCKCarePlanStore *)store didReceiveUpdateOfEvent:(OCKCarePlanEvent *)event {
    for (int i = 0; i < _events.count; i++) {
        OCKCarePlanEvent *eventInArray = _events[i];
        if ([eventInArray.activity isEqual:event.activity] &&
            (eventInArray.numberOfDaysSinceStart == event.numberOfDaysSinceStart) &&
            (eventInArray.occurrenceIndexOfDay == event.occurrenceIndexOfDay)) {
            [_events replaceObjectAtIndex:i withObject:event];
            [self updateHeaderView];
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            OCKSymptomTrackerTableViewCell *cell = [_tableView cellForRowAtIndexPath:indexPath];
            cell.assessmentEvent = event;
            cell.showEdgeIndicator = cell.showEdgeIndicator;
            break;
        }
    }
}

- (void)carePlanStoreActivityListDidChange:(OCKCarePlanStore *)store {
    [self fetchEvents];
}


#pragma mark - UIPageViewControllerDelegate

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed {
    if (completed) {
        OCKWeekViewController *controller = (OCKWeekViewController *)pageViewController.viewControllers.firstObject;
        controller.symptomTrackerWeekView.delegate = _weekViewController.symptomTrackerWeekView.delegate;
        
        NSDateComponents *components = [NSDateComponents new];
        components.day = (controller.weekIndex > _weekViewController.weekIndex) ? 7 : -7;
        NSDate *newDate = [_calendar dateByAddingComponents:components toDate:[_calendar dateFromComponents:self.selectedDate] options:0];
        
        _weekViewController = controller;
        self.selectedDate = [NSDateComponents ock_componentsWithDate:newDate calendar:_calendar];
    }
}


#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    OCKWeekViewController *controller = [[OCKWeekViewController alloc] initWithShowCareCardWeekView:NO];
    controller.weekIndex = ((OCKWeekViewController *)viewController).weekIndex - 1;
    controller.symptomTrackerWeekView.tintColor = self.progressRingTintColor;
    return controller;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    OCKWeekViewController *controller = [[OCKWeekViewController alloc] initWithShowCareCardWeekView:NO];
    controller.weekIndex = ((OCKWeekViewController *)viewController).weekIndex + 1;
    controller.symptomTrackerWeekView.tintColor = self.progressRingTintColor;
    return (![self.selectedDate isInSameWeekAsDate:[self today]]) ? controller : nil;
}


#pragma mark - UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return _headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    OCKCarePlanEvent *selectedEvent = _events[indexPath.row];
    _lastSelectedAssessmentEvent = selectedEvent;
    
    if (_delegate &&
        [_delegate respondsToSelector:@selector(symptomTrackerViewController:didSelectRowWithAssessmentEvent:)]) {
        [_delegate symptomTrackerViewController:self didSelectRowWithAssessmentEvent:selectedEvent];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _events.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"SymptomTrackerCell";
    OCKSymptomTrackerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[OCKSymptomTrackerTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                     reuseIdentifier:CellIdentifier];
    }
    cell.assessmentEvent = _events[indexPath.row];
    cell.showEdgeIndicator = self.showEdgeIndicators;
    cell.userInteractionEnabled = true;
    
    // ADDED
    // Disable any rows that are too far into the future (>1 hour)
    
    unsigned int allFlags = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitYear;
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSInteger eventDay = cell.assessmentEvent.date.day;
    NSInteger currentDay = [calendar component:NSCalendarUnitDay fromDate:[NSDate date]];
    
    if (eventDay != currentDay) {
        if (cell.assessmentEvent.state == OCKCarePlanEventStateCompleted) {
            cell.userInteractionEnabled = false;
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        return cell; // Return the cell now if the date isn't today
        
    } else if (cell.assessmentEvent.activity.userInfo[@"task-time"] != nil) {
        
        // If the date is today, limit the time at which you can take a measurement so people don't do it too early
        
        // Get the current date and its components
        NSDate *currentDate = [NSDate date];
        NSDateComponents* currentDateComponents = [calendar components:allFlags fromDate:currentDate];
        
        // Fix the task date to keep the tim, but match the date of the current date
        NSDate *taskDate = (NSDate*) cell.assessmentEvent.activity.userInfo[@"task-time"];
        NSDateComponents* taskComponents = [calendar components:allFlags fromDate:taskDate];
        taskComponents.year = currentDateComponents.year;
        taskComponents.month = currentDateComponents.month;
        taskComponents.day = currentDateComponents.day;
        taskComponents.hour -= 1;
        if (taskComponents.hour < 0) { taskComponents.hour = 23; taskComponents.day -= 1; }
        NSDate* fixedTaskDate = [calendar dateFromComponents:taskComponents];
        
        // Disable any tasks that are in the future
        NSComparisonResult result = [currentDate compare:fixedTaskDate];
        if (result == NSOrderedAscending) {
            cell.userInteractionEnabled = false;
            cell.accessoryType = UITableViewCellAccessoryNone;
        } else if(result == NSOrderedDescending) {
            cell.userInteractionEnabled = true;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else {
            cell.userInteractionEnabled = true;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    
    return cell;
}

@end
