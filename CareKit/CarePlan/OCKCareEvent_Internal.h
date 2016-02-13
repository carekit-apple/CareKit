//
//  OCKCareEvent_Internal.h
//  CareKit
//
//  Created by Yuan Zhu on 2/2/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import <CareKit/CareKit.h>
#import <CoreData/CoreData.h>
#import "OCKCarePlanItem_Internal.h"

NS_ASSUME_NONNULL_BEGIN

@interface OCKCareEvent () <OCKCoreDataObjectMirroring, NSCopying>

- (instancetype)initWithNumberOfDaysSinceStart:(NSUInteger)numberOfDaysSinceStart
                           occurrenceIndexOfDay:(NSUInteger)occurrenceIndexOfDay;

@property (nonatomic) OCKCareEventState state;

@property (nonatomic, strong) NSDate *eventChangeDate;

@property (nonatomic, strong) NSDate *completionDate;

@end

@interface OCKEvaluationEvent ()

- (instancetype)initWithNumberOfDaysSinceStart:(NSUInteger)numberOfDaysSinceStart
                           occurrenceIndexOfDay:(NSUInteger)occurrenceIndexOfDay
                                    evaluation:(OCKEvaluation *)evaluation;

@property (nonatomic, strong) NSNumber *evaluationValue;
@property (nonatomic, copy) NSString *evaluationValueString;
@property (nonatomic, strong) id<NSSecureCoding> evaluationResult;

@end

@interface OCKTreatmentEvent ()

- (instancetype)initWithNumberOfDaysSinceStart:(NSUInteger)numberOfDaysSinceStart
                           occurrenceIndexOfDay:(NSUInteger)occurrenceIndexOfDay
                                    treatment:(OCKTreatment *)treatment;
@end


@interface OCKCDCareEvent : NSManagedObject

- (instancetype)initWithEntity:(NSEntityDescription *)entity
insertIntoManagedObjectContext:(nullable NSManagedObjectContext *)context
                     careEvent:(OCKCareEvent *)careEvent;

- (void)updateWithEvent:(OCKCareEvent *)careEvent;

@end

@interface OCKCDCareEvent (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *occurrenceIndexOfDay;
@property (nullable, nonatomic, retain) NSNumber *numberOfDaysSinceStart;
@property (nullable, nonatomic, retain) NSNumber *state;
@property (nullable, nonatomic, retain) NSDate *completionDate;
@property (nullable, nonatomic, retain) NSDate *eventChangeDate;

@end


@class OCKCDEvaluation;

@interface OCKCDEvaluationEvent : OCKCDCareEvent

- (instancetype)initWithEntity:(NSEntityDescription *)entity
insertIntoManagedObjectContext:(nullable NSManagedObjectContext *)context
               evaluationEvent:(OCKEvaluationEvent *)evaluationEvent
                  cdEvaluation:(OCKCDEvaluation *)cdEvaluation;

@end

@interface OCKCDEvaluationEvent (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *evaluationValue;
@property (nullable, nonatomic, retain) NSString *evaluationValueString;
@property (nullable, nonatomic, retain) id<NSSecureCoding> evaluationResult;
@property (nullable, nonatomic, retain) OCKCDEvaluation *evaluation;

@end

@class OCKCDTreatment;

@interface OCKCDTreatmentEvent : OCKCDCareEvent

- (instancetype)initWithEntity:(NSEntityDescription *)entity
insertIntoManagedObjectContext:(nullable NSManagedObjectContext *)context
                treatmentEvent:(OCKTreatmentEvent *)treatmentEvent
                   cdTreatment:(OCKCDTreatment *)cdTreatment;

@end

@interface OCKCDTreatmentEvent (CoreDataProperties)

@property (nullable, nonatomic, retain) OCKCDTreatment *treatment;

@end



NS_ASSUME_NONNULL_END
