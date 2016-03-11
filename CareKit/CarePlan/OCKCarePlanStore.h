//
//  OCKCarePlanStore.h
//  CareKit
//
//  Created by Yuan Zhu on 1/21/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <CareKit/CareKit.h>


NS_ASSUME_NONNULL_BEGIN

@class OCKCarePlanStore;
@class OCKCarePlanActivity;
@class OCKCarePlanEvent;


/**
 Implement this delegate to subscribe to the notifications of changes in this store.
 */
@protocol OCKCarePlanStoreDelegate <NSObject>

@optional

- (void)carePlanStore:(OCKCarePlanStore *)store didReceiveUpdateOfEvent:(OCKCarePlanEvent *)event;

- (void)carePlanStoreActivityListDidChange:(OCKCarePlanStore *)store;

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
- (instancetype)initWithPersistenceDirectoryURL:(NSURL *)url NS_DESIGNATED_INITIALIZER;

/**
 This delegate can be used to subscribe to the notifications of changes in this store.
 */
@property (nonatomic, weak) id<OCKCarePlanStoreDelegate> delegate;

/**
 Add an activity to this store.
 */
- (void)addActivity:(OCKCarePlanActivity *)activity
         completion:(void (^)(BOOL success,  NSError * _Nullable error))completion;

/**
 Get all activities from this store.
 */
- (void)activitiesWithCompletion:(void (^)(BOOL success, NSArray<OCKCarePlanActivity *> *activities, NSError  * _Nullable error))completion;

/**
 Get all activities with specified type from this store.
 */
- (void)activitiesWithType:(OCKCarePlanActivityType)type
                completion:(void (^)(BOOL success, NSArray<OCKCarePlanActivity *> *activities, NSError * _Nullable error))completion;

/**
 Get activity by providing an identifier.
 */
- (void)activityForIdentifier:(NSString *)identifier
                   completion:(void (^)(BOOL success, OCKCarePlanActivity * _Nullable activity, NSError * _Nullable error))completion;


/**
 Get all activities with a specified group identifier.
 */
- (void)activitiesWithGroupIdentifier:(NSString *)groupIdentifier
                           completion:(void (^)(BOOL success, NSArray<OCKCarePlanActivity *> *activities, NSError * _Nullable error))completion;

/**
 Update an activity's end date.
 */
- (void)setEndDate:(NSDateComponents *)date
       forActivity:(OCKCarePlanActivity *)activity
        completion:(void (^)(BOOL success, OCKCarePlanActivity * _Nullable activity, NSError * _Nullable error))completion;

/**
 Remove an activity from this store.
 All its related event records will be removed as well.
 */
- (void)removeActivity:(OCKCarePlanActivity *)activity
            completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

/**
Obtain all `OCKCarePlanEvent` on a giving date.
@disccussion Returned result grouped by `OCKCarePlanActivity`.
*/
- (void)eventsOnDate:(NSDateComponents *)date
                type:(OCKCarePlanActivityType)type
          completion:(void (^)(NSArray<NSArray<OCKCarePlanEvent *> *> *eventsGroupedByActivity, NSError * _Nullable error))completion;

/**
 Obtain all events of a `OCKCarePlanActivity` in a giving date.
 */
- (void)eventsForActivity:(OCKCarePlanActivity *)activity
                     date:(NSDateComponents *)date
               completion:(void (^)(NSArray<OCKCarePlanEvent *> *events, NSError * _Nullable error))completion;

/**
 Mark an `OCKCarePlanEvent` to be completed.
 */
- (void)updateEvent:(OCKCarePlanEvent *)event
         withResult:(nullable OCKCarePlanEventResult *)result
              state:(OCKCarePlanEventState)state
         completion:(void (^)(BOOL success, OCKCarePlanEvent * _Nullable event, NSError * _Nullable error))completion;

/**
 Fetch all the events of an `OCKCarePlanEvent` by giving a date range.
 */
- (void)enumerateEventsOfActivity:(OCKCarePlanActivity *)activity
                        startDate:(NSDateComponents *)startDate
                          endDate:(NSDateComponents *)endDate
                       usingBlock:(void (^)(OCKCarePlanEvent * _Nullable event, BOOL *stop, NSError * _Nullable error))block;

- (void)dailyCompletionStatusWithType:(OCKCarePlanActivityType)type
                            startDate:(NSDateComponents *)startDate
                              endDate:(NSDateComponents *)endDate
                           usingBlock:(void (^)(NSDateComponents * _Nullable date, NSUInteger completed, NSUInteger total, NSError * _Nullable error))block;

@end



NS_ASSUME_NONNULL_END
