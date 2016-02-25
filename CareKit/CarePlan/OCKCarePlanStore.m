//
//  OCKCarePlanStore.m
//  CareKit
//
//  Created by Yuan Zhu on 1/21/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import "OCKCarePlanStore.h"
#import "OCKCarePlanStore_Internal.h"
#import "OCKCarePlanDay_Internal.h"
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
    
    NSError *errorOut = nil;
    
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
                              opBlock:(BOOL (^)(NSManagedObject *cdObject, NSManagedObjectContext *context))opBlock
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
    NSManagedObjectContext *context = [self contextWithError:error];
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
    
    NSManagedObjectContext *context = [self contextWithError:error];
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
    
    NSManagedObjectContext *context = [self contextWithError:error];
    if (context == nil) {
        return 0;
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:name];
    fetchRequest.predicate = predicate;
    
    NSUInteger count = [context countForFetchRequest:fetchRequest error:error];
    return count;
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
    NSManagedObjectContext *context = [self contextWithError:&errorOut];
    
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
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(errorOut == nil, activities , errorOut);
        });
    }];
}

- (void)activitiesWithGroupIdentifier:(NSString *)groupIdentifier
                           completion:(void (^)(BOOL success, NSArray<OCKCarePlanActivity *> *activities, NSError *error))completion {
    NSParameterAssert(groupIdentifier);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"groupIdentifier = %@", groupIdentifier];
    [self fetchActivitiesWithPredicate:predicate completion:completion];
}

- (void)handleActivityListChange:(BOOL)result type:(OCKCarePlanActivityType)type {
    if (result){
        if (type == OCKCarePlanActivityTypeIntervention &&
            _careCardUIDelegate && [_careCardUIDelegate respondsToSelector:@selector(carePlanStoreActivityListDidChange:)]) {
            [_careCardUIDelegate carePlanStoreActivityListDidChange:self];
        }
        if (type == OCKCarePlanActivityTypeAssessment &&
            _checkupsUIDelegate && [_checkupsUIDelegate respondsToSelector:@selector(carePlanStoreActivityListDidChange:)]) {
            [_checkupsUIDelegate carePlanStoreActivityListDidChange:self];
        }
        if (_delegate && [_delegate respondsToSelector:@selector(carePlanStoreActivityListDidChange:)]) {
            [_delegate carePlanStoreActivityListDidChange:self];
        }
    }
}

- (void)addActivity:(OCKCarePlanActivity *)activity
         completion:(void (^)(BOOL success, NSError *error))completion {
    NSParameterAssert(activity);
    
    NSError *errorOut = nil;
    NSManagedObjectContext *context = [self contextWithError:&errorOut];
    
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
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(result, errorOut);
            [self handleActivityListChange:result type:activity.type];
        });
    }];
}

- (void)removeActivity:(OCKCarePlanActivity *)activity
            completion:(void (^)(BOOL success, NSError *error))completion {
    NSParameterAssert(activity);
    
    NSError *errorOut = nil;
    NSManagedObjectContext *context = [self contextWithError:&errorOut];
    
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
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(result, error);
            [self handleActivityListChange:result type:activity.type];
        });
    }];
}

- (void)setEndDay:(OCKCarePlanDay *)day
      forActivity:(OCKCarePlanActivity *)activity
       completion:(void (^)(BOOL success, OCKCarePlanActivity *activity, NSError *error))completion {
    
    NSParameterAssert(activity);
    
    NSError *errorOut = nil;
    NSManagedObjectContext *context = [self contextWithError:&errorOut];
    
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
                                                       schedule.endDay = day;
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
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(result, modifiedActivity, errorOut);
            [self handleActivityListChange:result type:activity.type];
        });
    }];
}

