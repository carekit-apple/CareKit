//
//  OCKTreatmentsViewController.h
//  CareKit
//
//  Created by Umer Khan on 1/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@class OCKTreatmentPlan;

@interface OCKTreatmentPlanViewController : UINavigationController

+ (instancetype)treatmentPlanViewControllerWithTreatmentPlans:(NSArray<OCKTreatmentPlan *> *)plans;

- (instancetype)initWithTreatmentPlans:(NSArray<OCKTreatmentPlan *> *)plans;

@property (nonatomic, copy) NSArray<OCKTreatmentPlan *> *plans;
@property (nonatomic, readonly) OCKTreatmentPlan *currentTreatmentPlan;

@end

NS_ASSUME_NONNULL_END
