//
//  OCKCarePlanStore.h
//  CareKit
//
//  Created by Yuan Zhu on 1/21/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <ResearchKit/ResearchKit.h>
#import <CareKit/CareKit.h>


NS_ASSUME_NONNULL_BEGIN

@class OCKTreatment;
@class OCKTreatmentEvent;
@class OCKEvaluation;
@class OCKEvaluationEvent;
@class OCKCarePlanStore;


/**
 Implement this delegate to subscribe to the notifications of changes in this store.
 */
@protocol OCKCarePlanStoreDelegate <NSObject>

- (void)carePlanStore:(OCKCarePlanStore *)store didReceiveUpdateOfEvaluationEvent:(OCKEvaluationEvent *)event;

- (void)carePlanStore:(OCKCarePlanStore *)store didReceiveUpdateOfTreatmentEvent:(OCKTreatmentEvent *)event;

- (void)carePlanStoreTreatmentListDidChange:(OCKCarePlanStore *)store;

- (void)carePlanStoreEvaluationListDidChange:(OCKCarePlanStore *)store;

@end


/**
 The `OCKCarePlanStore` class is a data store which store both treatments and evaluations.
 It also keeps events for its treatments and evaluations.
 */
@interface OCKCarePlanStore : NSObject

- (instancetype)init NS_UNAVAILABLE;

/**
 Initializer of the store.
 */
- (instancetype)initWithPersistenceDirectoryURL:(NSURL *)url;

/**
 This delegate can be used to subscribe to the notifications of changes in this store.
 */
@property (nonatomic, weak) id<OCKCarePlanStoreDelegate> delegate;

@end


/**
 Treatment operations.
 */
@interface OCKCarePlanStore (Treatment)

/**
 Get all treatments.
 */
@property (nonatomic, copy ,readonly) NSArray<OCKTreatment *> *treatments;

/**
 Get all treatments with a specified type.
 */
- (NSArray<OCKTreatment *> *)treatmentsWithType:(NSString *)type error:(NSError **)error;

/**
 Add a treatment.
 */
- (BOOL)addTreatment:(OCKTreatment *)treatment error:(NSError **)error;

/**
 Update a treatment's end date.
 */
- (BOOL)setEndDate:(NSDate *)date forTreatment:(OCKTreatment *)treatment error:(NSError **)error;

/**
 Remove a treatment from this store. 
 All its related event records will be removed as well.
 */
- (BOOL)removeTreatment:(OCKTreatment *)treatment error:(NSError **)error;

/**
 Obtain all `OCKTreatmentEvent` on a giving day.
 @disccussion Returned result grouped by `OCKTreatment`.
 */
- (NSArray<NSArray<OCKTreatmentEvent *> *> *)treatmentEventsOnDay:(NSDate *)date error:(NSError **)error;

/**
 Obtain all events of a `OCKTreatment` in a giving day.
 */
- (NSArray<OCKTreatmentEvent *> *)eventsOfTreatment:(OCKTreatment *)treatment onDay:(NSDate *)day error:(NSError **)error;

/**
 Mark an `OCKTreatmentEvent` to be completed.
 */
- (BOOL)updateTreatmentEvent:(OCKTreatmentEvent *)treatmentEvent
                   completed:(BOOL)completed
              completionDate:(NSDate *)completionDate
                       error:(NSError **)error;

/**
 Fetch all the events of an `OCKTreatment` by giving a date range.
 */
- (NSArray<OCKTreatmentEvent *> *)eventsOfTreatment:(OCKTreatment *)treatment
                                          startDate:(NSDate *)startDate
                                            endDate:(NSDate *)endDate
                                              error:(NSError **)error;

@end


/**
 Evaluation operations.
 */
@interface OCKCarePlanStore (Evaluation)

/**
 Get all evaluations.
 */
@property (nonatomic, copy ,readonly) NSArray<OCKEvaluation *> *evaluations;

/**
 Get all evaluations with a specified type.
 */
- (NSArray<OCKEvaluation *> *)evaluationsWithType:(NSString *)type error:(NSError **)error;

/**
 Add an OCKEvaluation.
 */
- (BOOL)addEvaluation:(OCKEvaluation *)evaluation error:(NSError **)error;

/**
 Remove an OCKEvaluation from this manager.
 */
- (BOOL)removeEvaluation:(OCKEvaluation *)evaluation error:(NSError **)error;

/**
 Set an end date for an OCKEvaluation.
 */
- (BOOL)setEndDate:(nullable NSDate *)date forEvaluation:(OCKEvaluation *)evaluation error:(NSError **)error;

/**
 Obtain all `OCKEvaluationEvent` on a giving day.
 @disccussion Returned result grouped by `OCKEvaluation`.
 */
- (NSArray<NSArray<OCKEvaluationEvent *> *> *)evaluationEventsOnDay:(NSDate *)date error:(NSError **)error;

/**
 Obtain all events of a `OCKEvaluation` in a giving day.
 */
- (NSArray<OCKEvaluationEvent *> *)eventsOfEvaluation:(OCKEvaluation *)evaluation onDay:(NSDate *)date  error:(NSError **)error;

/**
 Store the evaluationResult in an `OCKEvaluationEvent`.
 */
- (BOOL)updateEvaluationEvent:(OCKEvaluationEvent *)evaluationEvent
              evaluationValue:(NSNumber *)evaluationValue
             evaluationResult:(nullable id<NSSecureCoding>)evaluationResult
               completionDate:(NSDate *)completionDate
                        error:(NSError **)error;

/**
 Fetch all the events of an `OCKEvaluation` by giving a date range.
 */
- (NSArray<OCKEvaluationEvent *> *)eventsOfEvaluation:(OCKEvaluation *)evaluation
                                            startDate:(NSDate *)startDate
                                              endDate:(NSDate *)endDate
                                                error:(NSError **)error;

@end


NS_ASSUME_NONNULL_END
