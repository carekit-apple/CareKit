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
#import "OCKCarePlanStore_Internal.h"


@interface OCKEvaluationTableViewController() <OCKCarePlanStoreDelegate>

@end


@implementation OCKEvaluationTableViewController {
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
    self = [super initWithStyle:UITableViewStyleGrouped];
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
    
    [self fetchEvaluationEvents];
    
    self.tableView.rowHeight = 85.0;
}

- (void)prepareHeaderView {
    if (!_headerView) {
        _headerView = [[OCKEvaluationTableViewHeader alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 200)];
    }
    
    if (!_dateFormatter) {
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.dateFormat = @"MMMM dd, yyyy";
    }
    _headerView.date = [_dateFormatter stringFromDate:[NSDate date]];
    
    NSInteger totalEvents = _evaluationEvents.count;
    NSInteger completedEvents = 0;
    for (OCKEvaluationEvent *event in _evaluationEvents) {
        if (event.evaluationValue) {
            completedEvents++;
        }
    }
    _headerView.progress = completedEvents/totalEvents;
    
    self.tableView.tableHeaderView = _headerView;
    
    [self setUpConstraints];
}

- (void)setUpConstraints {
    NSMutableArray *constraints = [NSMutableArray new];
    NSDictionary *views = NSDictionaryOfVariableBindings(_headerView);
    
    _headerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_headerView]|"
                                                                             options:NSLayoutFormatDirectionLeadingToTrailing
                                                                             metrics:nil
                                                                               views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_headerView]|"
                                                                             options:NSLayoutFormatDirectionLeadingToTrailing
                                                                             metrics:nil
                                                                               views:views]];
    
    [NSLayoutConstraint activateConstraints:constraints];
}


#pragma mark - Helpers

- (void)fetchEvaluationEvents {
    NSError *error;
    _evaluationEvents = [_store evaluationEventsOnDay:[NSDate date] error:&error];
    NSAssert(!error, error.localizedDescription);
}


#pragma mark - OCKCarePlanStoreDelegate

- (void)carePlanStore:(OCKCarePlanStore *)store didReceiveUpdateOfEvaluationEvent:(OCKEvaluationEvent *)event {
    [self carePlanStoreEvaluationListDidChange:store];
}

- (void)carePlanStoreEvaluationListDidChange:(OCKCarePlanStore *)store {
    [self fetchEvaluationEvents];
    [self.tableView reloadData];
}


#pragma mark - UITableViewDelegate

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
