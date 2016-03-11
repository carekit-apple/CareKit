//
//  OCKEvaluationTableViewController.m
//  CareKit
//
//  Created by Umer Khan on 2/2/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKEvaluationTableViewController.h"
#import "OCKEvaluationTableViewCell.h"
#import "OCKEvaluationTableViewHeader.h"
#import "OCKHelpers.h"
#import "OCKCarePlanStore_Internal.h"
#import "OCKWeekViewController.h"
#import "OCKEvaluationWeekView.h"
#import "OCKWeekView.h"
#import "NSDateComponents+CarePlanInternal.h"


const static CGFloat CellHeight = 85.0;
const static CGFloat HeaderViewHeight = 150.0;

@implementation OCKEvaluationTableViewController {
    NSMutableArray<NSMutableArray<OCKCarePlanEvent *> *> *_evaluationEvents;
    NSMutableArray *_weeklyProgress;
    OCKEvaluationTableViewHeader *_headerView;
    UIPageViewController *_pageViewController;
    NSCalendar *_calendar;
}

+ (instancetype)new {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithCarePlanStore:(OCKCarePlanStore *)store
                             delegate:(id<OCKEvaluationTableViewDelegate>)delegate {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _store = store;
        _delegate = delegate;
        _lastSelectedEvaluationEvent = nil;
        _store.checkupsUIDelegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self prepareView];
    
    _calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    
    self.selectedDate = [[NSDateComponents alloc] initWithDate:[NSDate date]
                                                      calendar:_calendar];
    
    self.tableView.rowHeight = CellHeight;
}

- (void)prepareView {
    if (!_headerView) {
        _headerView = [[OCKEvaluationTableViewHeader alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, HeaderViewHeight)];
    }
    [self updateHeaderView];
    
    if (!_pageViewController) {
        _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                              navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                            options:nil];
        _pageViewController.dataSource = self;
        _pageViewController.delegate = self;
        _pageViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, 60.0);
        
        OCKWeekViewController *weekController = [OCKWeekViewController new];
        
        id delegate = _weekViewController.evaluationWeekView.delegate;
        _weekViewController = weekController;
        _weekViewController.showCareCardWeekView = NO;
        _weekViewController.evaluationWeekView.delegate = delegate;
        
        [_pageViewController setViewControllers:@[weekController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    }
    
    self.tableView.tableHeaderView = _pageViewController.view;
    self.tableView.tableFooterView = [UIView new];
}

- (void)setSelectedDate:(NSDateComponents *)selectedDate {
    _selectedDate = selectedDate;
    NSDateComponents *today = [[NSDateComponents alloc] initWithDate:[NSDate date] calendar:_calendar];
    if ([_selectedDate isLaterThan:today]) {
        _selectedDate = today;
    }
    
    NSDateComponents *components = [_calendar components:NSCalendarUnitWeekday fromDate:[_selectedDate dateWithCalendar:_calendar]];
    _weekViewController.evaluationWeekView.selectedIndex = components.weekday-1;
    
    [self fetchEvaluationEvents];
}


#pragma mark - Helpers

- (void)fetchEvaluationEvents {
    [_store eventsOnDate:_selectedDate
                   type:OCKCarePlanActivityTypeAssessment
             completion:^(NSArray<NSArray<OCKCarePlanEvent *> *> * _Nonnull eventsGroupedByActivity, NSError * _Nonnull error) {
                 NSAssert(!error, error.localizedDescription);
                 
                 _evaluationEvents = [NSMutableArray new];
                 for (NSArray<OCKCarePlanEvent *> *events in eventsGroupedByActivity) {
                     [_evaluationEvents addObject:[events mutableCopy]];
                 }

                 [self updateHeaderView];
                 [self updateWeekView];
                 [self.tableView reloadData];
             }];
}

- (void)updateHeaderView {
    _headerView.date = [NSDateFormatter localizedStringFromDate:[_selectedDate dateWithCalendar:_calendar]
                                                      dateStyle:NSDateFormatterLongStyle
                                                      timeStyle:NSDateFormatterNoStyle];
    
    NSInteger totalEvents = _evaluationEvents.count;
    NSInteger completedEvents = 0;
    for (NSArray<OCKCarePlanEvent *> *events in _evaluationEvents) {
        OCKCarePlanEvent *evaluationEvent = events.firstObject;
        if (evaluationEvent.state == OCKCarePlanEventStateCompleted) {
            completedEvents++;
        }
    }
    
    float progress = (totalEvents > 0) ? (float)completedEvents/totalEvents : 1;
    _headerView.progress = progress;
    
    NSInteger selectedIndex = _weekViewController.evaluationWeekView.selectedIndex;
    [_weeklyProgress replaceObjectAtIndex:selectedIndex withObject:@(progress)];
    _weekViewController.evaluationWeekView.progressValues = _weeklyProgress;
}