- (void)eventsOfDay:(OCKCarePlanDay *)day
               type:(OCKCarePlanActivityType)type
         completion:(void (^)(NSArray<NSArray<OCKCarePlanEvent *> *> *eventsGroupedByActivity, NSError *error))completion {
    
    
    NSParameterAssert(day);
    
    __block NSMutableArray *eventGroups = [NSMutableArray array];
    
    [self activitiesWithType:type
                  completion:^(BOOL success, NSArray<OCKCarePlanActivity *> * _Nonnull activities, NSError * _Nonnull error) {
                      NSArray<OCKCarePlanActivity *> *items = activities;
                      if (items.count > 0) {
                          __block NSError *errorOut = nil;
                          __block NSInteger processedCount = 0;
                          for (OCKCarePlanActivity *item in items) {
                              [self eventsForActivity:item day:day completion:^(NSArray<OCKCarePlanEvent *> * _Nonnull events, NSError * _Nonnull error) {
                                  if (error == nil && events.count > 0) {
                                      [eventGroups addObject:events];
                                  }
                                  processedCount++;
                                  errorOut = error;
                                  if (items.count == processedCount) {
                                      dispatch_async(dispatch_get_main_queue(), ^{
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
                      day:(OCKCarePlanDay *)day
               completion:(void (^)(NSArray<OCKCarePlanEvent *> *events, NSError *error))completion {
    
    NSParameterAssert(activity);
    NSParameterAssert(day);
    NSParameterAssert(completion);
    
    OCKCareSchedule *schedule = activity.schedule;
    NSUInteger numberOfEvents = [schedule numberOfEventsOnDay:day];
    
   
    NSError *error = nil;
    NSManagedObjectContext *context = [self contextWithError:&error];
    if (context == nil) {
        completion(nil, error);
        return;
    }
    
    NSMutableArray *eventGroup = [NSMutableArray array];
    if (numberOfEvents > 0) {
        
        NSUInteger numberOfDaySinceStart = [schedule numberOfDaySinceStart:day];
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
                
                for (NSInteger index = 0 ; index < numberOfEvents ; index++ ) {
                    OCKCarePlanEvent *event = [savedEvents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"occurrenceIndexOfDay = %d", index]].firstObject;
                    if (event == nil) {
                        event = [[OCKCarePlanEvent alloc] initWithNumberOfDaysSinceStart:numberOfDaySinceStart occurrenceIndexOfDay:index activity:activity];
                    }
                    [eventGroup addObject:event];
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
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
    
    NSParameterAssert(event);
    NSParameterAssert(completion);
    
    NSError *error = nil;
    __block NSManagedObjectContext *context = [self contextWithError:&error];
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
        
        dispatch_async(dispatch_get_main_queue(), ^(){
            completion(result, result ? copiedEvent : event, errorOut);
            
            if (result) {
                
                OCKCarePlanActivityType type = event.activity.type;
                
                if(type == OCKCarePlanActivityTypeIntervention &&
                   _careCardUIDelegate &&
                   [_careCardUIDelegate respondsToSelector:@selector(carePlanStore:didReceiveUpdateOfEvent:)]) {
                    [_careCardUIDelegate carePlanStore:self didReceiveUpdateOfEvent:copiedEvent];
                }
                if(type == OCKCarePlanActivityTypeAssessment
                   && _checkupsUIDelegate
                   && [_checkupsUIDelegate respondsToSelector:@selector(carePlanStore:didReceiveUpdateOfEvent:)]) {
                    [_checkupsUIDelegate carePlanStore:self didReceiveUpdateOfEvent:copiedEvent];
                }
                if(_delegate && [_delegate respondsToSelector:@selector(carePlanStore:didReceiveUpdateOfEvent:)]) {
                    [_delegate carePlanStore:self didReceiveUpdateOfEvent:copiedEvent];
                }
            }
        });
    }];
}

- (void)enumerateEventsOfActivity:(OCKCarePlanActivity *)activity
                         startDay:(OCKCarePlanDay *)startDay
                           endDay:(OCKCarePlanDay *)endDay
                       usingBlock:(void (^)(OCKCarePlanEvent *event, BOOL *stop, NSError *error))block {
    NSParameterAssert(activity);
    NSParameterAssert(startDay);
    NSParameterAssert(endDay);
    NSParameterAssert(block);
    
    if ([startDay isLaterThan:endDay]) {
        return;
    }
    __block OCKCarePlanDay *day = startDay;
    __block BOOL stop = NO;
    __weak typeof(self) weakSelf = self;
    

    void __block (^completion)(NSArray<OCKCarePlanEvent *> *, NSError *) = nil;
    completion = ^(NSArray<OCKCarePlanEvent *> * _Nonnull events, NSError * _Nonnull error) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!stop) {
            for (OCKCarePlanEvent* event in events) {
                block(event, &stop, error);
                if (stop) {
                    break;
                }
            }
            
            day = [day nextDay];
            
            if ((stop == NO && ([day isEarlierThan:endDay] || [day isEqual:endDay]))) {
                [strongSelf eventsForActivity:activity day:day completion:completion];
            } else {
                completion = nil;
            }
        }
    };
    
    [self eventsForActivity:activity
                        day:day
                 completion:completion];
}

- (void)dailyCompletionStatusWithType:(OCKCarePlanActivityType)type
                             startDay:(OCKCarePlanDay *)startDay
                               endDay:(OCKCarePlanDay *)endDay
                           usingBlock:(void (^)(OCKCarePlanDay* day, NSUInteger completed, NSUInteger total, NSError *error))block {

    NSParameterAssert(startDay);
    NSParameterAssert(endDay);
    NSParameterAssert(block);
    
    if ([startDay isLaterThan:endDay]) {
        return;
    }
    
    NSError *error = nil;
    __block NSManagedObjectContext *context = [self contextWithError:&error];
    if (context == nil) {
        block(nil, 0, 0, error);
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self fetchActivitiesWithPredicate:[NSPredicate predicateWithFormat:@"type = %d", type]
                            completion:^(BOOL success, NSArray<OCKCarePlanActivity *> *activities, NSError *error) {
                                if (error) {
                                    block(nil, 0, 0, error);
                                } else {
                                    [context performBlock:^{
                                        __strong typeof(weakSelf) strongSelf = weakSelf;
                                        OCKCarePlanDay *day = startDay;
                                        do {
                                            NSUInteger total = 0;
                                            NSUInteger completed = 0;
                                            NSMutableArray *predicates = [NSMutableArray new];
                                            for (OCKCarePlanActivity *activity in activities) {
                                                NSUInteger count = [activity.schedule numberOfEventsOnDay:day];
                                                
                                                if (count > 0) {
                                                    NSUInteger daysSinceStart = [activity.schedule numberOfDaySinceStart:day];
                                                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"activity.identifier = %@ AND numberOfDaysSinceStart = %d AND state = %d", activity.identifier, daysSinceStart, OCKCarePlanEventStateCompleted];
                                                    [predicates addObject:predicate];
                                                    total += count;
                                                }
                                            }
                                            
                                            NSError *errorOut = nil;
                                            if (total > 0) {
                                                
                                                NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:predicates];
                                                
                                                completed = [strongSelf block_countItemsWithEntityName:OCKEntityNameEvent
                                                                                             predicate:compoundPredicate
                                                                                                 error:&errorOut];
                                            }
                                            
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                block(day, completed, total, errorOut);
                                            });
                                            day = [day nextDay];
                                        } while ([day isEarlierThan:endDay] || [day isEqual:endDay]);
                                    }];
                                }
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
