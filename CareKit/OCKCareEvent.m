//
//  OCKCareEvent.m
//  CareKit
//
//  Created by Yuan Zhu on 2/1/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import "OCKCareEvent.h"
#import "OCKCareEvent_Internal.h"
#import "OCKTreatment_Internal.h"
#import "OCKEvaluation_Internal.h"

@implementation OCKCareEvent

- (instancetype)initWithCoreDataObject:(OCKCDCareEvent *)cdObject {
    self = [super init];
    if (self) {
        _occurrenceIndexOfDay = cdObject.occurrenceIndexOfDay.unsignedIntegerValue;
        _numberOfDaysSinceStart = cdObject.numberOfDaysSinceStart.unsignedIntegerValue;
        _completed = cdObject.completed.boolValue;
        _reportingDate = cdObject.reportingDate;
        _completionDate = cdObject.completionDate;
    }
    return self;
}

- (instancetype)initWithNumberOfDaysSinceStart:(NSUInteger)numberOfDaysSinceStart
                           occurrenceIndexOfDay:(NSUInteger)occurrenceIndexOfDay {
    self = [super init];
    if (self) {
        _numberOfDaysSinceStart = numberOfDaysSinceStart;
        _occurrenceIndexOfDay = occurrenceIndexOfDay;
    }
    
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKCareEvent* event = [[[self class] allocWithZone:zone] init];
    event->_occurrenceIndexOfDay = _occurrenceIndexOfDay;
    event->_numberOfDaysSinceStart = _numberOfDaysSinceStart;
    event->_completed = _completed;
    event->_reportingDate = _reportingDate;
    event->_completionDate = _completionDate;
    return event;
}

@end

@implementation OCKTreatmentEvent

- (instancetype)initWithCoreDataObject:(OCKCDTreatmentEvent *)cdObject {
    self = [super initWithCoreDataObject:cdObject];
    if (self) {
        if (cdObject.treatment) {
            _treatment = [[OCKTreatment alloc] initWithCoreDataObject:cdObject.treatment];
        }
    }
    return self;
}

- (instancetype)initWithNumberOfDaysSinceStart:(NSUInteger)numberOfDaysSinceStart
                           occurrenceIndexOfDay:(NSUInteger)occurrenceIndexOfDay
                                     treatment:(OCKTreatment *)treatment {
    self = [super initWithNumberOfDaysSinceStart:numberOfDaysSinceStart occurrenceIndexOfDay:occurrenceIndexOfDay];
    if (self) {
        _treatment = treatment;
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKTreatmentEvent* event = [super copyWithZone:zone];
    event->_treatment = _treatment;
    return event;
}

@end

@implementation OCKEvaluationEvent

- (instancetype)initWithCoreDataObject:(OCKCDEvaluationEvent *)cdObject {
    self = [super initWithCoreDataObject:cdObject];
    if (self) {
        if (cdObject.evaluation) {
            _evaluation = [[OCKEvaluation alloc] initWithCoreDataObject:cdObject.evaluation];
        }
        _evaluationValue = cdObject.evaluationValue;
        _evaluationResult = cdObject.evaluationResult;
    }
    return self;
}

- (instancetype)initWithNumberOfDaysSinceStart:(NSUInteger)numberOfDaysSinceStart
                          occurrenceIndexOfDay:(NSUInteger)occurrenceIndexOfDay
                                    evaluation:(OCKEvaluation *)evaluation {
    self = [super initWithNumberOfDaysSinceStart:numberOfDaysSinceStart occurrenceIndexOfDay:occurrenceIndexOfDay];
    if (self) {
        _evaluation = evaluation;
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKEvaluationEvent* event = [super copyWithZone:zone];
    event->_evaluation = _evaluation;
    event->_evaluationValue = _evaluationValue;
    event->_evaluationResult = _evaluationResult;
    return event;
}

@end


@implementation OCKCDCareEvent

- (instancetype)initWithEntity:(NSEntityDescription *)entity
insertIntoManagedObjectContext:(nullable NSManagedObjectContext *)context
                     careEvent:(OCKCareEvent *)careEvent {
    
    NSParameterAssert(careEvent);
    
    self = [super initWithEntity:entity insertIntoManagedObjectContext:context];
    if (self) {
        self.occurrenceIndexOfDay = @(careEvent.occurrenceIndexOfDay);
        self.numberOfDaysSinceStart = @(careEvent.numberOfDaysSinceStart);
        self.completed = @(careEvent.completed);
        self.reportingDate = careEvent.reportingDate;
        self.completionDate = careEvent.completionDate;
    }
    return self;
}

- (void)updateWithEvent:(OCKCareEvent *)careEvent {
    NSParameterAssert(careEvent);
    self.completed = @(careEvent.completed);
    self.completionDate = careEvent.completionDate;
    self.reportingDate = careEvent.reportingDate;
}

@end


@implementation OCKCDCareEvent (CoreDataProperties)

@dynamic occurrenceIndexOfDay;
@dynamic numberOfDaysSinceStart;
@dynamic completed;
@dynamic completionDate;
@dynamic reportingDate;

@end


@implementation OCKCDEvaluationEvent

- (instancetype)initWithEntity:(NSEntityDescription *)entity
insertIntoManagedObjectContext:(nullable NSManagedObjectContext *)context
               evaluationEvent:(OCKEvaluationEvent *)evaluationEvent
                  cdEvaluation:(OCKCDEvaluation *)cdEvaluation; {

    NSParameterAssert(cdEvaluation);
    
    self = [super initWithEntity:entity insertIntoManagedObjectContext:context careEvent:evaluationEvent];
    if (self) {
        self.evaluation = cdEvaluation;
        self.evaluationValue = evaluationEvent.evaluationValue;
        self.evaluationResult = evaluationEvent.evaluationResult;
    }
    return self;
}

- (void)updateWithEvent:(OCKEvaluationEvent *)evaluationEvent {
    [super updateWithEvent:evaluationEvent];
    self.evaluationResult = evaluationEvent.evaluationResult;
    self.evaluationValue = evaluationEvent.evaluationValue;
}

@end


@implementation OCKCDEvaluationEvent (CoreDataProperties)

@dynamic evaluationValue;
@dynamic evaluationResult;
@dynamic evaluation;

@end


@implementation OCKCDTreatmentEvent

- (instancetype)initWithEntity:(NSEntityDescription *)entity
insertIntoManagedObjectContext:(nullable NSManagedObjectContext *)context
                treatmentEvent:(OCKTreatmentEvent *)treatmentEvent
                   cdTreatment:(OCKCDTreatment *)cdTreatment {
    
    NSParameterAssert(cdTreatment);
    
    self = [super initWithEntity:entity insertIntoManagedObjectContext:context careEvent:treatmentEvent];
    if (self) {
        self.treatment = cdTreatment;
    }
    return self;
}

@end


@implementation OCKCDTreatmentEvent (CoreDataProperties)

@dynamic treatment;

@end