- (void)updateWeekView {
    NSDate *selectedDate = [_selectedDate dateWithCalendar:_calendar];
    NSDate *startOfWeek;
    NSTimeInterval interval;
    [_calendar rangeOfUnit:NSCalendarUnitWeekOfMonth
                 startDate:&startOfWeek
                  interval:&interval
                   forDate:selectedDate];
    NSDate *endOfWeek = [startOfWeek dateByAddingTimeInterval:interval-1];
    
    NSMutableArray *progressValues = [NSMutableArray new];
    
    [_store dailyCompletionStatusWithType:OCKCarePlanActivityTypeAssessment
                                startDate:[[NSDateComponents alloc] initWithDate:startOfWeek calendar:_calendar]
                                  endDate:[[NSDateComponents alloc] initWithDate:endOfWeek calendar:_calendar]
                               usingBlock:^(NSDateComponents * _Nonnull day, NSUInteger completed, NSUInteger total, NSError * _Nonnull error) {
                                   
                                   NSDate *currentDate = [day dateWithCalendar:_calendar];
                                   
                                   if ([currentDate compare:[NSDate date]] == NSOrderedDescending) {
                                       [progressValues addObject:@(0)];
                                   }
                                   else if (total == 0) {
                                       [progressValues addObject:@(1)];
                                   } else {
                                       [progressValues addObject:@((float)completed/total)];
                                   }
                                   
                                   if (progressValues.count == 7) {
                                       _weekViewController.evaluationWeekView.progressValues = progressValues;
                                       _weeklyProgress = [progressValues mutableCopy];
                                   }
                               }];

}

- (BOOL)selectedDateIsInCurrentWeek {
    NSDateComponents *components = [_calendar components:NSCalendarUnitWeekOfYear fromDate:[NSDate date]];
    NSUInteger currentWeek = components.weekOfYear;
    
    components = [_calendar components:NSCalendarUnitWeekOfYear fromDate:[_selectedDate dateWithCalendar:_calendar]];
    NSUInteger selectedWeek = components.weekOfYear;
    
    return (selectedWeek == currentWeek);
}

- (NSDateComponents *)dateFromSelectedIndex:(NSInteger)index {
    NSDate *oldDate = [_selectedDate dateWithCalendar:_calendar];
    
    NSDateComponents* components = [[NSCalendar currentCalendar] components:NSCalendarUnitWeekday | NSCalendarUnitWeekOfMonth | NSCalendarUnitYear | NSCalendarUnitMonth
                                                                   fromDate:oldDate];
    
    NSDateComponents *newComponents = [NSDateComponents new];
    newComponents.year = components.year;
    newComponents.month = components.month;
    newComponents.weekOfMonth = components.weekOfMonth;
    newComponents.weekday = index + 1;
    
    NSDate *newDate = [_calendar dateFromComponents:newComponents];
    return [[NSDateComponents alloc] initWithDate:newDate calendar:_calendar];
}


#pragma mark - OCKCarePlanStoreDelegate

- (void)carePlanStore:(OCKCarePlanStore *)store didReceiveUpdateOfEvent:(OCKCarePlanEvent *)event {
    // Find the index that has the right activity.
    for (NSMutableArray<OCKCarePlanEvent *> *events in _evaluationEvents) {
        // Once found, look to see if the event matches.
        if ([events.firstObject.activity.identifier isEqualToString:event.activity.identifier]) {
            
            // If the event matches, then replace it.
            if (events[event.occurrenceIndexOfDay].numberOfDaysSinceStart == event.numberOfDaysSinceStart) {
                [events replaceObjectAtIndex:event.occurrenceIndexOfDay withObject:event];
                
                [self updateHeaderView];
                
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_evaluationEvents indexOfObject:events] inSection:0];
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            }
            break;
        }
    }}

- (void)carePlanStoreEvaluationListDidChange:(OCKCarePlanStore *)store {
    [self fetchEvaluationEvents];
}


#pragma mark - UIPageViewControllerDelegate

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed {
    if (completed) {
        OCKWeekViewController *controller = (OCKWeekViewController *)pageViewController.viewControllers.firstObject;
        controller.evaluationWeekView.delegate = _weekViewController.evaluationWeekView.delegate;
        
        
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [NSDateComponents new];
        components.day = (controller.view.tag > _weekViewController.view.tag) ? 7 : -7;
        NSDate *newDate = [_calendar dateByAddingComponents:components toDate:[_selectedDate dateWithCalendar:_calendar] options:0];
        
        _weekViewController = controller;
        self.selectedDate = [[NSDateComponents alloc] initWithDate:newDate calendar:calendar];
        
        components = [[NSCalendar currentCalendar] components:NSCalendarUnitWeekday fromDate:[_selectedDate dateWithCalendar:_calendar]];
        [_weekViewController.evaluationWeekView.weekView highlightDay:components.weekday-1];
    }
}


#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    OCKWeekViewController *controller = [OCKWeekViewController new];
    controller.showCareCardWeekView = NO;
    controller.view.tag = viewController.view.tag - 1;
    return controller;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    OCKWeekViewController *controller = [OCKWeekViewController new];
    controller.showCareCardWeekView = NO;
    controller.view.tag = viewController.view.tag + 1;
    return (![self selectedDateIsInCurrentWeek]) ? controller : nil;
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return HeaderViewHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return _headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    OCKCarePlanEvent *selectedEvaluationEvent = _evaluationEvents[indexPath.row].firstObject;
    _lastSelectedEvaluationEvent = selectedEvaluationEvent;

    if (_delegate &&
        [_delegate respondsToSelector:@selector(tableViewDidSelectRowWithEvaluationEvent:)]) {
        [_delegate tableViewDidSelectRowWithEvaluationEvent:selectedEvaluationEvent];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _evaluationEvents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"EvaluationCell";
    OCKEvaluationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[OCKEvaluationTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                 reuseIdentifier:CellIdentifier];
    }
    cell.evaluationEvent = _evaluationEvents[indexPath.row].firstObject;
    return cell;
}

@end
