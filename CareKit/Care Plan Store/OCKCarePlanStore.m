//
//  OCKCarePlanStore.m
//  CareKit
//
//  Created by Yuan Zhu on 1/21/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import "OCKCarePlanStore.h"
#import "OCKCarePlanItem_Internal.h"
#import "OCKTreatment_Internal.h"
#import "OCKEvaluation_Internal.h"
#import "OCKCareEvent_Internal.h"
#import "OCKCareSchedule_Internal.h"
#import "OCKHelpers.h"
#import "OCKDefines.h"

static NSManagedObjectContext *createManagedObjectContext(NSURL *modelURL, NSURL *storeURL, NSError **error) {
    
    NSManagedObjectModel *model =[[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                  configuration:nil
                                                            URL:storeURL
                                                        options:nil
                                                          error:error]) {
        return nil;
    }
    
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.persistentStoreCoordinator = persistentStoreCoordinator;
    return context;
}

static NSString * const CoreDataFileName = @".ock.careplan.db";
static NSString * const TreatmentsKey = @".ock.treatments";
static NSString * const EvaluationsKey = @".ock.evaluations";

static NSString * const OCKEntityNameTreatment =  @"OCKCDTreatment";
static NSString * const OCKEntityNameEvaluation =  @"OCKCDEvaluation";
static NSString * const OCKEntityNameTreatmentEvent =  @"OCKCDTreatmentEvent";
static NSString * const OCKEntityNameEvaluationEvent =  @"OCKCDEvaluationEvent";

static NSString * const OCKAttributeNameIdentifier = @"identifier";
static NSString * const OCKAttributeNameDayIndex = @"numberOfDaysSinceStart";

@implementation OCKCarePlanStore {
    NSURL *_persistenceDirectoryURL;
    NSArray *_cachedTreatments;
    NSArray *_cachedEvaluations;
    
    NSManagedObjectContext *_managedObjectContext;
}

- (instancetype)initWithPersistenceDirectoryURL:(NSURL *)url {
    NSParameterAssert(url);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    BOOL exist = [fileManager fileExistsAtPath:url.path isDirectory:&isDirectory];
    if (exist == NO) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"persistenceDirectoryURL is not exist." userInfo:nil];
    }
    if (isDirectory == NO) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"persistenceDirectoryURL is not a directory." userInfo:nil];
    }
    
    self = [super init];
    if (self) {
        _persistenceDirectoryURL = url;
    }
    return self;
}

- (NSString *)coredataFilePath {
    return [_persistenceDirectoryURL.path stringByAppendingPathComponent:CoreDataFileName];
}

#pragma mark - generic coredata operations

- (BOOL)block_addItemWithEntityName:(NSString *)entityName
                      coreDataClass:(Class)coreDataClass
                         sourceItem:(OCKCarePlanItem *)sourceItem
                              error:(NSError **)error{
    NSParameterAssert(entityName);
    NSParameterAssert(coreDataClass);
    NSParameterAssert(sourceItem);

    NSManagedObjectContext *context = [self contextWithError:error];
    if (context == nil) {
        return NO;
    }
    
    NSError *errorOut;

    NSManagedObject *cdObject;
    cdObject = [[coreDataClass alloc] initWithEntity:[NSEntityDescription entityForName:entityName
                                                                 inManagedObjectContext:context]
                      insertIntoManagedObjectContext:context
                                                item:sourceItem];
    
    if (![context save:&errorOut]) {
        if (error) {
            *error = errorOut;
        }
    }
    
    return errorOut ? NO : YES;
}

