//
//  OCKCareEvent.h
//  CareKit
//
//  Created by Yuan Zhu on 2/1/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CareKit/OCKEvaluation.h>
#import <CareKit/OCKTreatment.h>

NS_ASSUME_NONNULL_BEGIN

@interface OCKCareEvent : NSObject 

@property (nonatomic, readonly) NSUInteger occurrenceIndexOfDay;

@property (nonatomic, readonly) NSUInteger numberOfDaysSinceStart;

@property (nonatomic, readonly) BOOL completed;

@property (nonatomic, strong, readonly, nullable) NSDate *reportingDate;

@property (nonatomic, strong, readonly, nullable) NSDate *completionDate;

@end


@interface OCKTreatmentEvent : OCKCareEvent

@property (nonatomic, strong, readonly) OCKTreatment *treatment;

@end

@interface OCKEvaluationEvent : OCKCareEvent

@property (nonatomic, strong, readonly) OCKEvaluation *evaluation;

@property (nonatomic, strong, readonly, nullable) NSNumber *evaluationValue;

@property (nonatomic, strong, readonly, nullable) id<NSSecureCoding> evaluationResult;

@end

NS_ASSUME_NONNULL_END
