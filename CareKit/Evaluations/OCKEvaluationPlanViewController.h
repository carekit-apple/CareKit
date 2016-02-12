//
//  OCKEvaluationPlanViewController.h
//  CareKit
//
//  Created by Umer Khan on 2/2/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@class OCKEvaluationPlan;

@interface OCKEvaluationPlanViewController : UINavigationController

+ (instancetype)evaluationPlanViewControllerWithEvaluationPlans:(NSArray<OCKEvaluationPlan *> *)plans;

- (instancetype)initWithEvaluationPlans:(NSArray<OCKEvaluationPlan *> *)plans;

@property (nonatomic, copy) NSArray<OCKEvaluationPlan *> *plans;
@property (nonatomic, readonly) OCKEvaluationPlan *currentEvaluationPlan;

@end

NS_ASSUME_NONNULL_END
