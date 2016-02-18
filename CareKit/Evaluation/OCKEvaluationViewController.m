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
#import "OCKEvaluationTableViewController_Internal.h"
#import "OCKCarePlanStore.h"
#import "OCKCarePlanEvent.h"
#import "OCKWeekView.h"
#import "OCKWeekPageViewController.h"
#import "OCKEvaluationWeekView.h"


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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _tableViewController.weekPageViewController.evaluationWeekView.delegate = self;
}

- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    self.topViewController.title = self.title;
}

- (OCKEvaluationEvent *)lastSelectedEvaluationEvent {
    return _tableViewController.lastSelectedEvaluationEvent;
}


#pragma mark - OCKEvaluationWeekViewDelegate

- (void)evaluationWeekViewSelectionDidChange:(OCKEvaluationWeekView *)evaluationWeekView {
    NSDate *selectedDate = [_tableViewController dateFromSelectedDay:evaluationWeekView.selectedDay];
    if (selectedDate.timeIntervalSinceNow < 0) {
        _tableViewController.selectedDate = selectedDate;
        OCKEvaluationWeekView *evaluationWeekView = _tableViewController.weekPageViewController.evaluationWeekView;
        [evaluationWeekView.weekView highlightDay:evaluationWeekView.selectedDay];
    }
}

@end
