//
//  OCKEvaluation_Internal.h
//  CareKit
//
//  Created by Yuan Zhu on 2/2/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import <CareKit/CareKit.h>
#import "OCKCarePlanItem_Internal.h"

@class OCKCDEvaluationEvent;

NS_ASSUME_NONNULL_BEGIN

@interface OCKCDEvaluation : OCKCDCarePlanItem



@end

@interface OCKCDEvaluation (CoreDataProperties)

@property (nullable, nonatomic, strong) id<ORKTask, NSSecureCoding> task;
@property (nullable, nonatomic, retain) NSSet<OCKCDEvaluationEvent *> *events;
@property (nonatomic, strong) NSNumber *retryLimit;

@end

@interface OCKCDEvaluation (CoreDataGeneratedAccessors)

- (void)addEventsObject:(OCKCDEvaluationEvent *)value;
- (void)removeEventsObject:(OCKCDEvaluationEvent *)value;
- (void)addEvents:(NSSet<OCKCDEvaluationEvent *> *)values;
- (void)removeEvents:(NSSet<OCKCDEvaluationEvent *> *)values;

@end

NS_ASSUME_NONNULL_END