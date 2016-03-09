//
//  OCKTreatmentsTableViewController.m
//  CareKit
//
//  Created by Umer Khan on 1/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKCareCardTableViewController.h"
#import "OCKCareCardTableViewHeader.h"
#import "OCKHelpers.h"
#import "OCKCarePlanActivity.h"
#import "OCKCareCardTableViewCell.h"
#import "OCKWeekViewController.h"
#import "OCKCarePlanStore_Internal.h"
#import "OCKCareCardWeekView.h"
#import "NSDateComponents+CarePlanInternal.h"
#import "OCKHeartView.h"
#import "OCKWeekView.h"


static const CGFloat CellHeight = 85.0;
static const CGFloat HeaderViewHeight = 200.0;

@implementation OCKCareCardTableViewController {
    NSMutableArray<NSMutableArray<OCKCarePlanEvent *> *> *_treatmentEvents;
    NSMutableArray *_weeklyAdherences;
    OCKCareCardTableViewHeader *_headerView;
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

- (instancetype)initWithCarePlanStore:(OCKCarePlanStore *)store {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _store = store;
        _store.careCardUIDelegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self prepareView];
    
    self.selectedDate = [[NSDateComponents alloc] initWithDate:[NSDate date] calendar:[NSCalendar currentCalendar]];

    self.tableView.rowHeight = CellHeight;
}

