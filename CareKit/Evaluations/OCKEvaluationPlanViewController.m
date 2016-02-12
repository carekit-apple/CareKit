//
//  OCKEvaluationPlanViewController.m
//  CareKit
//
//  Created by Umer Khan on 2/2/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKEvaluationPlanViewController.h"
#import "OCKEvaluationTableViewController.h"
#import "OCKEvaluationPlan.h"


@implementation OCKEvaluationPlanViewController {
    OCKEvaluationTableViewController *_tableViewController;
}

+ (instancetype)evaluationPlanViewControllerWithEvaluationPlans:(NSArray<OCKEvaluationPlan *> *)plans {
    return [[OCKEvaluationPlanViewController alloc] initWithEvaluationPlans:plans];
}

- (instancetype)initWithEvaluationPlans:(NSArray<OCKEvaluationPlan *> *)plans {
    OCKEvaluationPlan *plan = [plans firstObject];
    _tableViewController = [[OCKEvaluationTableViewController alloc] initWithEvaluations:plan.evaluations];
    
    self = [super initWithRootViewController:_tableViewController];
    if (self) {
        _plans = [plans copy];
    }
    return self;
}

- (void)setPlans:(NSArray<OCKEvaluationPlan *> *)plans {
    _plans = plans;
    OCKEvaluationPlan *plan = [_plans firstObject];
    _tableViewController.evaluations = plan.evaluations;
}

- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    self.topViewController.title = self.title;
}

@end