- (BOOL)block_alterItemWithEntityName:(NSString *)name
                           identifier:(NSString *)identifier
                              opBlock:(BOOL (^)(NSManagedObject *cdObject))opBlock
                                error:(NSError **)error {
    NSParameterAssert(name);
    NSParameterAssert(identifier);
    NSParameterAssert(opBlock);
    
    NSManagedObjectContext *context = [self contextWithError:error];
    if (context == nil) {
        return NO;
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:name];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K = %@",
                              OCKAttributeNameIdentifier, identifier];
    
    NSError *errorOut;
    
    NSArray *managedObjects = [context executeFetchRequest:fetchRequest error:&errorOut];
    
    if (managedObjects.count > 0 && errorOut == nil) {
        opBlock(managedObjects.firstObject);
        [context save:&errorOut];
    }
    
    if (error && errorOut) {
        *error = errorOut;
    }

    return errorOut ? NO : YES;
}

- (OCKCarePlanItem *)block_fetchItemWithEntityName:(NSString *)name
                                        identifier:(NSString *)identifier
                                             class:(Class)containerClass
                                             error:(NSError **)error {
    NSParameterAssert(name);
    NSParameterAssert(identifier);
    NSParameterAssert(containerClass);

    return [self block_fetchItemsWithEntityName:name
                                predicate:[NSPredicate predicateWithFormat:@"%K = %@",
                                           OCKAttributeNameIdentifier, identifier]
                                    class:containerClass
                                    error:error].firstObject;
    
}

- (BOOL)block_removeItemWithEntityName:(NSString *)name
                            identifier:(NSString *)identifier
                                 error:(NSError **)error {
    NSParameterAssert(name);
    NSParameterAssert(identifier);
    NSManagedObjectContext *context = [self contextWithError:error];
    if (context == nil) {
        return NO;
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:name];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K = %@",
                              OCKAttributeNameIdentifier, identifier];
    
    NSError *errorOut;
    BOOL found = NO;
    
    NSArray *managedObjects = [context executeFetchRequest:fetchRequest error:&errorOut];
    
    if (managedObjects.count > 0 && errorOut == nil) {
        found = YES;
        [context deleteObject:managedObjects.firstObject];
        [context save:&errorOut];
    }
    
    if (error && errorOut) {
        *error = errorOut;
    }
    
    return (found && errorOut == nil);
}

- (NSArray<OCKCarePlanItem *> *)block_fetchItemsWithEntityName:(NSString *)name
                                                         class:(Class)containerClass
                                                         error:(NSError **)error {
    NSParameterAssert(name);
    NSParameterAssert(containerClass);
    return [self block_fetchItemsWithEntityName:name predicate:nil class:containerClass error:error];
}


- (NSArray<OCKCarePlanItem *> *)block_fetchItemsWithEntityName:(NSString *)name
                                                     predicate:(NSPredicate *)predicate
                                                         class:(Class)containerClass
                                                         error:(NSError **)error {
    NSParameterAssert(name);
    NSParameterAssert(containerClass);
    
    NSManagedObjectContext *context = [self contextWithError:error];
    if (context == nil) {
        return nil;
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:name];
    fetchRequest.predicate = predicate;
    
    NSError *errorOut;
    NSMutableArray<OCKCarePlanItem *> *items = [NSMutableArray new];
   
        
    NSArray *managedObjects = [context executeFetchRequest:fetchRequest error:&errorOut];
    for (NSManagedObject *object in managedObjects) {
        [items addObject:[[containerClass alloc] initWithCoreDataObject:object]];
    }
    
    return [items copy];
}

#pragma mark - treatment

- (NSArray<OCKTreatment *> *)treatments {
    return [self fetchAllTreatmentsWithError:nil];
}

- (NSArray<OCKTreatment *> *)fetchAllTreatmentsWithError:(NSError **)error {
    __block NSArray<OCKTreatment *> *treatments;
    [[self contextWithError:error] performBlockAndWait:^{
        if (_cachedTreatments == nil) {
            _cachedTreatments = [self block_fetchItemsWithEntityName:OCKEntityNameTreatment class:[OCKTreatment class] error:error];
        }
        treatments = [_cachedTreatments copy];
    }];
    return treatments;
}

