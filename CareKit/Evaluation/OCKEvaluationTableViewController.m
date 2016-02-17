//
//  OCKEvaluationTableViewController.m
//  CareKit
//
//  Created by Umer Khan on 2/2/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKEvaluationTableViewController.h"
#import "OCKEvaluationTableViewController_Internal.h"
#import "OCKEvaluation.h"
#import "OCKEvaluation_Internal.h"
#import "OCKEvaluationTableViewCell.h"
#import "OCKEvaluationTableViewHeader.h"
#import "OCKHelpers.h"
#import "OCKCarePlanStore_Internal.h"
#import "OCKWeekPageViewController.h"


const static CGFloat CellHeight = 85.0;
const static CGFloat HeaderViewHeight = 100.0;


@implementation OCKEvaluationTableViewController {
    OCKWeekPageViewController *_weekPageViewController;
    NSArray<NSArray<OCKEvaluationEvent *> *> *_evaluationEvents;
    OCKEvaluationTableViewHeader *_headerView;
    NSDateFormatter *_dateFormatter;
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
        self.title = @"Evaluations";
        _store = store;
        _delegate = delegate;
        _lastSelectedEvaluationEvent = nil;
        _store.evaluationUIDelegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _selectedDate = [NSDate date];
    
    [self fetchEvaluationEvents];
    [self prepareView];
}

- (void)prepareView {
    if (!_headerView) {
        _headerView = [[OCKEvaluationTableViewHeader alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, HeaderViewHeight)];
    }
    [self updateHeaderView];
    
    _weekPageViewController = [[OCKWeekPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                                   navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                                 options:nil];
    self.tableView.tableHeaderView = _weekPageViewController.view;
    self.tableView.tableFooterView = [UIView new];

}

- (void)setSelectedDate:(NSDate *)selectedDate {
    _selectedDate = selectedDate;

    [self fetchEvaluationEvents];
}

#pragma mark - Helpers

- (void)fetchEvaluationEvents {
    NSError *error;
    _evaluationEvents = [_store evaluationEventsOnDay:_selectedDate error:&error];
    NSAssert(!error, error.localizedDescription);
    
    [self updateHeaderView];
    [self.tableView reloadData];
}

- (void)updateHeaderView {
    if (!_dateFormatter) {
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.dateFormat = @"MMMM dd, yyyy";
    }
    _headerView.date = [_dateFormatter stringFromDate:_selectedDate];
    
    NSInteger totalEvents = _evaluationEvents.count;
    NSInteger completedEvents = 0;
    for (NSArray<OCKEvaluationEvent *> *events in _evaluationEvents) {
        OCKEvaluationEvent *evaluationEvent = events.firstObject;
        if (evaluationEvent.state == OCKCareEventStateCompleted) {
            completedEvents++;
        }
    }
    _headerView.progress = (totalEvents > 0) ? (float)completedEvents/totalEvents : 0;
    
    _headerView.text = [NSString stringWithFormat:@"%@ of %@", [@(completedEvents) stringValue], [@(totalEvents) stringValue]];
}

- (NSDate *)dateFromSelectedDay:(NSInteger)day {
    NSDate *referenceDate = _selectedDate;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekOfMonth | NSCalendarUnitWeekday | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:referenceDate];
    components.weekday = day;
    
    return [calendar dateFromComponents:components];
}


#pragma mark - OCKCarePlanStoreDelegate

- (void)carePlanStore:(OCKCarePlanStore *)store didReceiveUpdateOfEvaluationEvent:(OCKEvaluationEvent *)event {
    [self fetchEvaluationEvents];
}

- (void)carePlanStoreEvaluationListDidChange:(OCKCarePlanStore *)store {
    [self fetchEvaluationEvents];
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
    OCKEvaluationEvent *selectedEvaluationEvent = _evaluationEvents[indexPath.row].firstObject;
    _lastSelectedEvaluationEvent = selectedEvaluationEvent;
    
    if (_delegate &&
        [_delegate respondsToSelector:@selector(tableViewDidSelectEvaluationEvent:)]) {
        [_delegate tableViewDidSelectEvaluationEvent:selectedEvaluationEvent];
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

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
