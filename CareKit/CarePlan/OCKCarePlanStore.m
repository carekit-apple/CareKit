/*
 Copyright (c) 2016, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "OCKCarePlanStore.h"
#import "OCKCarePlanStore_Internal.h"
#import "NSDateComponents+CarePlanInternal.h"
#import "OCKCarePlanActivity_Internal.h"
#import "OCKCarePlanEvent_Internal.h"
#import "OCKCarePlanEventResult_Internal.h"
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

static NSString * const OCKEntityNameActivity =  @"OCKCDCarePlanActivity";
static NSString * const OCKEntityNameEvent =  @"OCKCDCarePlanEvent";
static NSString * const OCKEntityNameEventResult =  @"OCKCDCarePlanEventResult";

static NSString * const OCKAttributeNameIdentifier = @"identifier";
static NSString * const OCKAttributeNameDayIndex = @"numberOfDaysSinceStart";


@implementation OCKCarePlanStore {
    NSURL *_persistenceDirectoryURL;
    NSArray *_cachedActivities;
    dispatch_queue_t _queue;
    NSManagedObjectContext *_managedObjectContext;
    HKHealthStore *_healthStore;
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithPersistenceDirectoryURL:(NSURL *)url {
    NSAssert([NSThread currentThread].isMainThread, @"OCKCarePlanStore initialization must be on main thread");
    OCKThrowInvalidArgumentExceptionIfNil(url);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    BOOL exist = [fileManager fileExistsAtPath:url.path isDirectory:&isDirectory];
    if (exist == NO) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"persistenceDirectoryURL does not exist." userInfo:nil];
    }
    if (isDirectory == NO) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"persistenceDirectoryURL is not a directory." userInfo:nil];
    }
    
    self = [super init];
    if (self) {
        _persistenceDirectoryURL = url;
        _queue = dispatch_queue_create("CarePlanStore", DISPATCH_QUEUE_SERIAL);
        NSError *error = nil;
        [self setUpContextWithError:&error];
        if (_managedObjectContext == nil) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Failed to create a CoreData context." userInfo:@{@"error": error ? : @""}];
        }
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

    NSManagedObjectContext *context = _managedObjectContext;
    if (nil == context) {
        return NO;
    }
    
    NSError *errorOut = nil;
    
    OCKCarePlanActivity *item = [self block_fetchItemWithEntityName:entityName
                                                         identifier:sourceItem.identifier
                                                              class:[OCKCarePlanActivity class]
                                                              error:&errorOut];
    if (nil != errorOut) {
        if (nil != error) {
            *error = errorOut;
        }
        return NO;
    }

    if (nil != item) {
        if (nil != error) {
            NSString *reasonString = [NSString stringWithFormat:@"An activity with the identifier %@ already exists.", sourceItem.identifier];
            *error = [NSError errorWithDomain:OCKErrorDomain code:OCKErrorInvalidObject userInfo:@{@"reason":reasonString}];
        }
        return NO;
    }
    
    NSManagedObject *cdObject;
    cdObject = [[coreDataClass alloc] initWithEntity:[NSEntityDescription entityForName:entityName
                                                                 inManagedObjectContext:context]
                      insertIntoManagedObjectContext:context
                                                item:sourceItem];

    BOOL savedSuccessfully = [context save:&errorOut];

    if (nil != error) {
        *error = errorOut;
    }

    return savedSuccessfully;
}

- (BOOL)block_alterItemWithEntityName:(NSString *)name
                           identifier:(NSString *)identifier
                              opBlock:(BOOL (^)(NSManagedObject *cdObject, NSManagedObjectContext *context))opBlock
                                error:(NSError **)error {
    NSParameterAssert(name);
    NSParameterAssert(identifier);
    NSParameterAssert(opBlock);
    
    NSManagedObjectContext *context = _managedObjectContext;
    if (context == nil) {
        return NO;
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:name];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K = %@",
                              OCKAttributeNameIdentifier, identifier];
    
    NSError *errorOut = nil;
    
    NSArray *managedObjects = [context executeFetchRequest:fetchRequest error:&errorOut];
    
    BOOL saved = YES;
    if (managedObjects.count > 0 && errorOut == nil) {
        opBlock(managedObjects.firstObject, context);
        saved = [context save:&errorOut];
    }
    
    if (!saved && error) {
        *error = errorOut;
    }

    return saved;
}

- (id)block_fetchItemWithEntityName:(NSString *)name
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
    NSManagedObjectContext *context = _managedObjectContext;
    if (context == nil) {
        return NO;
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:name];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K = %@",
                              OCKAttributeNameIdentifier, identifier];
    
    NSError *errorOut = nil;
    BOOL found = NO;
    
    NSArray *managedObjects = [context executeFetchRequest:fetchRequest error:&errorOut];
    
    BOOL saved = YES;
    if (managedObjects.count > 0 && errorOut == nil) {
        found = YES;
        [context deleteObject:managedObjects.firstObject];
        saved = [context save:&errorOut];
    } else if (managedObjects.count == 0 && errorOut == nil) {
        errorOut = [NSError errorWithDomain:OCKErrorDomain code:OCKErrorObjectNotFound userInfo:@{@"reason" : @"Item not found."}];
    }
    
    if (error && errorOut) {
        *error = errorOut;
    }
    
    return (found && saved);
}

- (NSArray *)block_fetchItemsWithEntityName:(NSString *)name
                                                         class:(Class)containerClass
                                                         error:(NSError **)error {
    NSParameterAssert(name);
    NSParameterAssert(containerClass);
    return [self block_fetchItemsWithEntityName:name predicate:nil class:containerClass error:error];
}


- (NSArray *)block_fetchItemsWithEntityName:(NSString *)name
                                  predicate:(NSPredicate *)predicate
                                      class:(Class)containerClass
                                      error:(NSError **)error {
    NSParameterAssert(name);
    NSParameterAssert(containerClass);
    
    NSManagedObjectContext *context = _managedObjectContext;
    if (context == nil) {
        return nil;
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:name];
    fetchRequest.predicate = predicate;
    
    NSError *errorOut = nil;
    NSMutableArray<OCKCarePlanActivity *> *items = [NSMutableArray new];
   
    NSArray *managedObjects = [context executeFetchRequest:fetchRequest error:&errorOut];
    for (NSManagedObject *object in managedObjects) {
        [items addObject:[[containerClass alloc] initWithCoreDataObject:object]];
    }
    return [items copy];
}

- (NSUInteger)block_countItemsWithEntityName:(NSString *)name
                                   predicate:(NSPredicate *)predicate
                                       error:(NSError **)error {
    NSParameterAssert(name);
    
    NSManagedObjectContext *context = _managedObjectContext;
    if (context == nil) {
        return 0;
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:name];
    fetchRequest.predicate = predicate;
    
    NSUInteger count = [context countForFetchRequest:fetchRequest error:error];
    return count;
}

- (void)block_fetchHKSampleForEvents:(NSArray<OCKCarePlanEvent *> *)events {
    if (events.count == 0) {
        return;
    }
    
    if (!_healthStore && [HKHealthStore isHealthDataAvailable]) {
        _healthStore = [HKHealthStore new];
    }
    
    if (!_healthStore) {
        return;
    }
 
    NSArray<OCKCarePlanEvent *> * eventsHasResult = [events filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"result.sampleType != nil"]];
    NSArray<OCKCarePlanEventResult *> *results = [eventsHasResult valueForKeyPath:@"result"];
    
    NSMutableDictionary<HKSampleType *, NSMutableArray<OCKCarePlanEventResult *> *> *dictionary = [NSMutableDictionary new];
    for (OCKCarePlanEventResult *result in results) {
        if (dictionary[result.sampleType]) {
            [dictionary[result.sampleType] addObject:result];
        } else {
            dictionary[result.sampleType] = [NSMutableArray arrayWithObject:result];
        }
    }
    
    NSArray<HKSampleType *> *types = [dictionary allKeys];
    
    for (HKSampleType *type in types) {
        NSMutableArray<OCKCarePlanEventResult *> *sameTypeResults = dictionary[type];
        NSArray *sampleUUIDs = [sameTypeResults valueForKeyPath:@"sampleUUID"];
        
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:type
                                                               predicate:[HKQuery predicateForObjectsWithUUIDs:[NSSet setWithArray:sampleUUIDs]]
                                                                   limit:sampleUUIDs.count
                                                         sortDescriptors:nil
                                                          resultsHandler:^(HKSampleQuery * _Nonnull query,
                                                                           NSArray<__kindof HKSample *> * _Nullable results,
                                                                           NSError * _Nullable error) {
                                                              
                                                              for (HKSample *sample in results) {
                                                                  OCKCarePlanEventResult *result = [sameTypeResults filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"sampleUUID = %@", sample.UUID]].firstObject;
                                                                  [result setSample:sample];
                                                              }
                                                              dispatch_semaphore_signal(sem);
                                                          }];
        
        [_healthStore executeQuery:query];
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    }
}


#pragma mark - activities

- (void)activitiesWithType:(OCKCarePlanActivityType)type
                completion:(void (^)(BOOL success, NSArray<OCKCarePlanActivity *> *activities, NSError *error))completion {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type = %@", @(type)];
    return [self fetchActivitiesWithPredicate:predicate completion:completion];
}

- (void)activityForIdentifier:(NSString *)identifier
                   completion:(void (^)(BOOL success, OCKCarePlanActivity *activity, NSError *error))completion {
    NSParameterAssert(identifier);
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier = %@", identifier];
    [self fetchActivitiesWithPredicate:predicate completion:^(BOOL success, NSArray<OCKCarePlanActivity *> *activities, NSError *error) {
        completion(success, activities.firstObject, error);
    }];
}

- (void)activitiesWithCompletion:(void (^)(BOOL success, NSArray<OCKCarePlanActivity *> *activities, NSError *error))completion {
    [self fetchActivitiesWithPredicate:nil completion:completion];
}

- (void)fetchActivitiesWithPredicate:(NSPredicate *)predicate
                          completion:(void (^)(BOOL success, NSArray<OCKCarePlanActivity *> *activities, NSError *error))completion {
    NSError *errorOut = nil;
    NSManagedObjectContext *context = _managedObjectContext;
    
    if (context == nil) {
        completion(NO, nil, errorOut);
        return;
    }
    __weak typeof(self) weakSelf = self;
    [context performBlock:^{
        
        if (_cachedActivities == nil) {
            NSError *errorOut = nil;
            __strong typeof(weakSelf) strongSelf = weakSelf;
            _cachedActivities = [strongSelf block_fetchItemsWithEntityName:OCKEntityNameActivity class:[OCKCarePlanActivity class] error:&errorOut];
        }
        NSArray *activities = _cachedActivities;
        if (predicate) {
            activities = [_cachedActivities filteredArrayUsingPredicate:predicate];
        }
        dispatch_async(_queue, ^{
            completion(errorOut == nil, activities , errorOut);
        });
    }];
}

- (void)activitiesWithGroupIdentifier:(NSString *)groupIdentifier
                           completion:(void (^)(BOOL success, NSArray<OCKCarePlanActivity *> *activities, NSError *error))completion {
    OCKThrowInvalidArgumentExceptionIfNil(groupIdentifier);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"groupIdentifier = %@", groupIdentifier];
    [self fetchActivitiesWithPredicate:predicate completion:completion];
}

- (void)handleActivityListChange:(BOOL)result type:(OCKCarePlanActivityType)type {
    if (result){
        dispatch_async(dispatch_get_main_queue(), ^{
            if (type == OCKCarePlanActivityTypeIntervention &&
                _careCardUIDelegate && [_careCardUIDelegate respondsToSelector:@selector(carePlanStoreActivityListDidChange:)]) {
                [_careCardUIDelegate carePlanStoreActivityListDidChange:self];
            }
            if (type == OCKCarePlanActivityTypeAssessment &&
                _symptomTrackerUIDelegate && [_symptomTrackerUIDelegate respondsToSelector:@selector(carePlanStoreActivityListDidChange:)]) {
                [_symptomTrackerUIDelegate carePlanStoreActivityListDidChange:self];
            }
            if (_delegate && [_delegate respondsToSelector:@selector(carePlanStoreActivityListDidChange:)]) {
                [_delegate carePlanStoreActivityListDidChange:self];
            }
        });
    }
}

- (void)addActivity:(OCKCarePlanActivity *)activity
         completion:(void (^)(BOOL success, NSError *error))completion {
    OCKThrowInvalidArgumentExceptionIfNil(activity);
    
    NSError *errorOut = nil;
    NSManagedObjectContext *context = _managedObjectContext;
    
    if (context == nil) {
        completion(NO, errorOut);
        return;
    }
    
    __block BOOL result = NO;
    __weak typeof(self) weakSelf = self;
    [context performBlock:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSError *errorOut = nil;
        result = [strongSelf block_addItemWithEntityName:OCKEntityNameActivity coreDataClass:[OCKCDCarePlanActivity class] sourceItem:activity error:&errorOut];
        if (result) {
            _cachedActivities = nil;
        }
        dispatch_async(_queue, ^{
            completion(result, errorOut);
            [self handleActivityListChange:result type:activity.type];
        });
    }];
}

- (void)removeActivity:(OCKCarePlanActivity *)activity
            completion:(void (^)(BOOL success, NSError *error))completion {
    OCKThrowInvalidArgumentExceptionIfNil(activity);
    
    NSError *errorOut = nil;
    NSManagedObjectContext *context = _managedObjectContext;
    
    if (context == nil) {
        completion(NO, errorOut);
        return;
    }
    
    __block BOOL result = NO;
    __weak typeof(self) weakSelf = self;
    [context performBlock:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSError *error = nil;
        result = [strongSelf block_removeItemWithEntityName:OCKEntityNameActivity identifier:activity.identifier error:&error];
        if (result) {
            _cachedActivities = nil;
        }
        
        dispatch_async(_queue, ^{
            completion(result, error);
            [self handleActivityListChange:result type:activity.type];
        });
    }];
}

- (void)setEndDate:(NSDateComponents *)day
      forActivity:(OCKCarePlanActivity *)activity
       completion:(void (^)(BOOL success, OCKCarePlanActivity *activity, NSError *error))completion {
    
    OCKThrowInvalidArgumentExceptionIfNil(activity);
    
    NSError *errorOut = nil;
    NSManagedObjectContext *context = _managedObjectContext;
    
    if (context == nil) {
        completion(NO, nil, errorOut);
        return;
    }
    
    __block BOOL result = NO;
    __weak typeof(self) weakSelf = self;
    [context performBlock:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        NSError *errorOut = nil;
        result = [strongSelf block_alterItemWithEntityName:OCKEntityNameActivity
                                                identifier:activity.identifier
                                                   opBlock:^BOOL(NSManagedObject *cdObject, NSManagedObjectContext *context) {
                                                       OCKCDCarePlanActivity *cdActivity = (OCKCDCarePlanActivity *)cdObject;
                                                       OCKCareSchedule *schedule = [cdActivity.schedule copy];
                                                       schedule.endDate = day;
                                                       cdActivity.schedule = schedule;
                                                       return YES;
                                                   } error:&errorOut];
        OCKCarePlanActivity *modifiedActivity;
        if (result) {
            _cachedActivities = nil;
            modifiedActivity = [strongSelf block_fetchItemWithEntityName:OCKEntityNameActivity
                                                              identifier:activity.identifier
                                                                   class:[OCKCarePlanActivity class]
                                                                   error:&errorOut];
        }
        dispatch_async(_queue, ^{
            completion(result, modifiedActivity, errorOut);
            [self handleActivityListChange:result type:activity.type];
        });
    }];
}

- (void)eventsOnDate:(NSDateComponents *)date
               type:(OCKCarePlanActivityType)type
         completion:(void (^)(NSArray<NSArray<OCKCarePlanEvent *> *> *eventsGroupedByActivity, NSError *error))completion {
    
    
    OCKThrowInvalidArgumentExceptionIfNil(date);
    date = [date validatedDateComponents];
    
    __block NSMutableArray *eventGroups = [NSMutableArray array];
    
    [self activitiesWithType:type
                  completion:^(BOOL success, NSArray<OCKCarePlanActivity *> * _Nonnull activities, NSError * _Nonnull error) {
                      NSArray<OCKCarePlanActivity *> *items = activities;
                      if (items.count > 0) {
                          __block NSError *errorOut = nil;
                          __block NSInteger processedCount = 0;
                          for (OCKCarePlanActivity *item in items) {
                              [self eventsForActivity:item date:date completion:^(NSArray<OCKCarePlanEvent *> * _Nonnull events, NSError * _Nonnull error) {
                                  if (error == nil && events.count > 0) {
                                      [eventGroups addObject:events];
                                  }
                                  processedCount++;
                                  errorOut = error;
                                  if (items.count == processedCount) {
                                      dispatch_async(_queue, ^{
                                          completion(eventGroups, errorOut);
                                      });
                                  }
                              }];
                          }
                      } else {
                           completion(eventGroups, error);
                      }
                      
                  }];
    
}

- (void)eventsForActivity:(OCKCarePlanActivity *)activity
                     date:(NSDateComponents *)date
               completion:(void (^)(NSArray<OCKCarePlanEvent *> *events, NSError *error))completion {
    
    OCKThrowInvalidArgumentExceptionIfNil(activity);
    OCKThrowInvalidArgumentExceptionIfNil(date);
    date = [date validatedDateComponents];
    OCKThrowInvalidArgumentExceptionIfNil(completion);
    
    OCKCareSchedule *schedule = activity.schedule;
    NSUInteger numberOfEvents = [schedule numberOfEventsOnDate:date];
    
   
    NSError *error = nil;
    NSManagedObjectContext *context = _managedObjectContext;
    if (context == nil) {
        completion(nil, error);
        return;
    }
    
    NSMutableArray *eventGroup = [NSMutableArray array];
    if (numberOfEvents > 0) {
        
        NSUInteger numberOfDaySinceStart = [schedule numberOfDaySinceStart:date];
        __weak typeof(self) weakSelf = self;
        [context performBlock:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            NSError *error = nil;
            OCKCarePlanActivity *fetchActivity = [strongSelf block_fetchItemWithEntityName:OCKEntityNameActivity identifier:activity.identifier class:[OCKCarePlanActivity class] error:&error];
            
            if (!fetchActivity) {
                error = [NSError errorWithDomain:OCKErrorDomain
                                            code:OCKErrorInvalidObject
                                        userInfo:@{@"reason":[NSString stringWithFormat:@"Cannot find acitivity with identifier %@", fetchActivity.identifier]}];
            } else {
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %d AND %K = %@",
                                          OCKAttributeNameDayIndex, numberOfDaySinceStart, @"activity.identifier", fetchActivity.identifier];
                NSArray<OCKCarePlanEvent *> *savedEvents = (NSArray<OCKCarePlanEvent *> *)[strongSelf block_fetchItemsWithEntityName:OCKEntityNameEvent
                                                                                                                           predicate:predicate
                                                                                                                               class:[OCKCarePlanEvent class]
                                                                                                                               error:&error];
                
                [self block_fetchHKSampleForEvents:savedEvents];
                
                for (NSInteger index = 0 ; index < numberOfEvents ; index++ ) {
                    OCKCarePlanEvent *event = [savedEvents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"occurrenceIndexOfDay = %d", index]].firstObject;
                    if (event == nil) {
                        event = [[OCKCarePlanEvent alloc] initWithNumberOfDaysSinceStart:numberOfDaySinceStart occurrenceIndexOfDay:index activity:activity];
                    }
                    [eventGroup addObject:event];
                }
            }
            
            dispatch_async(_queue, ^{
                completion([eventGroup copy], error);
            });
        }];
    } else {
        completion([eventGroup copy], nil);
    }
}

- (void)updateEvent:(OCKCarePlanEvent *)event
         withResult:(OCKCarePlanEventResult *)result
              state:(OCKCarePlanEventState)state
         completion:(void (^)(BOOL success, OCKCarePlanEvent *event, NSError *error))completion {
    
    OCKThrowInvalidArgumentExceptionIfNil(event);
    OCKThrowInvalidArgumentExceptionIfNil(completion);
    
    NSError *error = nil;
    __block NSManagedObjectContext *context = _managedObjectContext;
    if (context == nil) {
        completion(NO, event, error);
        return;
    }
    
    OCKCarePlanEvent *copiedEvent = [event copy];
    copiedEvent.state = state;
    copiedEvent.result = result;
    
    __block NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:OCKEntityNameEvent];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K = %d AND %K = %d AND %K = %@",
                              @"occurrenceIndexOfDay", event.occurrenceIndexOfDay,
                              @"numberOfDaysSinceStart", event.numberOfDaysSinceStart,
                              @"activity.identifier", event.activity.identifier
                              ];
    
    __block NSError *errorOut = nil;
    __block BOOL found = NO;
    __block BOOL saved = YES;
    
    [context performBlock:^{
        
        NSArray<OCKCDCarePlanEvent *> *cdEvents = [context executeFetchRequest:fetchRequest error:&errorOut];
        if (errorOut == nil) {
            
            if (cdEvents.count > 0) {
                
                // If the event exists
                found = YES;
                OCKCDCarePlanEvent *cdEvent = cdEvents.firstObject;
                
                OCKCDCarePlanEventResult *cdResult;
                if (copiedEvent.result) {
                    
                    NSEntityDescription *resultEntity = [NSEntityDescription entityForName:OCKEntityNameEventResult
                                                                    inManagedObjectContext:context];
                    
                    cdResult = [[OCKCDCarePlanEventResult alloc] initWithEntity:resultEntity
                                                 insertIntoManagedObjectContext:context
                                                                         result:copiedEvent.result
                                                                          event:cdEvent];
                }
                
                [cdEvent updateWithState:copiedEvent.state result:cdResult];

                saved = [context save:&errorOut];
                
            } else {
                
                //Find the treatment first
                fetchRequest = [NSFetchRequest fetchRequestWithEntityName:OCKEntityNameActivity];
                fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K = %@",
                                          OCKAttributeNameIdentifier, event.activity.identifier];
                
                NSArray<OCKCDCarePlanActivity *> *cdActivities = [context executeFetchRequest:fetchRequest error:&errorOut];
                
                if (errorOut == nil) {
                    if (cdActivities.count > 0) {
                        found = YES;
                        
                        // Create the event with activity
                        OCKCDCarePlanActivity *cdActivity = cdActivities.firstObject;
                        NSEntityDescription *entity = [NSEntityDescription entityForName:OCKEntityNameEvent
                                                                  inManagedObjectContext:context];
                        
                        OCKCDCarePlanEvent *cdEvent = [[OCKCDCarePlanEvent alloc] initWithEntity:entity
                                                                  insertIntoManagedObjectContext:context
                                                                                           event:copiedEvent
                                                                                        cdResult:nil
                                                                                      cdActivity:cdActivity];
                        
                        OCKCDCarePlanEventResult *cdResult;
                        if (copiedEvent.result) {
                            
                            NSEntityDescription *resultEntity = [NSEntityDescription entityForName:OCKEntityNameEventResult
                                                                            inManagedObjectContext:context];
                            
                            cdResult = [[OCKCDCarePlanEventResult alloc] initWithEntity:resultEntity
                                                         insertIntoManagedObjectContext:context
                                                                                 result:copiedEvent.result
                                                                                  event:cdEvent];
                        }
                        
                        [cdEvent updateWithState:copiedEvent.state result:cdResult];
                        saved = [context save:&errorOut];
                    }
                }
            }
        }
        
        BOOL result = saved && errorOut == nil && found;
        
        if (errorOut == nil && found == NO) {
            errorOut = [NSError errorWithDomain:OCKErrorDomain code:OCKErrorObjectNotFound userInfo:@{@"reason": @"Event not found."}];
        }
        
        dispatch_async(_queue, ^(){
            completion(result, result ? copiedEvent : event, errorOut);
            
            if (result) {
                
                OCKCarePlanActivityType type = event.activity.type;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(type == OCKCarePlanActivityTypeIntervention &&
                       _careCardUIDelegate &&
                       [_careCardUIDelegate respondsToSelector:@selector(carePlanStore:didReceiveUpdateOfEvent:)]) {
                        [_careCardUIDelegate carePlanStore:self didReceiveUpdateOfEvent:copiedEvent];
                    }
                    if(type == OCKCarePlanActivityTypeAssessment
                       && _symptomTrackerUIDelegate
                       && [_symptomTrackerUIDelegate respondsToSelector:@selector(carePlanStore:didReceiveUpdateOfEvent:)]) {
                        [_symptomTrackerUIDelegate carePlanStore:self didReceiveUpdateOfEvent:copiedEvent];
                    }
                    if(_delegate && [_delegate respondsToSelector:@selector(carePlanStore:didReceiveUpdateOfEvent:)]) {
                        [_delegate carePlanStore:self didReceiveUpdateOfEvent:copiedEvent];
                    }
                });
            }
        });
    }];
}

- (void)enumerateEventsOfActivity:(OCKCarePlanActivity *)activity
                        startDate:(NSDateComponents *)startDate
                          endDate:(NSDateComponents *)endDate
                          handler:(void (^)(OCKCarePlanEvent * _Nullable event, BOOL *stop))handler
                       completion:(void (^)(BOOL completed, NSError * _Nullable error))completion {
    
    OCKThrowInvalidArgumentExceptionIfNil(activity);
    OCKThrowInvalidArgumentExceptionIfNil(startDate);
    startDate = [startDate validatedDateComponents];
    OCKThrowInvalidArgumentExceptionIfNil(endDate);
    endDate = [endDate validatedDateComponents];
    OCKThrowInvalidArgumentExceptionIfNil(handler);
    OCKThrowInvalidArgumentExceptionIfNil(completion);
    
    if ([startDate isLaterThan:endDate]) {
        dispatch_async(_queue, ^{
            completion(YES, nil);
        });
        return;
    }
    __block NSDateComponents *day = startDate;
    __block BOOL stop = NO;
    __weak typeof(self) weakSelf = self;
    
    void __block (^completion2)(NSArray<OCKCarePlanEvent *> *, NSError *) = nil;
    completion2 = ^(NSArray<OCKCarePlanEvent *> * _Nonnull events, NSError * _Nonnull error) {
        if (error) {
            completion(YES, error);
        } else if (!stop) {
            
            for (OCKCarePlanEvent* event in events) {
                handler(event, &stop);
                if (stop) {
                    break;
                }
            }
            
            day = [day nextDay];
            
            if ((stop == NO && ([day isEarlierThan:endDate] || [day isEqualToDate:endDate]))) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [strongSelf eventsForActivity:activity date:day completion:completion2];
            } else {
                completion2 = nil;
                completion(YES, nil);
            }
            
        } else {
            completion2 = nil;
        }
    };
    
    [self eventsForActivity:activity
                        date:day
                 completion:completion2];
}

- (void)dailyCompletionStatusWithType:(OCKCarePlanActivityType)type
                            startDate:(NSDateComponents *)startDate
                              endDate:(NSDateComponents *)endDate
                              handler:(void (^)(NSDateComponents *date, NSUInteger completed, NSUInteger total))handler
                           completion:(void (^)(BOOL completed, NSError * _Nullable error))completion {

    OCKThrowInvalidArgumentExceptionIfNil(startDate);
    startDate = [startDate validatedDateComponents];
    OCKThrowInvalidArgumentExceptionIfNil(endDate);
    endDate = [endDate validatedDateComponents];
    OCKThrowInvalidArgumentExceptionIfNil(handler);
    OCKThrowInvalidArgumentExceptionIfNil(completion);
    
    if ([startDate isLaterThan:endDate]) {
        dispatch_async(_queue, ^{
            completion(YES, nil);
        });
        return;
    }
    
    NSError *error = nil;
    __block NSManagedObjectContext *context = _managedObjectContext;
    if (context == nil) {
        dispatch_async(_queue, ^{
            completion(YES, error);
        });
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self fetchActivitiesWithPredicate:[NSPredicate predicateWithFormat:@"type = %d", type]
                            completion:^(BOOL success, NSArray<OCKCarePlanActivity *> *activities, NSError *error) {
                                if (error) {
                                    completion(YES, error);
                                } else {
                                    [context performBlock:^{
                                        __strong typeof(weakSelf) strongSelf = weakSelf;
                                        NSDateComponents *day = startDate;
                                        NSError *errorOut = nil;
                                        do {
                                            NSUInteger total = 0;
                                            NSUInteger completed = 0;
                                            NSMutableArray *predicates = [NSMutableArray new];
                                            for (OCKCarePlanActivity *activity in activities) {
                                                NSUInteger count = [activity.schedule numberOfEventsOnDate:day];
                                                
                                                if (count > 0) {
                                                    NSUInteger daysSinceStart = [activity.schedule numberOfDaySinceStart:day];
                                                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"activity.identifier = %@ AND numberOfDaysSinceStart = %d AND state = %d", activity.identifier, daysSinceStart, OCKCarePlanEventStateCompleted];
                                                    [predicates addObject:predicate];
                                                    total += count;
                                                }
                                            }
                                            
                                            errorOut = nil;
                                            if (total > 0) {
                                                NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:predicates];
                                                completed = [strongSelf block_countItemsWithEntityName:OCKEntityNameEvent
                                                                                             predicate:compoundPredicate
                                                                                                 error:&errorOut];
                                            }
                                            dispatch_async(_queue, ^{
                                                 handler(day, completed, total);
                                            });
                    
                                            day = [day nextDay];
                                        } while (errorOut == nil && ( [day isEarlierThan:endDate] || [day isEqualToDate:endDate] ));
                                        
                                        dispatch_async(_queue, ^{
                                            completion(YES, errorOut);
                                        });
                                    }];
                                }
                            }];
}


#pragma mark - coredata

static NSString * const OCKCarePlanModelName =  @"OCKCarePlanStore";

- (void)setUpContextWithError:(NSError **)error {
    if (_managedObjectContext == nil) {
        NSURL *modelURL = [OCKBundle() URLForResource:OCKCarePlanModelName
                                        withExtension:@"momd"];
        NSURL *storeURL = [NSURL fileURLWithPath:[self coredataFilePath]];
        _managedObjectContext = createManagedObjectContext(modelURL, storeURL, error);
        OCK_Log_Debug(@"%@", storeURL);
    }
}

@end