- (void)prepareView {
    if (!_headerView) {
        _headerView = [[OCKCareCardTableViewHeader alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, HeaderViewHeight)];
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
        
        id delegate = _weekViewController.careCardWeekView.delegate;
        _weekViewController = weekController;
        _weekViewController.careCardWeekView.delegate = delegate;
    
        [_pageViewController setViewControllers:@[weekController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    }
    
    self.tableView.tableHeaderView = _pageViewController.view;
    self.tableView.tableFooterView = [UIView new];
}

- (void)setSelectedDate:(NSDateComponents *)selectedDate {
    _selectedDate = selectedDate;
    NSDateComponents *today = [[NSDateComponents alloc] initWithDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
    if ([_selectedDate isLaterThan:today]) {
        _selectedDate = today;
    }
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitWeekday fromDate:[self dateFromCarePlanDay:_selectedDate]];
    _weekViewController.careCardWeekView.selectedIndex = components.weekday-1;
    
    [self fetchTreatmentEvents];
}


#pragma mark - Helpers

- (void)fetchTreatmentEvents {
    [_store eventsOnDate:_selectedDate
                   type:OCKCarePlanActivityTypeIntervention
             completion:^(NSArray<NSArray<OCKCarePlanEvent *> *> * _Nonnull eventsGroupedByActivity, NSError * _Nonnull error) {
                 NSAssert(!error, error.localizedDescription);
                
                 _treatmentEvents = [NSMutableArray new];
                 for (NSArray<OCKCarePlanEvent *> *events in eventsGroupedByActivity) {
                     [_treatmentEvents addObject:[events mutableCopy]];
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
    NSInteger totalEvents = 0;
    NSInteger completedEvents = 0;
    for (NSArray<OCKCarePlanEvent* > *events in _treatmentEvents) {
        totalEvents += events.count;
        for (OCKCarePlanEvent *event in events) {
            if (event.state == OCKCarePlanEventStateCompleted) {
                completedEvents++;
            }
        }
    }

    float adherence = (totalEvents > 0) ? (float)completedEvents/totalEvents : 1;
    _headerView.adherence = adherence;

    NSInteger selectedIndex = _weekViewController.careCardWeekView.selectedIndex;
    [_weeklyAdherences replaceObjectAtIndex:selectedIndex withObject:@(adherence)];
    _weekViewController.careCardWeekView.adherenceValues = _weeklyAdherences;
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
    
    NSMutableArray *adherenceValues = [NSMutableArray new];
        
    [_store dailyCompletionStatusWithType:OCKCarePlanActivityTypeIntervention
                                 startDate:[[NSDateComponents alloc] initWithDate:startOfWeek calendar:calendar]
                                   endDate:[[NSDateComponents alloc] initWithDate:endOfWeek calendar:calendar]
                               usingBlock:^(NSDateComponents * _Nonnull day, NSUInteger completed, NSUInteger total, NSError * _Nonnull error) {
                                   
                                   // TODO: Logic to compare today and set value accordingly.
                                   
                                   if (total == 0) {
                                       [adherenceValues addObject:@(1)];
                                   } else {
                                       [adherenceValues addObject:@((float)completed/total)];
                                   }
                                   
                                   if (adherenceValues.count == 7) {
                                       _weekViewController.careCardWeekView.adherenceValues = adherenceValues;
                                       _weeklyAdherences = [adherenceValues mutableCopy];
                                   }
                               }];
    
    
}

- (NSDateComponents *)dateFromSelectedIndex:(NSInteger)index {
    NSDate *oldDate = [self dateFromCarePlanDay:_selectedDate];
    
    NSDateComponents* components = [[NSCalendar currentCalendar] components:NSCalendarUnitWeekday | NSCalendarUnitWeekOfMonth | NSCalendarUnitYear | NSCalendarUnitMonth
                                                                   fromDate:oldDate];
    
    NSDateComponents *newComponents = [NSDateComponents new];
    newComponents.year = components.year;
    newComponents.month = components.month;
    newComponents.weekOfMonth = components.weekOfMonth;
    newComponents.weekday = index + 1;

    NSDate *newDate = [[NSCalendar currentCalendar] dateFromComponents:newComponents];
    return [[NSDateComponents alloc] initWithDate:newDate calendar:[NSCalendar currentCalendar]];
}

- (NSDate *)dateFromCarePlanDay:(NSDateComponents *)day {
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


#pragma mark - OCKCareCardCellDelegate

- (void)careCardCellDidUpdateFrequency:(OCKCareCardTableViewCell *)cell ofTreatmentEvent:(OCKCarePlanEvent *)event {
    // Update the treatment event and mark it as completed.
    OCKCarePlanEventState state = (event.state == OCKCarePlanEventStateCompleted) ? OCKCarePlanEventStateNotCompleted : OCKCarePlanEventStateCompleted;

    [_store updateEvent:event
             withResult:nil
                  state:state
             completion:^(BOOL success, OCKCarePlanEvent * _Nonnull event, NSError * _Nonnull error) {
                 NSAssert(success, error.localizedDescription);
             }];
}


#pragma mark - OCKCarePlanStoreDelegate

- (void)carePlanStore:(OCKCarePlanStore *)store didReceiveUpdateOfEvent:(OCKCarePlanEvent *)event {
    // Find the index that has the right activity.
    for (NSMutableArray<OCKCarePlanEvent *> *events in _treatmentEvents) {
        // Once found, look to see if the event matches.
        if ([events.firstObject.activity.identifier isEqualToString:event.activity.identifier]) {
            
            // If the event matches, then replace it.
            if (events[event.occurrenceIndexOfDay].numberOfDaysSinceStart == event.numberOfDaysSinceStart) {
                [events replaceObjectAtIndex:event.occurrenceIndexOfDay withObject:event];

                [self updateHeaderView];
                
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_treatmentEvents indexOfObject:events] inSection:0];
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            }
            break;
        }
    }
}

- (void)carePlanStoreTreatmentListDidChange:(OCKCarePlanStore *)store {
    [self fetchTreatmentEvents];
}


#pragma mark - UIPageViewControllerDelegate

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed {
    if (completed) {
        OCKWeekViewController *controller = (OCKWeekViewController *)pageViewController.viewControllers.firstObject;
        controller.careCardWeekView.delegate = _weekViewController.careCardWeekView.delegate;
        
        
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [NSDateComponents new];
        components.day = (controller.view.tag > _weekViewController.view.tag) ? 7 : -7;
        NSDate *newDate = [calendar dateByAddingComponents:components toDate:[self dateFromCarePlanDay:_selectedDate] options:0];
        
        _weekViewController = controller;
        self.selectedDate = [[NSDateComponents alloc] initWithDate:newDate calendar:calendar];
        
        components = [[NSCalendar currentCalendar] components:NSCalendarUnitWeekday fromDate:[self dateFromCarePlanDay:_selectedDate]];
        [_weekViewController.careCardWeekView.weekView highlightDay:components.weekday-1];
    }
}


#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    OCKWeekViewController *controller = [OCKWeekViewController new];
    controller.view.tag = viewController.view.tag - 1;
    return controller;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    OCKWeekViewController *controller = [OCKWeekViewController new];
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
    OCKCarePlanActivity *selectedActivity = _treatmentEvents[indexPath.row].firstObject.activity;
    
    if (_delegate &&
        [_delegate respondsToSelector:@selector(tableViewDidSelectRowWithTreatment:)]) {
        [_delegate tableViewDidSelectRowWithTreatment:selectedActivity];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _treatmentEvents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CareCardCell";
    OCKCareCardTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[OCKCareCardTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                               reuseIdentifier:CellIdentifier];
    }
    cell.treatmentEvents = _treatmentEvents[indexPath.row];
    cell.delegate = self;
    return cell;

}

@end
