/*
 Copyright (c) 2017, Apple Inc. All rights reserved.
 
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


#import <CareKit/CareKit.h>
#import <CareKit/OCKDefines.h>


NS_ASSUME_NONNULL_BEGIN

@class OCKCarePlanStore;
@class OCKCarePlanActivity;
@class OCKCarePlanEvent;
@class OCKPatient;

/**
 Implement this delegate to subscribe to the notification of changes in this store.
 */
@protocol OCKCarePlanStoreDelegate <NSObject>

@optional

/**
 Called when an event receives an update.
 
 @param store   The care plan store.
 @param event   The event that has been updated.
 */
- (void)carePlanStore:(OCKCarePlanStore *)store didReceiveUpdateOfEvent:(OCKCarePlanEvent *)event;

/**
 Called when an activity is added to or removed from the store.
 
 @param store   The care plan store.
 */
- (void)carePlanStoreActivityListDidChange:(OCKCarePlanStore *)store;

@end


/**
 An instance of the `OCKCarePlanStore` class represents a care plan database.
 It stores activities and events.
 
 An activity can be added to, or removed from, a store. 
 Once an activity has been added to a store, only the endDate can be changed by using the  setEndDate:forActivity:completion: method. 
 Update the state of an event after the user has responded to it.
 
 You can query the store in the following ways:
 - Get all the activities in the store.
 - Get all the activities of a given type (intervention or assessment) in the store.
 - Get the activity for a given identifier.
 - Get activities for a given group identifier
 - Get the events of a type (intervention or assessment) for a given date.
 - Get the events for a given activity for a given date.
 - Enumerate all the events for a given activity for a range of dates
 - Enumerate the completion status for a given type (intervention or assessment) for a range of dates.
 */
OCK_CLASS_AVAILABLE
@interface OCKCarePlanStore : NSObject

- (instancetype)init NS_UNAVAILABLE;

/**
 The initializer requires an identifier and a local directory URL.
 The directory in the URL must exist, otherwise this initializer raises an exception.
 
 @param     URL                 The directory for the store to save its database file.
 @param     identifier          A unqiue identifier for the store.
 @param     patient             The patient associated with the store.
 
 @return    An instance of the store.
 */
- (instancetype)initWithPersistenceDirectoryURL:(NSURL *)URL
                                     identifier:(NSString *)identifier
                                        patient:(nullable OCKPatient *)patient;

/**
 The initializer requires a local directory URL.
 The directory in the URL must exist, otherwise this initializer raises an exception.
 
 @param     URL        The directory for the store to save its database file.
 
 @return    An instance of the store.
 */
- (instancetype)initWithPersistenceDirectoryURL:(NSURL *)URL;


/**
 A unique identifier for the store at the directory url.
 */
@property (nonatomic, copy, readonly) NSString *identifier;

/**
 The persistence directory url for the store to save its database file.
 */
@property (nonatomic, copy, readonly) NSURL *directoryURL;

/**
 The patient object associated with this care plan store.
 */
@property (nonatomic, copy, readonly, nullable) OCKPatient *patient;

/**
 You can use the delegate to subscribe to notifications of changes to the store.
 */
@property (nonatomic, weak, nullable) id<OCKCarePlanStoreDelegate> delegate;

/**
You can use the watch delegate to subscribe a watch app to notifications of changes to the store.
 */
@property (nonatomic, weak, nullable) id<OCKCarePlanStoreDelegate> watchDelegate;

/**
 The cloud bridge delegate is used to support the Medable, IBM Watson, or CloudMine cloud bridge.
 
 Developers should not use this delegate. Use `delegate` property instead.
 */
@property (nonatomic, weak, nullable) id<OCKCarePlanStoreDelegate> cloudBridgeDelegate;


/**
 Add an activity to this store.
 
 The identifiers for activities in the store should be unique. 
 An activity with a duplicate identifier cannot be added.
 
 @param     activity    Activity object to be added.
 @param     completion  Completion block to return operation result.
 */
- (void)addActivity:(OCKCarePlanActivity *)activity
         completion:(void (^)(BOOL success,  NSError * _Nullable error))completion;

/**
 Get all activities in the store.
 
 @param     completion  A completion block that returns the result of the operation and a list of activities.
 */
- (void)activitiesWithCompletion:(void (^)(BOOL success, NSArray<OCKCarePlanActivity *> *activities, NSError  * _Nullable error))completion;

/**
 Get all activities with specified type from this store.
 
 @param     type        Activity type used to filter the activity list.
 @param     completion  A completion block that returns the result of the operation and a list of activities.
 */
- (void)activitiesWithType:(OCKCarePlanActivityType)type
                completion:(void (^)(BOOL success, NSArray<OCKCarePlanActivity *> *activities, NSError * _Nullable error))completion;

/**
 Gets the activity associated with the provided identifier.
 
 @param     identifier  An activity identifier.
 @param     completion A completion block that returns the result of the operation and an activity (if the activity is in the store).
 */
