//
//  OCKEvaluationTableViewController.m
//  CareKit
//
//  Created by Umer Khan on 2/2/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKEvaluationTableViewController.h"
#import "OCKEvaluation.h"
#import "OCKEvaluation_Internal.h"
#import "OCKEvaluationTableViewCell.h"
#import "OCKEvaluationTableViewHeader.h"
#import "OCKHelpers.h"


@implementation OCKEvaluationTableViewController {
    NSArray<NSArray<OCKEvaluationEvent *> *> *_evaluationEvents;
    
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
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.title = @"Evaluations";
        _store = store;
        _delegate = delegate;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.sectionHeaderHeight = 20.0;
    self.tableView.rowHeight = 85.0;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self fetchEvaluationEvents];
    [self.tableView reloadData];
}

- (void)prepareHeaderView {
    OCKEvaluationTableViewHeader *headerView = [OCKEvaluationTableViewHeader new];
    
    if (!_dateFormatter) {
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.dateFormat = @"MMMM dd, yyyy";
    }
    headerView.date = [_dateFormatter stringFromDate:[NSDate date]];
    
    NSInteger totalEvents = _evaluationEvents.count;
    NSInteger completedEvents = 0;
    for (OCKEvaluationEvent *event in _evaluationEvents) {
        if (event.evaluationValue) {
            completedEvents++;
        }
    }
    headerView.progress = completedEvents/totalEvents;
    
    self.tableView.tableHeaderView = headerView;
}

#pragma mark - Helpers

- (void)fetchEvaluationEvents {
    NSError *error;
    _evaluationEvents = [_store evaluationEventsOnDay:[NSDate date] error:&error];
    NSAssert(!error, error.localizedDescription);
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_delegate &&
        [_delegate respondsToSelector:@selector(tableViewDidSelectEvaluationEvent:)]) {
        [_delegate tableViewDidSelectEvaluationEvent:[_evaluationEvents[indexPath.row] firstObject]];
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
    OCKEvaluationTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[OCKEvaluationTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                 reuseIdentifier:CellIdentifier];
    }
    cell.evaluationEvent = [_evaluationEvents[indexPath.row] firstObject];
    return cell;
}

@end