- (NSArray<OCKTreatment *> *)treatmentsWithType:(NSString *)type error:(NSError **)error {
    NSParameterAssert(type);
    
    NSArray *treatments = [self fetchAllTreatmentsWithError:error];
    return [treatments filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type = %@", type]];
}

- (void)handleTreatmentListChange:(BOOL)result {
    if (result && _delegate && [_delegate respondsToSelector:@selector(carePlanStoreTreatmentListDidChange:)]) {
        [_delegate carePlanStoreTreatmentListDidChange:self];
    }
}

- (BOOL)addTreatment:(OCKTreatment *)treatment error:(NSError **)error{
    NSParameterAssert(treatment);
    
    __block BOOL result = NO;
    [[self contextWithError:error] performBlockAndWait:^{
        
        result = [self block_addItemWithEntityName:OCKEntityNameTreatment coreDataClass:[OCKCDTreatment class] sourceItem:treatment error:error];
        if (result) {
            _cachedTreatments = nil;
        }
    }];
    
    [self handleTreatmentListChange:result];
    
    return result;
}

- (BOOL)removeTreatment:(OCKTreatment *)treatment error:(NSError **)error {
    NSParameterAssert(treatment);
    
    __block BOOL result = NO;
    [[self contextWithError:error] performBlockAndWait:^{
        result = [self block_removeItemWithEntityName:OCKEntityNameTreatment identifier:treatment.identifier error:error];
        if (result) {
            _cachedTreatments = nil;
        }
    }];
    
    [self handleTreatmentListChange:result];
    
    return result;
}

- (BOOL)setEndDate:(NSDate *)date forTreatment:(OCKTreatment *)treatment error:(NSError **)error {
    NSParameterAssert(treatment);
    
    __block BOOL result = NO;
    [[self contextWithError:error] performBlockAndWait:^{
        result = [self block_alterItemWithEntityName:OCKEntityNameTreatment
                                          identifier:treatment.identifier
                                             opBlock:^BOOL(NSManagedObject *cdObject) {
                                                 OCKCDTreatment *cdTreatment = (OCKCDTreatment *)cdObject;
                                                 OCKCareSchedule *schedule = cdTreatment.schedule;
                                                 schedule.endDate = date;
                                                 cdTreatment.schedule = schedule;
                                                 return YES;
                                             } error:error];
        if (result) {
            _cachedTreatments = nil;
        }
    }];
    
    [self handleTreatmentListChange:result];
    
    return result;
}

- (NSArray<NSArray<OCKTreatmentEvent *> *> *)treatmentEventsOnDay:(NSDate *)date error:(NSError **)error {
    NSParameterAssert(date);
    NSMutableArray *eventGroups = [NSMutableArray array];
    NSArray<OCKTreatment *> *items = [self fetchAllTreatmentsWithError:error];
    
    for (OCKTreatment *treatment in items) {
        NSArray *eventGroup = [self eventsOfTreatment:treatment onDay:(NSDate *)date error:error];
        if (eventGroup.count > 0) {
            [eventGroups addObject:eventGroup];
        }
    }
    return [eventGroups copy];
}

- (NSArray<OCKTreatmentEvent *> *)eventsOfTreatment:(OCKTreatment *)treatment onDay:(NSDate *)day error:(NSError **)error {
    OCKCareSchedule *schedule = treatment.schedule;
    NSUInteger numberOfEvents = [schedule numberOfEventsOnDay:day];
    
    NSMutableArray *eventGroup = [NSMutableArray array];
    
    NSManagedObjectContext *context = [self contextWithError:error];
    if (context == nil) {
        return nil;
    }
    
    if (numberOfEvents > 0) {
        
        NSUInteger numberOfDaySinceStart = [schedule numberOfDaySinceStart:day];
        
        [context performBlockAndWait:^{
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %d AND %K = %@",
                                      OCKAttributeNameDayIndex, numberOfDaySinceStart, @"treatment.identifier", treatment.identifier];
            
            NSArray<OCKTreatmentEvent *> *savedEvents = (NSArray<OCKTreatmentEvent *> *)[self block_fetchItemsWithEntityName:OCKEntityNameTreatmentEvent
                                                                                                             predicate:predicate
                                                                                                                 class:[OCKTreatmentEvent class]
                                                                                                                 error:error];
            
            for (NSInteger index = 0 ; index < numberOfEvents ; index++ ) {
                OCKTreatmentEvent *event = [savedEvents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"occurrenceIndexOfDay = %d", index]].firstObject;
                if (event == nil) {
                    event = [[OCKTreatmentEvent alloc] initWithNumberOfDaysSinceStart:numberOfDaySinceStart occurrenceIndexOfDay:index treatment:treatment];
                }
                [eventGroup addObject:event];
            }
        }];
    }
    
    return [eventGroup copy];
}

