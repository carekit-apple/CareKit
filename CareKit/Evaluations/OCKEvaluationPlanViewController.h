//
//  OCKEvaluationPlanViewController.h
//  CareKit
//
//  Created by Umer Khan on 2/2/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@class OCKCarePlanStore, OCKEvaluation;

@protocol OCKEvaluationTableViewDelegate <NSObject>

@required

- (void)tableViewDidSelectEvaluation:(OCKEvaluation *)evaluation;

@end


@interface OCKEvaluationPlanViewController : UINavigationController

+ (instancetype)evaluationPlanViewControllerWithCarePlanStore:(OCKCarePlanStore *)store
                                                     delegate:(id<OCKEvaluationTableViewDelegate>)delegate;

- (instancetype)initWithCarePlanStore:(OCKCarePlanStore *)store
                             delegate:(id<OCKEvaluationTableViewDelegate>)delegate;

@property (nonatomic, readonly) OCKCarePlanStore *store;

@end

NS_ASSUME_NONNULL_END
