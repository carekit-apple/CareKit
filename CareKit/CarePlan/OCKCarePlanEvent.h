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

typedef NS_ENUM(NSInteger, OCKCareEventState) {
    OCKCareEventStateInitial,
    OCKCareEventStateNotCompleted,
    OCKCareEventStateCompleted
};

/**
 Abstract Event Class
 */
@interface OCKCarePlanEvent : NSObject 

/**
 The index of this event for its associated OCKCarePlanItem.
 */
@property (nonatomic, readonly) NSUInteger occurrenceIndexOfDay;

/**
 Which day this event is in. Counting from the start day.
 E.g. If this event is on start day, this value is `0`.
 The combination of `occurrenceIndexOfDay` and `numberOfDaysSinceStart` uniquely identifys an event.
 */
@property (nonatomic, readonly) NSUInteger numberOfDaysSinceStart;

/**
 The state of this event (Initial / NotCompleted / Completed).
 All event starts with `Initial`.
 */
@property (nonatomic, readonly) OCKCareEventState state;

/**
 When the event was changed.
 */
@property (nonatomic, strong, readonly, nullable) NSDate *eventChangeDate;

/**
 When the event was completed.
 */
@property (nonatomic, strong, readonly, nullable) NSDate *completionDate;

@end


@interface OCKTreatmentEvent : OCKCarePlanEvent

/**
 The treatment this event is belonging to.
 */
@property (nonatomic, strong, readonly) OCKTreatment *treatment;

@end

@interface OCKEvaluationEvent : OCKCarePlanEvent

/**
 The evaluation this event is belonging to.
 */
@property (nonatomic, strong, readonly) OCKEvaluation *evaluation;

/**
 The evaluation result value can be plotted.
 */
@property (nonatomic, strong, readonly, nullable) NSNumber *evaluationValue;

/**
 The evaluation result value can be displayed in UI.
 */
@property (nonatomic, copy, readonly, nullable) NSString *evaluationValueString;

/**
 The actual result object.
 */
@property (nonatomic, strong, readonly, nullable) id<NSSecureCoding> evaluationResult;

@end

NS_ASSUME_NONNULL_END