- (BOOL)updateTreatmentEvent:(OCKTreatmentEvent *)treatmentEvent
                   completed:(BOOL)completed
              completionDate:(NSDate *)completionDate
                       error:(NSError **)error {
    
    NSParameterAssert(treatmentEvent);
    NSDate *reportingDate = [NSDate date];
    
    __block NSManagedObjectContext *context = [self contextWithError:error];
    if (context == nil) {
        return NO;
    }
    
    OCKTreatmentEvent *copiedTreatmentEvent = [treatmentEvent copy];
    copiedTreatmentEvent.completed = completed;
    // Discard `completionDate` if completed flag is NO
    copiedTreatmentEvent.completionDate = completed ? completionDate : nil;
    copiedTreatmentEvent.reportingDate = reportingDate;
    
    __block NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:OCKEntityNameTreatmentEvent];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K = %d AND %K = %d",
                              @"occurrenceIndexOfDay", treatmentEvent.occurrenceIndexOfDay, @"numberOfDaysSinceStart", treatmentEvent.numberOfDaysSinceStart];
    
    __block NSError *errorOut;
    __block BOOL found = NO;
    
    [context performBlockAndWait:^{
        
        NSArray<OCKCDTreatmentEvent *> *cdTreatmentEvents = [context executeFetchRequest:fetchRequest error:&errorOut];
        
        if (errorOut == nil) {
            if (cdTreatmentEvents.count > 0) {
                
                // If the event exists
                found = YES;
                OCKCDTreatmentEvent *cdTreatmentEvent = cdTreatmentEvents.firstObject;
                [cdTreatmentEvent updateWithEvent:copiedTreatmentEvent];
                [context save:&errorOut];
                
            } else {
                
                //Find the treatment first
                fetchRequest = [NSFetchRequest fetchRequestWithEntityName:OCKEntityNameTreatment];
                fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K = %@",
                                          OCKAttributeNameIdentifier, treatmentEvent.treatment.identifier];
                
                NSArray<OCKCDTreatment *> *cdTreatments = [context executeFetchRequest:fetchRequest error:&errorOut];
                
                if (errorOut == nil) {
                    if (cdTreatments.count > 0) {
                        found = YES;
                        
                        // Create the event with treatment
                        OCKCDTreatment *cdTreatment = cdTreatments.firstObject;
                        NSEntityDescription *entity = [NSEntityDescription entityForName:OCKEntityNameTreatmentEvent
                                                                  inManagedObjectContext:context];
                        
                        OCKCDTreatmentEvent *cdTreatmentEvent = [[OCKCDTreatmentEvent alloc] initWithEntity:entity
                                                                             insertIntoManagedObjectContext:context
                                                                                            treatmentEvent:copiedTreatmentEvent
                                                                                                cdTreatment:cdTreatment];
                        
                        [cdTreatmentEvent updateWithEvent:copiedTreatmentEvent];
                        [context save:&errorOut];
                    }
                }
            }
        }
        
        if (error && errorOut) {
            *error = errorOut;
        }
    }];
    
    BOOL result = errorOut == nil && found;
    
    if (result && _delegate && [_delegate respondsToSelector:@selector(carePlanStore:didReceiveUpdateOfTreatmentEvent:)]) {
        [_delegate carePlanStore:self didReceiveUpdateOfTreatmentEvent:copiedTreatmentEvent];
    }
    
    return result;
}

