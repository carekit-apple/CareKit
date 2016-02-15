//
//  OCKCarePlanStore.m
//  CareKit
//
//  Created by Yuan Zhu on 1/21/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import "OCKCarePlanStore.h"
#import "OCKCarePlanStore_Internal.h"
#import "OCKCarePlanActivity_Internal.h"
#import "OCKTreatment_Internal.h"
#import "OCKEvaluation_Internal.h"
#import "OCKCarePlanEvent_Internal.h"
#import "OCKCareSchedule_Internal.h"
#import "OCKHelpers.h"
#import "OCKDefines.h"

static NSManagedObjectContext *createManagedObjectContext(NSURL *modelURL, NSURL *storeURL, NSError **error) {
    
    NSManagedObjectModel *model =[[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                  configuration:nil
                                                            URL:storeURL
                                                        options:@{NSFileProtectionKey: NSFileProtectionComplete}
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
                         sourceItem:(OCKCarePlanActivity *)sourceItem
                              error:(NSError **)error{
    NSParameterAssert(entityName);
    NSParameterAssert(coreDataClass);
    NSParameterAssert(sourceItem);

    NSManagedObjectContext *context = [self contextWithError:error];
    if (context == nil) {
        return NO;
    }
    
    NSError *errorOut;
    
    OCKCarePlanActivity *item = [self block_fetchItemWithEntityName:entityName
                                                         identifier:sourceItem.identifier
                                                              class:[OCKCarePlanActivity class]
                                                              error:&errorOut];
    
    if (item) {
        if (error) {
            NSString *reasonString = [NSString stringWithFormat:@"The activity with same identifier %@ is existing.", sourceItem.identifier];
            *error = [NSError errorWithDomain:OCKErrorDomain code:OCKErrorInvalidObject userInfo:@{@"reason":reasonString}];
        }
    } else {
    
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

- (OCKCarePlanActivity *)block_fetchItemWithEntityName:(NSString *)name
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

- (NSArray<OCKCarePlanActivity *> *)block_fetchItemsWithEntityName:(NSString *)name
                                                         class:(Class)containerClass
                                                         error:(NSError **)error {
    NSParameterAssert(name);
    NSParameterAssert(containerClass);
    return [self block_fetchItemsWithEntityName:name predicate:nil class:containerClass error:error];
}


- (NSArray<OCKCarePlanActivity *> *)block_fetchItemsWithEntityName:(NSString *)name
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
    NSMutableArray<OCKCarePlanActivity *> *items = [NSMutableArray new];
   
        
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

- (OCKTreatment *)treatmentForIdentifier:(NSString *)identifier error:(NSError **)error {
    NSParameterAssert(identifier);
    NSArray *treatments = [self fetchAllTreatmentsWithError:error];
    return [treatments filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier = %@", identifier]].firstObject;
}

- (NSArray<OCKTreatment *> *)fetchAllTreatmentsWithError:(NSError **)error {
    __block NSArray<OCKTreatment *> *treatments;
    __weak typeof(self) weakSelf = self;
    [[self contextWithError:error] performBlockAndWait:^{
        if (_cachedTreatments == nil) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            _cachedTreatments = [strongSelf block_fetchItemsWithEntityName:OCKEntityNameTreatment class:[OCKTreatment class] error:error];
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
    if (result){
        if (_treatmentUIDelegate && [_treatmentUIDelegate respondsToSelector:@selector(carePlanStoreTreatmentListDidChange:)]) {
            [_treatmentUIDelegate carePlanStoreTreatmentListDidChange:self];
        }
        if (_delegate && [_delegate respondsToSelector:@selector(carePlanStoreTreatmentListDidChange:)]) {
            [_delegate carePlanStoreTreatmentListDidChange:self];
        }
    }
}

- (BOOL)addTreatment:(OCKTreatment *)treatment error:(NSError **)error{
    NSParameterAssert(treatment);
    
    __block BOOL result = NO;
    __weak typeof(self) weakSelf = self;
    [[self contextWithError:error] performBlockAndWait:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        result = [strongSelf block_addItemWithEntityName:OCKEntityNameTreatment coreDataClass:[OCKCDTreatment class] sourceItem:treatment error:error];
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
    __weak typeof(self) weakSelf = self;
    [[self contextWithError:error] performBlockAndWait:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        result = [strongSelf block_removeItemWithEntityName:OCKEntityNameTreatment identifier:treatment.identifier error:error];
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
    __weak typeof(self) weakSelf = self;
    [[self contextWithError:error] performBlockAndWait:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        result = [strongSelf block_alterItemWithEntityName:OCKEntityNameTreatment
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
        __weak typeof(self) weakSelf = self;
        [context performBlockAndWait:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %d AND %K = %@",
                                      OCKAttributeNameDayIndex, numberOfDaySinceStart, @"treatment.identifier", treatment.identifier];
            
            NSArray<OCKTreatmentEvent *> *savedEvents = (NSArray<OCKTreatmentEvent *> *)[strongSelf block_fetchItemsWithEntityName:OCKEntityNameTreatmentEvent
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

- (void)updateTreatmentEvent:(OCKTreatmentEvent *)treatmentEvent
                   completed:(BOOL)completed
              completionDate:(NSDate *)completionDate
           completionHandler:(void (^)(BOOL success, OCKTreatmentEvent *event, NSError *error))completionHandler {
    
    NSParameterAssert(treatmentEvent);
    NSParameterAssert(completionHandler);
    NSDate *eventChangeDate = [NSDate date];
    
    NSError *error;
    __block NSManagedObjectContext *context = [self contextWithError:&error];
    if (context == nil) {
        completionHandler(NO, treatmentEvent, error);
        return;
    }
    
    OCKTreatmentEvent *copiedTreatmentEvent = [treatmentEvent copy];
    copiedTreatmentEvent.state = completed ? OCKCareEventStateCompleted : OCKCareEventStateNotCompleted;
    // Discard `completionDate` if completed flag is NO
    copiedTreatmentEvent.completionDate = completed ? completionDate : nil;
    copiedTreatmentEvent.eventChangeDate = eventChangeDate;
    
    __block NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:OCKEntityNameTreatmentEvent];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K = %d AND %K = %d",
                              @"occurrenceIndexOfDay", treatmentEvent.occurrenceIndexOfDay, @"numberOfDaysSinceStart", treatmentEvent.numberOfDaysSinceStart];
    
    __block NSError *errorOut;
    __block BOOL found = NO;
    
    [context performBlock:^{
        
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
        
        BOOL result = errorOut == nil && found;
        
        dispatch_async(dispatch_get_main_queue(), ^(){
            completionHandler(result, result ? copiedTreatmentEvent : treatmentEvent, errorOut);
            
            if (result) {
                if(_treatmentUIDelegate && [_treatmentUIDelegate respondsToSelector:@selector(carePlanStore:didReceiveUpdateOfTreatmentEvent:)]) {
                    [_treatmentUIDelegate carePlanStore:self didReceiveUpdateOfTreatmentEvent:copiedTreatmentEvent];
                }
                if(_delegate && [_delegate respondsToSelector:@selector(carePlanStore:didReceiveUpdateOfTreatmentEvent:)]) {
                    [_delegate carePlanStore:self didReceiveUpdateOfTreatmentEvent:copiedTreatmentEvent];
                }
            }
        });
    }];
}

- (void)enumerateEventsOfTreatment:(OCKTreatment *)treatment
                         startDate:(NSDate *)startDate
                           endDate:(NSDate *)endDate
                        usingBlock:(void (^)(OCKTreatmentEvent *event, BOOL *stop, NSError *error))block {
    NSParameterAssert(treatment);
    NSParameterAssert(startDate);
    NSParameterAssert(endDate);
    NSParameterAssert(block);
    
    if (startDate.timeIntervalSince1970 > endDate.timeIntervalSince1970) {
        return;
    }
    
    NSDate *date = startDate;
    NSCalendar *calendar = treatment.schedule.calendar;
    
    BOOL stop = NO;
    do {
        NSError *error;
        
        NSArray<OCKTreatmentEvent *> *events = [self eventsOfTreatment:treatment onDay:date error:&error];
        for (OCKTreatmentEvent* event in events) {
            block(event, &stop, error);
            if (stop) {
                break;
            }
        }
        date = [calendar startOfDayForDate:[calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:date options:0]];
    } while (stop == NO && date.timeIntervalSince1970 <= endDate.timeIntervalSince1970);
    
}

#pragma mark - evaluation

- (NSArray<OCKEvaluation *> *)evaluations {
    return [self fetchAllEvaluationsWithError:nil];
}

- (OCKEvaluation *)evaluationForIdentifier:(NSString *)identifier error:(NSError **)error {
    
    NSArray<OCKEvaluation *> *evaluations = [self fetchAllEvaluationsWithError:error];
    return [evaluations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier = %@", identifier]].firstObject;
}

- (NSArray<OCKEvaluation *> *)fetchAllEvaluationsWithError:(NSError **)error {
    
    __block NSArray<OCKEvaluation *> *evaluations = nil;
    NSManagedObjectContext *context = [self contextWithError:error];
     __weak typeof(self) weakSelf = self;
    [context performBlockAndWait:^{
        if (_cachedEvaluations == nil) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            _cachedEvaluations = [strongSelf block_fetchItemsWithEntityName:OCKEntityNameEvaluation class:[OCKEvaluation class] error:error];
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
    if (result) {
        if (_evaluationUIDelegate && [_evaluationUIDelegate respondsToSelector:@selector(carePlanStoreEvaluationListDidChange:)]) {
            [_evaluationUIDelegate carePlanStoreEvaluationListDidChange:self];
        }
        if(_delegate && [_delegate respondsToSelector:@selector(carePlanStoreEvaluationListDidChange:)]) {
            [_delegate carePlanStoreEvaluationListDidChange:self];
        }
    }
}

- (BOOL)addEvaluation:(OCKEvaluation *)evaluation error:(NSError **)error {
    NSParameterAssert(evaluation);

    NSManagedObjectContext *context = [self contextWithError:error];
    __block BOOL result = NO;
    __weak typeof(self) weakSelf = self;
    [context performBlockAndWait:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        result = [strongSelf block_addItemWithEntityName:OCKEntityNameEvaluation coreDataClass:[OCKCDEvaluation class] sourceItem:evaluation error:error];
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
    __weak typeof(self) weakSelf = self;
    [context performBlockAndWait:^{
         __strong typeof(weakSelf) strongSelf = weakSelf;
        result = [strongSelf block_alterItemWithEntityName:OCKEntityNameEvaluation
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
    __weak typeof(self) weakSelf = self;
    [context performBlockAndWait:^{
         __strong typeof(weakSelf) strongSelf = weakSelf;
        result = [strongSelf block_removeItemWithEntityName:OCKEntityNameEvaluation identifier:evaluation.identifier error:error];
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

- (void)enumerateEventsOfEvaluation:(OCKEvaluation *)evaluation
                          startDate:(NSDate *)startDate
                            endDate:(NSDate *)endDate
                         usingBlock:(void (^)(OCKEvaluationEvent *event, BOOL *stop, NSError *error))block {
    NSParameterAssert(evaluation);
    NSParameterAssert(startDate);
    NSParameterAssert(endDate);
    NSParameterAssert(block);
    
    if (startDate.timeIntervalSince1970 >= endDate.timeIntervalSince1970) {
        return;
    }
    
    NSDate *date = startDate;
    NSCalendar *calendar = evaluation.schedule.calendar;
    
    BOOL stop = NO;
    do {
        NSError *error;
        
        NSArray<OCKEvaluationEvent *> *events = [self eventsOfEvaluation:evaluation onDay:date error:&error];
        for (OCKEvaluationEvent* event in events) {
            block(event, &stop, error);
            if (stop) {
                break;
            }
        }
        date = [calendar startOfDayForDate:[calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:date options:0]];
    } while (stop == NO && date.timeIntervalSince1970 <= endDate.timeIntervalSince1970);
}

- (void)updateEvaluationEvent:(OCKEvaluationEvent *)evaluationEvent
              evaluationValue:(NSNumber *)evaluationValue
        evaluationValueString:(NSString *)evaluationValueString
             evaluationResult:(id<NSSecureCoding>)evaluationResult
               completionDate:(NSDate *)completionDate
            completionHandler:(void (^)(BOOL success, OCKEvaluationEvent *event, NSError *error))completionHandler {
    
    NSParameterAssert(evaluationEvent);
    NSParameterAssert(completionHandler);
    NSDate *eventChangeDate = [NSDate date];
    NSError *error;
    __block NSManagedObjectContext *context = [self contextWithError:&error];
    if (context == nil) {
        completionHandler(NO, evaluationEvent, error);
        return;
    }
    
    OCKEvaluationEvent *copiedEvaluationEvent = [evaluationEvent copy];
    copiedEvaluationEvent.state = OCKCareEventStateCompleted;
    copiedEvaluationEvent.completionDate = completionDate;
    copiedEvaluationEvent.eventChangeDate = eventChangeDate;
    copiedEvaluationEvent.evaluationValue = evaluationValue;
    copiedEvaluationEvent.evaluationResult = evaluationResult;
    copiedEvaluationEvent.evaluationValueString = evaluationValueString;
    
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
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(result, result ? copiedEvaluationEvent : evaluationEvent, errorOut);
            
            if (result){
                if(_evaluationUIDelegate && [_evaluationUIDelegate respondsToSelector:@selector(carePlanStore:didReceiveUpdateOfEvaluationEvent:)]) {
                    [_evaluationUIDelegate carePlanStore:self didReceiveUpdateOfEvaluationEvent:copiedEvaluationEvent];
                }
                if(_delegate && [_delegate respondsToSelector:@selector(carePlanStore:didReceiveUpdateOfEvaluationEvent:)]) {
                    [_delegate carePlanStore:self didReceiveUpdateOfEvaluationEvent:copiedEvaluationEvent];
                }
            }
        });
    }];
    
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
