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
#import "OCKHelpers.h"


@implementation OCKEvaluationTableViewController {
    NSArray<OCKEvaluation *> *_evaluations;
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
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.title = @"Evaluations";
        _store = store;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self fetchEvaluations];
    
    self.tableView.sectionHeaderHeight = 20.0;
    self.tableView.rowHeight = 85.0;
}


#pragma mark - Helpers

- (void)fetchEvaluations {
    _evaluations = [store.evaluations copy];
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_delegate &&
        [_delegate respondsToSelector:@selector(tableViewDidSelectEvaluation:)]) {
        [_delegate tableViewDidSelectEvaluation:_evaluations[indexPath.row]];
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _evaluations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"EvaluationCell";
    OCKEvaluationTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[OCKEvaluationTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                 reuseIdentifier:CellIdentifier];
    }
    cell.evaluation = _evaluations[indexPath.row];
    return cell;
}

@end