- (NSArray<OCKTreatmentEvent *> *)eventsOfTreatment:(OCKTreatment *)treatment
                                          startDate:(NSDate *)startDate
                                            endDate:(NSDate *)endDate
                                              error:(NSError **)error {
    NSParameterAssert(treatment);
    NSParameterAssert(startDate);
    NSParameterAssert(endDate);
    
    if (startDate.timeIntervalSince1970 > endDate.timeIntervalSince1970) {
        return [NSArray new];
    }
    
    NSMutableArray *events = [NSMutableArray array];
    
    NSDate *date = startDate;
    NSCalendar *calendar = treatment.schedule.calendar;
    
    do {
        [events addObjectsFromArray:[self eventsOfTreatment:treatment onDay:date error:error]];
        date = [calendar startOfDayForDate:[calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:date options:0]];
    } while (date.timeIntervalSince1970 <= endDate.timeIntervalSince1970);
    
    return [events copy];
}

#pragma mark - evaluation

- (NSArray<OCKEvaluation *> *)evaluations {
    return [self fetchAllEvaluationsWithError:nil];
}

- (NSArray<OCKEvaluation *> *)fetchAllEvaluationsWithError:(NSError **)error {
    
    __block NSArray<OCKEvaluation *> *evaluations = nil;
    NSManagedObjectContext *context = [self contextWithError:error];
    [context performBlockAndWait:^{
        if (_cachedEvaluations == nil) {
            _cachedEvaluations = [self block_fetchItemsWithEntityName:OCKEntityNameEvaluation class:[OCKEvaluation class] error:error];
        }
        evaluations = [_cachedEvaluations copy];
    }];
    
    return evaluations;
    
}

