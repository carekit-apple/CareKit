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
#import "OCKTreatment.h"
#import "OCKTreatmentPlan.h"
#import "OCKTreatmentsTableViewController.h"
#import "OCKWeekPageViewController.h"
#import "OCKHeartWeekView.h"


@implementation OCKTreatmentPlanViewController {
    OCKTreatmentsTableViewController *_tableViewController;
}

+ (instancetype)treatmentPlanViewControllerWithTreatmentPlans:(NSArray<OCKTreatmentPlan *> *)plans {
    return [[OCKTreatmentPlanViewController alloc] initWithTreatmentPlans:plans];
}

- (instancetype)initWithTreatmentPlans:(NSArray<OCKTreatmentPlan *> *)plans {
    OCKTreatmentPlan *plan = [plans firstObject];
    _tableViewController = [[OCKTreatmentsTableViewController alloc] initWithTreatments:plan.treatments];
    
    self = [super initWithRootViewController:_tableViewController];
    if (self) {
        _plans = [plans copy];
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _tableViewController.weekPageViewController.heartWeekView.delegate = self;
}

- (void)setPlans:(NSArray<OCKTreatmentPlan *> *)plans {
    _plans = plans;
    OCKTreatmentPlan *plan = [_plans firstObject];
    _tableViewController.treatments = plan.treatments;
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
    OCKTreatmentPlan *plan = _plans[heartWeekView.selectedDay];
    _tableViewController.treatments = plan.treatments;
}

@end
