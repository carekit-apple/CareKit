//
//  OCKTreatmentsViewController.m
//  CareKit
//
//  Created by Umer Khan on 1/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKCareCardViewController.h"
#import "OCKCareCardViewController_Internal.h"
#import "OCKCareCardTableViewController_Internal.h"
#import "OCKCarePlanStore.h"
#import "OCKCarePlanEvent.h"
#import "OCKWeekView.h"
#import "OCKWeekPageViewController.h"
#import "OCKCareCardWeekView.h"


@implementation OCKCareCardViewController {
    OCKCareCardTableViewController *_tableViewController;
}

+ (instancetype)careCardViewControllerWithCarePlanStore:(OCKCarePlanStore *)store {
    return [[OCKCareCardViewController alloc] initWithCarePlanStore:store];
}

- (instancetype)initWithCarePlanStore:(OCKCarePlanStore *)store {
    _tableViewController = [[OCKCareCardTableViewController alloc] initWithCarePlanStore:store];
    
    self = [super initWithRootViewController:_tableViewController];
    if (self) {
        _store = store;
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _tableViewController.delegate = self;
    _tableViewController.weekPageViewController.careCardWeekView.delegate = self;
}

- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    self.topViewController.title = self.title;
}


#pragma mark - OCKCareCardWeekViewDelegate

- (void)careCardWeekViewSelectionDidChange:(OCKCareCardWeekView *)careCardWeekView {
    NSDate *selectedDate = [_tableViewController dateFromSelectedDay:careCardWeekView.selectedDay];
    if (selectedDate.timeIntervalSinceNow < 0) {
        _tableViewController.selectedDate = selectedDate;
        OCKCareCardWeekView *careCardWeekView = _tableViewController.weekPageViewController.careCardWeekView;
        [careCardWeekView.weekView highlightDay:careCardWeekView.selectedDay];
    }
}


#pragma mark - OCKCareCardTableViewDelegate

- (void)tableViewDidSelectTreatmentEvent:(OCKCarePlanEvent *)treatmentEvent {
    // TODO: Implement this.
    
    // Navigate to detail treatment view controller.
}

@end
