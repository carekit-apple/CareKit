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


#import "OCKCareCardViewController.h"
#import "OCKCareCardDetailViewController.h"
#import "OCKWeekViewController.h"
#import "OCKCareCardWeekView.h"
#import "NSDateComponents+CarePlanInternal.h"
#import "OCKCareCardTableViewHeader.h"
#import "OCKCareCardTableViewCell.h"
#import "OCKWeekViewController.h"
#import "OCKHeartView.h"
#import "OCKWeekLabelsView.h"
#import "OCKCarePlanStore_Internal.h"
#import "OCKHelpers.h"
#import "OCKDefines_Private.h"


#define RedColor() OCKColorFromRGB(0xEF445B);

@interface OCKCareCardViewController() <OCKWeekViewDelegate, OCKCarePlanStoreDelegate, OCKCareCardCellDelegate, UITableViewDelegate, UITableViewDataSource, UIPageViewControllerDelegate, UIPageViewControllerDataSource>

@property (nonatomic) NSDateComponents *selectedDate;

@end


@implementation OCKCareCardViewController {
    UITableView *_tableView;
    NSMutableArray<NSMutableArray<OCKCarePlanEvent *> *> *_events;
    NSMutableArray *_weekValues;
    OCKCareCardTableViewHeader *_headerView;
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
        self.maskImage = nil;
        self.smallMaskImage = nil;
        self.maskImageTintColor = nil;
        _showEdgeIndicators = NO;
        _calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.store.careCardUIDelegate = self;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:OCKLocalizedString(@"TODAY_BUTTON_TITLE", nil)
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(showToday:)];
    self.navigationItem.rightBarButtonItem.tintColor = self.maskImageTintColor;
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [self.view addSubview:_tableView];
    
    [self prepareView];
    
    self.selectedDate = [NSDateComponents ock_componentsWithDate:[NSDate date] calendar:_calendar];
    
    _tableView.estimatedRowHeight = 90.0;
    _tableView.rowHeight = UITableViewAutomaticDimension;
    _tableView.estimatedSectionHeaderHeight = 100.0;
    _tableView.sectionHeaderHeight = UITableViewAutomaticDimension;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSAssert(self.navigationController, @"OCKCareCardViewController must be embedded in a navigation controller.");
    
    _weekViewController.careCardWeekView.delegate = self;
}

- (void)showToday:(id)sender {
    self.selectedDate = [NSDateComponents ock_componentsWithDate:[NSDate date] calendar:_calendar];
    [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:NSNotFound inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

- (void)prepareView {
    if (!_headerView) {
        _headerView = [[OCKCareCardTableViewHeader alloc] initWithFrame:CGRectZero];
    }
    _headerView.heartView.maskImage = self.maskImage;
    _headerView.tintColor = self.maskImageTintColor;
    
    if (!_pageViewController) {
        _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                              navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                            options:nil];
        _pageViewController.dataSource = self;
        _pageViewController.delegate = self;
        
        OCKWeekViewController *weekController = [OCKWeekViewController new];
        weekController.careCardWeekView.delegate = _weekViewController.careCardWeekView.delegate;
        weekController.careCardWeekView.smallMaskImage = self.smallMaskImage;
        weekController.careCardWeekView.tintColor = self.maskImageTintColor;
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
    
    _weekViewController.careCardWeekView.selectedIndex = self.selectedDate.weekday - 1;
    
    [self fetchEvents];
}

- (void)setMaskImage:(UIImage *)maskImage {
    _maskImage = maskImage;
    if (!_maskImage) {
        _maskImage = [UIImage imageNamed:@"heart" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    }
    _headerView.heartView.maskImage = _maskImage;
}

- (void)setSmallMaskImage:(UIImage *)smallMaskImage {
    _smallMaskImage = smallMaskImage;
    if (!_smallMaskImage) {
        _smallMaskImage = [UIImage imageNamed:@"heart-small" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    }
    _weekViewController.careCardWeekView.smallMaskImage = _smallMaskImage;
}

- (void)setMaskImageTintColor:(UIColor *)maskImageTintColor {
    _maskImageTintColor = maskImageTintColor;
    if (!_maskImageTintColor) {
        _maskImageTintColor = RedColor();
    }
    
    _weekViewController.careCardWeekView.tintColor = _maskImageTintColor;
    _headerView.tintColor = _maskImageTintColor;
    self.navigationItem.rightBarButtonItem.tintColor = _maskImageTintColor;
}

- (void)setShowEdgeIndicators:(BOOL)showEdgeIndicators {
    _showEdgeIndicators = showEdgeIndicators;
    [_tableView reloadData];
}


#pragma mark - Helpers

- (void)fetchEvents {
    [self.store eventsOnDate:self.selectedDate
                        type:OCKCarePlanActivityTypeIntervention
                  completion:^(NSArray<NSArray<OCKCarePlanEvent *> *> * _Nonnull eventsGroupedByActivity, NSError * _Nonnull error) {
                      NSAssert(!error, error.localizedDescription);
                      dispatch_async(dispatch_get_main_queue(), ^{
                          _events = [NSMutableArray new];
                          for (NSArray<OCKCarePlanEvent *> *events in eventsGroupedByActivity) {
                              [_events addObject:[events mutableCopy]];
                          }
                          
                          if (self.delegate &&
                              [self.delegate respondsToSelector:@selector(careCardViewController:willDisplayEvents:dateComponents:)]) {
                              [self.delegate careCardViewController:self willDisplayEvents:[_events copy] dateComponents:_selectedDate];
                          }
                          
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
    NSInteger totalEvents = 0;
    NSInteger completedEvents = 0;
    for (NSArray<OCKCarePlanEvent* > *events in _events) {
        totalEvents += events.count;
        for (OCKCarePlanEvent *event in events) {
            if (event.state == OCKCarePlanEventStateCompleted) {
                completedEvents++;
            }
        }
    }
    
    float value = (totalEvents > 0) ? (float)completedEvents/totalEvents : 1;
    _headerView.value = value;
    
    NSInteger selectedIndex = _weekViewController.careCardWeekView.selectedIndex;
    [_weekValues replaceObjectAtIndex:selectedIndex withObject:@(value)];
    _weekViewController.careCardWeekView.values = _weekValues;
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
    
    [self.store dailyCompletionStatusWithType:OCKCarePlanActivityTypeIntervention
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
                                              _weekViewController.careCardWeekView.values = values;
                                              _weekValues = [values mutableCopy];
                                          });
                                      }];
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


#pragma mark - OCKWeekViewDelegate

- (void)weekViewSelectionDidChange:(UIView *)weekView {
    OCKCareCardWeekView *careCardWeekView = (OCKCareCardWeekView *)weekView;
    NSDateComponents *selectedDate = [self dateFromSelectedIndex:careCardWeekView.selectedIndex];
    self.selectedDate = selectedDate;
}

- (BOOL)weekViewCanSelectDayAtIndex:(NSUInteger)index {
    NSDateComponents *today = [self today];
    NSDateComponents *selectedDate = [self dateFromSelectedIndex:index];
    return ![selectedDate isLaterThan:today];
}


#pragma mark - OCKCareCardCellDelegate

- (void)careCardTableViewCell:(OCKCareCardTableViewCell *)cell didUpdateFrequencyofInterventionEvent:(OCKCarePlanEvent *)event {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(careCardViewController:didSelectButtonWithInterventionEvent:)]) {
        [self.delegate careCardViewController:self didSelectButtonWithInterventionEvent:event];
    }
    
    BOOL shouldHandleEventCompletion = YES;
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(careCardViewController:shouldHandleEventCompletionForActivity:)]) {
        shouldHandleEventCompletion = [self.delegate careCardViewController:self shouldHandleEventCompletionForActivity:event.activity];
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
                             cell.showEdgeIndicator = cell.showEdgeIndicator;
                         });
                     }];
    }
}


