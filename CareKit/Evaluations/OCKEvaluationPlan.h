//
//  OCKEvaluationPlan.h
//  CareKit
//
//  Created by Umer Khan on 2/2/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@class OCKEvaluation;

@interface OCKEvaluationPlan : NSObject <NSSecureCoding, NSCopying>

+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)evaluationPlanWithEvaluations:(NSArray<OCKEvaluation *> *)evaluations;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithEvaluations:(NSArray<OCKEvaluation *> *)evaluations;

@property (nonatomic, copy, readonly) NSArray<OCKEvaluation *> *evaluations;

@end

NS_ASSUME_NONNULL_END
