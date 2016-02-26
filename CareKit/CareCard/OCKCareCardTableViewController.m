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
#import "OCKWeekPageViewController.h"
#import "OCKCarePlanStore_Internal.h"
#import "OCKCareCardWeekView.h"
#import "OCKCarePlanDay.h"
#import "OCKHeartView.h"


static const CGFloat CellHeight = 90.0;
static const CGFloat HeaderViewHeight = 235.0;

@implementation OCKCareCardTableViewController {
    NSMutableArray<NSMutableArray<OCKCarePlanEvent *> *> *_treatmentEvents;
    NSMutableArray *_weeklyAdherences;
    OCKCareCardTableViewHeader *_headerView;
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
        self.title = @"CareCard";
        _store = store;
        _store.careCardUIDelegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _selectedDate = [[OCKCarePlanDay alloc] initWithDate:[NSDate date] calendar:[NSCalendar currentCalendar]];

    self.tableView.rowHeight = CellHeight;
    self.tableView.sectionHeaderHeight = HeaderViewHeight;
    
    [self fetchTreatmentEvents];
    [self prepareView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    OCKCarePlanDay *newDate = [[OCKCarePlanDay alloc] initWithDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
    
    if ([newDate isLaterThan:_selectedDate]) {
        _selectedDate = newDate;
    }
}

- (void)prepareView {
    if (!_headerView) {
        _headerView = [[OCKCareCardTableViewHeader alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, HeaderViewHeight)];
    }
    [self updateHeaderView];
    
    _weekPageViewController = [[OCKWeekPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                                   navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                                 options:nil];
    _weekPageViewController.dataSource = self;
    _weekPageViewController.showCareCardWeekView = YES;
    self.tableView.tableHeaderView = _weekPageViewController.view;
    self.tableView.tableFooterView = [UIView new];
}

- (void)setSelectedDate:(OCKCarePlanDay *)selectedDate {
    _selectedDate = selectedDate;
    
    [self fetchTreatmentEvents];
}


#pragma mark - Helpers

- (void)fetchTreatmentEvents {
    [_store eventsOfDay:_selectedDate
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

    float adherence = (totalEvents > 0) ? (float)completedEvents/totalEvents : 0;
    _headerView.adherence = adherence;

    // Update the week view heart for the selected index.
    NSInteger selectedIndex = _weekPageViewController.careCardWeekView.selectedIndex;
    [_weeklyAdherences replaceObjectAtIndex:selectedIndex withObject:@(adherence)];
    _weekPageViewController.careCardWeekView.adherenceValues = _weeklyAdherences;
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
                                 startDay:[[OCKCarePlanDay alloc] initWithDate:startOfWeek calendar:calendar]
                                   endDay:[[OCKCarePlanDay alloc] initWithDate:endOfWeek calendar:calendar]
                               usingBlock:^(OCKCarePlanDay * _Nonnull day, NSUInteger completed, NSUInteger total, NSError * _Nonnull error) {
                                   if (total == 0) {
                                       [adherenceValues addObject:@(1)];
                                   } else {
                                       [adherenceValues addObject:@((float)completed/total)];
                                   }
                                   if (adherenceValues.count == 7) {
                                       _weekPageViewController.careCardWeekView.adherenceValues = adherenceValues;
                                       _weeklyAdherences = [adherenceValues mutableCopy];
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
//                [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
            }
            break;
        }
    }
}

- (void)carePlanStoreTreatmentListDidChange:(OCKCarePlanStore *)store {
    [self fetchTreatmentEvents];
}


#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    // TO DO: implementation
    // Calculate the date one week before the selected date.
    
    // Set the new date as the selected date.
    
    return pageViewController;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    // TO DO: implementation
    
    // Check if the selected date is from current week, if it is then don't do anything.
    
    // Calculate the date one week after the selected date.
    
    // Set the new date as the selected date.
    
    return pageViewController;
}


#pragma mark - UITableViewDelegate

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
