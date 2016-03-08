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


const static CGFloat CellHeight = 90.0;
const static CGFloat HeaderViewHeight = 150.0;

@implementation OCKEvaluationTableViewController {
    NSMutableArray<NSMutableArray<OCKCarePlanEvent *> *> *_evaluationEvents;
    NSMutableArray *_weeklyProgress;
    OCKEvaluationTableViewHeader *_headerView;
    UIPageViewController *_pageViewController;
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
    
    self.selectedDate = [[OCKCarePlanDay alloc] initWithDate:[NSDate date]
                                                    calendar:[NSCalendar currentCalendar]];
    
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

- (void)setSelectedDate:(OCKCarePlanDay *)selectedDate {
    _selectedDate = selectedDate;
    OCKCarePlanDay *today = [[OCKCarePlanDay alloc] initWithDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
    if ([_selectedDate isLaterThan:today]) {
        _selectedDate = today;
    }
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitWeekday fromDate:[self dateFromCarePlanDay:_selectedDate]];
    _weekViewController.evaluationWeekView.selectedIndex = components.weekday-1;
    
    [self fetchEvaluationEvents];
}


#pragma mark - Helpers

- (void)fetchEvaluationEvents {
    [_store eventsOfDay:_selectedDate
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
    _headerView.date = [NSDateFormatter localizedStringFromDate:[self dateFromCarePlanDay:_selectedDate]
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
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *selectedDate = [self dateFromCarePlanDay:_selectedDate];
    NSDate *startOfWeek;
    NSTimeInterval interval;
    [calendar rangeOfUnit:NSCalendarUnitWeekOfMonth
                startDate:&startOfWeek
                 interval:&interval
                  forDate:selectedDate];
    NSDate *endOfWeek = [startOfWeek dateByAddingTimeInterval:interval-1];
    
    NSMutableArray *progressValues = [NSMutableArray new];
    
    OCKCarePlanDay *today = [[OCKCarePlanDay alloc] initWithDate:[NSDate date] calendar:calendar];
    
    [_store dailyCompletionStatusWithType:OCKCarePlanActivityTypeAssessment
                                 startDay:[[OCKCarePlanDay alloc] initWithDate:startOfWeek calendar:calendar]
                                   endDay:[[OCKCarePlanDay alloc] initWithDate:endOfWeek calendar:calendar]
                               usingBlock:^(OCKCarePlanDay * _Nonnull day, NSUInteger completed, NSUInteger total, NSError * _Nonnull error) {
                                   
                                   if ([day isLaterThan:today]) {
                                       [progressValues addObject:@(0)];
                                   } else if (total == 0) {
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

- (OCKCarePlanDay *)dateFromSelectedIndex:(NSInteger)index {
    NSDate *oldDate = [self dateFromCarePlanDay:_selectedDate];
    
    NSDateComponents* components = [[NSCalendar currentCalendar] components:NSCalendarUnitWeekday | NSCalendarUnitWeekOfMonth | NSCalendarUnitYear | NSCalendarUnitMonth
                                                                   fromDate:oldDate];
    
    NSDateComponents *newComponents = [NSDateComponents new];
    newComponents.year = components.year;
    newComponents.month = components.month;
    newComponents.weekOfMonth = components.weekOfMonth;
    newComponents.weekday = index + 1;
    
    NSDate *newDate = [[NSCalendar currentCalendar] dateFromComponents:newComponents];
    return [[OCKCarePlanDay alloc] initWithDate:newDate calendar:[NSCalendar currentCalendar]];
}

- (NSDate *)dateFromCarePlanDay:(OCKCarePlanDay *)day {
    NSDateComponents *components = [NSDateComponents new];
    components.year = _selectedDate.year;
    components.month = _selectedDate.month;
    components.day = _selectedDate.day;
    return [[NSCalendar currentCalendar] dateFromComponents:components];
}

- (BOOL)selectedDateIsInCurrentWeek {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDateComponents *components = [calendar components:NSCalendarUnitWeekOfYear fromDate:[NSDate date]];
    NSUInteger currentWeek = components.weekOfYear;
    
    components = [calendar components:NSCalendarUnitWeekOfYear fromDate:[self dateFromCarePlanDay:_selectedDate]];
    NSUInteger selectedWeek = components.weekOfYear;
    
    return (selectedWeek == currentWeek);
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
        NSDate *newDate = [calendar dateByAddingComponents:components toDate:[self dateFromCarePlanDay:_selectedDate] options:0];
        
        _weekViewController = controller;
        self.selectedDate = [[OCKCarePlanDay alloc] initWithDate:newDate calendar:calendar];
        
        components = [[NSCalendar currentCalendar] components:NSCalendarUnitWeekday fromDate:[self dateFromCarePlanDay:_selectedDate]];
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