- (NSArray<OCKEvaluation *> *)evaluationsWithType:(NSString *)type error:(NSError **)error {
    NSArray<OCKEvaluation *> *evaluations = [self fetchAllEvaluationsWithError:error];
    return [evaluations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type = %@", type]];
}

- (void)handleEvaluationListChange:(BOOL)result {
    if (result && _delegate && [_delegate respondsToSelector:@selector(carePlanStoreEvaluationListDidChange:)]) {
        [_delegate carePlanStoreEvaluationListDidChange:self];
    }
}

- (BOOL)addEvaluation:(OCKEvaluation *)evaluation error:(NSError **)error {
    NSParameterAssert(evaluation);

    NSManagedObjectContext *context = [self contextWithError:error];
    __block BOOL result = NO;
    [context performBlockAndWait:^{
        result = [self block_addItemWithEntityName:OCKEntityNameEvaluation coreDataClass:[OCKCDEvaluation class] sourceItem:evaluation error:error];
        if (result) {
            _cachedEvaluations = nil;
        }
    }];
    
    [self handleEvaluationListChange:result];
    
    return result;
}

- (BOOL)setEndDate:(NSDate *)date forEvaluation:(OCKEvaluation *)evaluation error:(NSError **)error {
    NSParameterAssert(evaluation);
    
    NSManagedObjectContext *context = [self contextWithError:error];
    __block BOOL result = NO;
    [context performBlockAndWait:^{
        result = [self block_alterItemWithEntityName:OCKEntityNameEvaluation
                                    identifier:evaluation.identifier
                                       opBlock:^BOOL(NSManagedObject *cdObject) {
                                           OCKCDEvaluation *evaluation = (OCKCDEvaluation *)cdObject;
                                           OCKCareSchedule *schedule = evaluation.schedule;
                                           schedule.endDate = date;
                                           evaluation.schedule = schedule;
                                           return YES;
                                       } error:error];
        if(result) {
            _cachedEvaluations = nil;
        }
    }];
    
    [self handleEvaluationListChange:result];
    
    return result;
}

- (BOOL)removeEvaluation:(OCKEvaluation *)evaluation error:(NSError **)error {
    NSParameterAssert(evaluation);
    
    NSManagedObjectContext *context = [self contextWithError:error];
    __block BOOL result = NO;
    [context performBlockAndWait:^{
        result = [self block_removeItemWithEntityName:OCKEntityNameEvaluation identifier:evaluation.identifier error:error];
        if (result) {
            _cachedEvaluations = nil;
        }
    }];
    
    [self handleEvaluationListChange:result];
    
    return result;
}

- (NSArray<NSArray<OCKEvaluationEvent *> *> *)evaluationEventsOnDay:(NSDate *)date error:(NSError **)error {
    
    NSParameterAssert(date);
    NSMutableArray *eventGroups = [NSMutableArray array];
    NSArray<OCKEvaluation *> *evaluations = [self fetchAllEvaluationsWithError:error];
    
    for (OCKEvaluation *evaluation in evaluations) {
        NSArray *eventGroup = [self eventsOfEvaluation:evaluation onDay:date error:error];
        if (eventGroup.count > 0) {
            [eventGroups addObject:eventGroup];
        }
    }
    return [eventGroups copy];
}

- (NSArray<OCKEvaluationEvent *> *)eventsOfEvaluation:(OCKEvaluation *)evaluation onDay:(NSDate *)date  error:(NSError **)error {
    NSParameterAssert(evaluation);
    NSParameterAssert(date);
    
    OCKCareSchedule *schedule = evaluation.schedule;
    NSUInteger numberOfEvents = [schedule numberOfEventsOnDay:date];
    
    NSMutableArray *eventGroup = [NSMutableArray array];
    
    NSManagedObjectContext *context = [self contextWithError:error];
    
    if (numberOfEvents > 0) {
        [context performBlockAndWait:^{
            NSUInteger numberOfDaySinceStart = [schedule numberOfDaySinceStart:date];
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %d AND %K = %@",
                                      OCKAttributeNameDayIndex, numberOfDaySinceStart, @"evaluation.identifier", evaluation.identifier];
            
            NSArray<OCKEvaluationEvent *> *savedEvents = (NSArray<OCKEvaluationEvent *> *)[self block_fetchItemsWithEntityName:OCKEntityNameEvaluationEvent predicate:predicate class:[OCKEvaluationEvent class] error:error];
            
            for (NSInteger index = 0 ; index < numberOfEvents ; index++ ) {
                OCKEvaluationEvent *event = [savedEvents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"occurrenceIndexOfDay = %d", index]].firstObject;
                if (event == nil) {
                    event = [[OCKEvaluationEvent alloc] initWithNumberOfDaysSinceStart:numberOfDaySinceStart occurrenceIndexOfDay:index evaluation:evaluation];
                }
                [eventGroup addObject:event];
            }
        }];
    }
    
    return [eventGroup copy];
}

- (NSArray<OCKEvaluationEvent *> *)eventsOfEvaluation:(OCKEvaluation *)evaluation
                                            startDate:(NSDate *)startDate
                                              endDate:(NSDate *)endDate
                                                error:(NSError **)error {
    NSParameterAssert(evaluation);
    NSParameterAssert(startDate);
    NSParameterAssert(endDate);
    
    if (startDate.timeIntervalSince1970 >= endDate.timeIntervalSince1970) {
        return [NSArray new];
    }
    
    NSMutableArray *events = [NSMutableArray array];
    
    NSDate *date = startDate;
    NSCalendar *calendar = evaluation.schedule.calendar;
   
    do {
        [events addObjectsFromArray:[self eventsOfEvaluation:evaluation onDay:date error:error]];
        date = [calendar startOfDayForDate:[calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:date options:0]];
    } while (date.timeIntervalSince1970 <= endDate.timeIntervalSince1970);
    
    return [events copy];
}

