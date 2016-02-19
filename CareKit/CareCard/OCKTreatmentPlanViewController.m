//
//  OCKTreatmentsViewController.m
//  CareKit
//
//  Created by Umer Khan on 1/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKTreatmentPlanViewController.h"
#import "OCKTreatmentPlanViewController_Internal.h"
#import "OCKCareCard.h"
#import "OCKCarePlanActivity.h"
#import "OCKTreatmentsTableViewController.h"
#import "OCKWeekPageViewController.h"
#import "OCKHeartWeekView.h"


@implementation OCKTreatmentPlanViewController {
    OCKTreatmentsTableViewController *_tableViewController;
}

+ (instancetype)treatmentPlanViewControllerWithCarePlanStore:(OCKCarePlanStore *)store {
    return [[OCKTreatmentPlanViewController alloc] initWithCarePlanStore:store];
}

- (instancetype)initWithCarePlanStore:(OCKCarePlanStore *)store {
    _tableViewController = [[OCKTreatmentsTableViewController alloc] initWithCarePlanStore:store];

    self = [super initWithRootViewController:_tableViewController];
    if (self) {
        _store = store;
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _tableViewController.weekPageViewController.heartWeekView.delegate = self;
}

- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    self.topViewController.title = self.title;
}

- (OCKCareCard *)careCard {
    return _tableViewController.careCard;
}


#pragma mark - OCKHeartWeekDelegate

- (void)heartWeekViewSelectionDidChange:(OCKHeartWeekView *)heartWeekView {
//    OCKTreatmentPlan *plan = _plans[heartWeekView.selectedDay];
//    _tableViewController.treatments = plan.treatments;
}

@end