- (void)activityForIdentifier:(NSString *)identifier
                   completion:(void (^)(BOOL success, OCKCarePlanActivity * _Nullable activity, NSError * _Nullable error))completion;


/**
 Gets the activities associated with the specified group identifier.
 
 @param     groupIdentifier Identifier for a group of activities.
 @param     completion      A completion block that returns the result of the operation and a list of activities.
 */
- (void)activitiesWithGroupIdentifier:(NSString *)groupIdentifier
                           completion:(void (^)(BOOL success, NSArray<OCKCarePlanActivity *> *activities, NSError * _Nullable error))completion;

/**
 Update the end date of an activity.
 Use this method to change the end date of an activity after it has been added to store.
 
 @param     endDate         End date for an activity.
 @param     activity        Activity object to receive new end date.
 @param     completion      A completion block that returns the result of the operation and the activity that was modified.
 */
- (void)setEndDate:(NSDateComponents *)endDate
       forActivity:(OCKCarePlanActivity *)activity
        completion:(void (^)(BOOL success, OCKCarePlanActivity * _Nullable activity, NSError * _Nullable error))completion;

/**
 Remove an activity from this store.
 All the events related to the activity will also be removed.
 
 @param     activity        The activity object to remove.
 @param     completion      A completion block that returns the result of the operation.
 */
- (void)removeActivity:(OCKCarePlanActivity *)activity
            completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

/**
Get all the `OCKCarePlanEvent` objects for a given date.
 
 @disccussion The returned events are grouped by `OCKCarePlanActivity` objects.
 
 @param     date            Date to filter events.
 @param     type            Activity type to filter events.
 @param     completion      A completion block that returns the result of the operation and a list of event objects.
*/
- (void)eventsOnDate:(NSDateComponents *)date
                type:(OCKCarePlanActivityType)type
          completion:(void (^)(NSArray<NSArray<OCKCarePlanEvent *> *> *eventsGroupedByActivity, NSError * _Nullable error))completion;

/**
 Obtain events on a given date and belongs to a `OCKCarePlanActivity` .
 
 @param     activity        Activity to filter events.
 @param     date            Date to filter events.
 @param     completion      A completion block that returns the result of the operation and a list of event objects.
 */
- (void)eventsForActivity:(OCKCarePlanActivity *)activity
                     date:(NSDateComponents *)date
               completion:(void (^)(NSArray<OCKCarePlanEvent *> *events, NSError * _Nullable error))completion;

/**
 Change the state of an event and optionally attach a result object to it.
 All events start with OCKCarePlanEventStateInitial.
 
 @param     event           The event object to modify.
 @param     result          The result to attach (optional).
 @param     state           A new state for the event.
 @param     completion      A completion block that returns the result of the operation and the event that was changed.
 */
- (void)updateEvent:(OCKCarePlanEvent *)event
         withResult:(nullable OCKCarePlanEventResult *)result
              state:(OCKCarePlanEventState)state
         completion:(void (^)(BOOL success, OCKCarePlanEvent * _Nullable event, NSError * _Nullable error))completion;



/**
 Get the daily event completion status within a date range.
 An event with state OCKCarePlanEventStateCompleted is counting towards completed number.
 
 @param     type            Activity type to filter events.
 @param     startDate       Start date of the date range.
 @param     endDate         End date of the date range.
 @param     handler           A completion block that reports completion status for each day.
 @param     completion      A completion block that reports the end of the enumeration.
 */
- (void)dailyCompletionStatusWithType:(OCKCarePlanActivityType)type
                            startDate:(NSDateComponents *)startDate
                              endDate:(NSDateComponents *)endDate
                              handler:(void (^)(NSDateComponents *date, NSUInteger completedEvents, NSUInteger totalEvents))handler
                           completion:(void (^)(BOOL completed, NSError * _Nullable error))completion;

/**
 Enumerate through all the events associated with an OCKCarePlanActivity object within a specified date range.
 
 @param     activity        The activity to which the events belong.
 @param     startDate       Start date of the date range.
 @param     endDate         End date of the date range.
 @param     handler         A completion block that returns each event object.
 @param     completion      A completion block that reports the end of the enumeration.
 */
- (void)enumerateEventsOfActivity:(OCKCarePlanActivity *)activity
                        startDate:(NSDateComponents *)startDate
                          endDate:(NSDateComponents *)endDate
                          handler:(void (^)(OCKCarePlanEvent * _Nullable event, BOOL *stop))handler
                       completion:(void (^)(BOOL completed, NSError * _Nullable error))completion;

/**
 Check the adherance threshold for an activity on a given day.
 
 @param     activity        The activity to check.
 @param     date            The date to check.
 @param     completion      A completion block that returns the result of the operation and a possible triggered threshold object.
 */
- (void)evaluateAdheranceThresholdForActivity:(OCKCarePlanActivity *)activity
                                         date:(NSDateComponents *)date
                                   completion:(void (^)(BOOL success, OCKCarePlanThreshold * _Nullable threshold, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
