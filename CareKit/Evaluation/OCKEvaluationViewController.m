//
//  OCKEvaluationViewController.m
//  CareKit
//
//  Created by Umer Khan on 2/2/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKEvaluationViewController.h"
#import "OCKEvaluationViewController_Internal.h"
#import "OCKEvaluationTableViewController.h"
#import "OCKCarePlanStore.h"
#import "OCKCarePlanEvent.h"
#import "OCKWeekView.h"
#import "OCKWeekViewController.h"
#import "OCKEvaluationWeekView.h"
#import "NSDateComponents+CarePlanInternal.h"


@implementation OCKEvaluationViewController {
    OCKEvaluationTableViewController *_tableViewController;
}

+ (instancetype)evaluationViewControllerWithCarePlanStore:(OCKCarePlanStore *)store
                                                     delegate:(id<OCKEvaluationTableViewDelegate>)delegate {
    return [[OCKEvaluationViewController alloc] initWithCarePlanStore:store
                                                             delegate:delegate];
}

- (instancetype)initWithCarePlanStore:(OCKCarePlanStore *)store
                             delegate:(id<OCKEvaluationTableViewDelegate>)delegate {
    _tableViewController = [[OCKEvaluationTableViewController alloc] initWithCarePlanStore:store
                                                                                  delegate:delegate];
    self = [super initWithRootViewController:_tableViewController];
    if (self) {
        _store = store;
    }
    return self;
}

- (void)viewDidLoad {
    _tableViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Today"
                                                                                              style:UIBarButtonItemStylePlain
                                                                                             target:self
                                                                                             action:@selector(showToday:)];
    _tableViewController.navigationItem.rightBarButtonItem.tintColor = OCKPinkColor();
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _tableViewController.weekViewController.evaluationWeekView.delegate = self;
}

- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    self.topViewController.title = self.title;
}

- (OCKCarePlanEvent *)lastSelectedEvaluationEvent {
    return _tableViewController.lastSelectedEvaluationEvent;
}

- (void)showToday:(id)sender {
    _tableViewController.selectedDate = [[NSDateComponents alloc] initWithDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
}


#pragma mark - OCKEvaluationWeekViewDelegate

- (void)evaluationWeekViewSelectionDidChange:(OCKEvaluationWeekView *)evaluationWeekView {
    NSDateComponents *selectedDate = [_tableViewController dateFromSelectedIndex:evaluationWeekView.selectedIndex];
    NSDateComponents *today = [[NSDateComponents alloc] initWithDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
    if (![selectedDate isLaterThan:today]) {
        _tableViewController.selectedDate = selectedDate;
    }
}

@end
