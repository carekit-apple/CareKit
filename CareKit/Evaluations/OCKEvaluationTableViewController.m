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


@implementation OCKEvaluationTableViewController

+ (instancetype)new {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithEvaluations:(NSArray<OCKEvaluation *> *)evaluations {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.title = @"Evaluations";
        _evaluations = [evaluations copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.sectionHeaderHeight = 20.0;
    self.tableView.rowHeight = 85.0;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ORKTaskViewController *taskViewController = [[ORKTaskViewController alloc] initWithTask:_evaluations[indexPath.row].task
                                                                            restorationData:nil
                                                                                   delegate:self];
    [self presentViewController:taskViewController animated:YES completion:nil];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.evaluations.count;
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


#pragma mark - ORKTaskViewControllerDelegate

- (void)taskViewController:(ORKTaskViewController *)taskViewController didFinishWithReason:(ORKTaskViewControllerFinishReason)reason error:(NSError *)error {
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    OCKEvaluation *selectedEvaluation = _evaluations[indexPath.row];
    selectedEvaluation.value = [selectedEvaluation.delegate normalizedValueOfEvaluation:selectedEvaluation forTaskResult:taskViewController.result];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    
    [self dismissViewControllerAnimated:taskViewController completion:nil];
}

@end
