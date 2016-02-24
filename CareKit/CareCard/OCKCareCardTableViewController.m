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
#import "OCKHeartView.h"
#import "OCKCarePlanDay.h"


static const CGFloat CellHeight = 90.0;
static const CGFloat HeaderViewHeight = 235.0;

@implementation OCKCareCardTableViewController {
    NSArray<NSArray<OCKCarePlanEvent *> *> *_treatmentEvents;
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
                 _treatmentEvents = [eventsGroupedByActivity copy];
                
                 [self updateHeaderView];
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
    
    _headerView.adherence = (totalEvents > 0) ? (float)completedEvents/totalEvents : 0;
}

- (OCKCarePlanDay *)dateFromSelectedIndex:(NSInteger)index {
    NSDate *oldDate = [self dateFromCarePlanDay:_selectedDate];
    
    NSDateComponents* components = [[NSCalendar currentCalendar] components:NSCalendarUnitWeekday | NSCalendarUnitWeekOfMonth | NSCalendarUnitYear | NSCalendarUnitMonth
                                                                   fromDate:oldDate];
    
    NSDateComponents *newComponents = [NSDateComponents new];
    newComponents.year = components.year;
    newComponents.month = components.month;
    newComponents.weekOfMonth = components.weekOfMonth;
    newComponents.weekday = index;

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
    [self fetchTreatmentEvents];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return tableView.rowHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return _headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return HeaderViewHeight;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section {
    return HeaderViewHeight;
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
