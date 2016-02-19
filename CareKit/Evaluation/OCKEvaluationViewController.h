//
//  OCKEvaluationViewController.h
//  CareKit
//
//  Created by Umer Khan on 2/2/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@class OCKCarePlanStore, OCKEvaluationEvent;

@protocol OCKEvaluationTableViewDelegate <NSObject>

- (void)tableViewDidSelectRowWithEvaluationEvent:(OCKEvaluationEvent *)evaluationEvent;

@end


@interface OCKEvaluationViewController : UINavigationController

+ (instancetype)evaluationViewControllerWithCarePlanStore:(OCKCarePlanStore *)store
                                                 delegate:(id<OCKEvaluationTableViewDelegate>)delegate;

- (instancetype)initWithCarePlanStore:(OCKCarePlanStore *)store
                             delegate:(id<OCKEvaluationTableViewDelegate>)delegate;

@property (nonatomic, readonly) OCKCarePlanStore *store;
@property (nonatomic, readonly) OCKEvaluationEvent *lastSelectedEvaluationEvent;

@end

NS_ASSUME_NONNULL_END