- (BOOL)updateEvaluationEvent:(OCKEvaluationEvent *)evaluationEvent
              evaluationValue:(NSNumber *)evaluationValue
             evaluationResult:(id<NSSecureCoding>)evaluationResult
               completionDate:(NSDate *)completionDate
                        error:(NSError **)error {
    NSParameterAssert(evaluationEvent);
    NSDate *reportingDate = [NSDate date];
    
    __block NSManagedObjectContext *context = [self contextWithError:error];
    if (context == nil) {
        return NO;
    }
    
    OCKEvaluationEvent *copiedEvaluationEvent = [evaluationEvent copy];
    copiedEvaluationEvent.completed = YES;
    copiedEvaluationEvent.completionDate = completionDate;
    copiedEvaluationEvent.reportingDate = reportingDate;
    copiedEvaluationEvent.evaluationValue = evaluationValue;
    copiedEvaluationEvent.evaluationResult = evaluationResult;
    
    __block NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:OCKEntityNameEvaluationEvent];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K = %d AND %K = %d",
                              @"occurrenceIndexOfDay", evaluationEvent.occurrenceIndexOfDay, @"numberOfDaysSinceStart", evaluationEvent.numberOfDaysSinceStart];
    
    __block NSError *errorOut;
    __block BOOL found = NO;
    __block BOOL result = NO;
    
    [context performBlockAndWait:^{
        
        NSArray<OCKCDEvaluationEvent *> *cdEvalautionEvents = [context executeFetchRequest:fetchRequest error:&errorOut];
        
        if (errorOut == nil) {
            if (cdEvalautionEvents.count > 0) {
                
                // If the event exists
                found = YES;
                OCKCDEvaluationEvent *cdEvaluationEvent = cdEvalautionEvents.firstObject;
                [cdEvaluationEvent updateWithEvent:copiedEvaluationEvent];
                [context save:&errorOut];
                
            } else {
                
                //Find the treatment first
                fetchRequest = [NSFetchRequest fetchRequestWithEntityName:OCKEntityNameEvaluation];
                fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K = %@",
                                          OCKAttributeNameIdentifier, evaluationEvent.evaluation.identifier];
                
                NSArray<OCKCDEvaluation *> *cdEvaluations = [context executeFetchRequest:fetchRequest error:&errorOut];
                
                if (errorOut == nil) {
                    if (cdEvaluations.count > 0) {
                        found = YES;
                        
                        // Create the event with treatment
                        OCKCDEvaluation *cdEvaluation = cdEvaluations.firstObject;
                        NSEntityDescription *entity = [NSEntityDescription entityForName:OCKEntityNameEvaluationEvent
                                                                  inManagedObjectContext:context];
                        
                        OCKCDEvaluationEvent *cdEvaluationEvent = [[OCKCDEvaluationEvent alloc] initWithEntity:entity
                                                                                insertIntoManagedObjectContext:context
                                                                                               evaluationEvent:evaluationEvent
                                                                                                  cdEvaluation:cdEvaluation];
                        
                        [cdEvaluationEvent updateWithEvent:copiedEvaluationEvent];
                        [context save:&errorOut];
                    }
                }
            }
            
            
        }
        
        result = errorOut == nil && found;
        
        if (error && errorOut) {
            *error = errorOut;
        }
    }];
    
    if (result && _delegate && [_delegate respondsToSelector:@selector(carePlanStore:didReceiveUpdateOfEvaluationEvent:)]) {
        [_delegate carePlanStore:self didReceiveUpdateOfEvaluationEvent:copiedEvaluationEvent];
    }
    
    return result;
}



#pragma mark - coredata

static NSString * const OCKCarePlanModelName =  @"OCKCarePlanStore";

- (NSManagedObjectContext *)contextWithError:(NSError **)error {
    if (_managedObjectContext == nil) {
        NSURL *modelURL = [OCKBundle() URLForResource:OCKCarePlanModelName
                                        withExtension:@"momd"];
        NSURL *storeURL = [NSURL fileURLWithPath:[self coredataFilePath]];
        _managedObjectContext = createManagedObjectContext(modelURL, storeURL, error);
        OCK_Log_Debug(@"%@", storeURL);
    }
    return _managedObjectContext;
}

@end