#pragma mark - OCKCarePlanStoreDelegate

- (void)carePlanStore:(OCKCarePlanStore *)store didReceiveUpdateOfEvent:(OCKCarePlanEvent *)event {
    for (NSMutableArray<OCKCarePlanEvent *> *events in _events) {
        if ([events.firstObject.activity.identifier isEqualToString:event.activity.identifier]) {
            if (events[event.occurrenceIndexOfDay].numberOfDaysSinceStart == event.numberOfDaysSinceStart) {
                [events replaceObjectAtIndex:event.occurrenceIndexOfDay withObject:event];
                [self updateHeaderView];
                
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_events indexOfObject:events] inSection:0];
                OCKCareCardTableViewCell *cell = [_tableView cellForRowAtIndexPath:indexPath];
                cell.interventionEvents = events;
                cell.showEdgeIndicator = cell.showEdgeIndicator;
            }
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
        controller.careCardWeekView.delegate = _weekViewController.careCardWeekView.delegate;
        
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
    controller.careCardWeekView.smallMaskImage = self.smallMaskImage;
    controller.careCardWeekView.tintColor = self.maskImageTintColor;
    return controller;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    OCKWeekViewController *controller = [OCKWeekViewController new];
    controller.weekIndex = ((OCKWeekViewController *)viewController).weekIndex + 1;
    controller.careCardWeekView.smallMaskImage = self.smallMaskImage;
    controller.careCardWeekView.tintColor = self.maskImageTintColor;
    return (![self.selectedDate isInSameWeekAsDate:[self today]]) ? controller : nil;
}


#pragma mark - UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return _headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    OCKCarePlanActivity *selectedActivity = _events[indexPath.row].firstObject.activity;
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(careCardViewController:didSelectRowWithInterventionActivity:)]) {
        [self.delegate careCardViewController:self didSelectRowWithInterventionActivity:selectedActivity];
    } else {
        OCKCareCardDetailViewController *detailViewController = [[OCKCareCardDetailViewController alloc] initWithIntervention:selectedActivity];
        detailViewController.showEdgeIndicator = self.showEdgeIndicators;
        [self.navigationController pushViewController:detailViewController animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _events.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CareCardCell";
    OCKCareCardTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[OCKCareCardTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                               reuseIdentifier:CellIdentifier];
    }
    cell.interventionEvents = _events[indexPath.row];
    cell.delegate = self;
    cell.showEdgeIndicator = self.showEdgeIndicators;
    return cell;
}

@end
