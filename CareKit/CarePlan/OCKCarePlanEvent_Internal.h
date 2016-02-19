//
//  OCKCareEvent_Internal.h
//  CareKit
//
//  Created by Yuan Zhu on 2/2/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import <CareKit/CareKit.h>
#import <CoreData/CoreData.h>
#import "OCKCarePlanActivity_Internal.h"
#import "OCKCarePlanEventResult_Internal.h"

NS_ASSUME_NONNULL_BEGIN

@interface OCKCarePlanEvent () <OCKCoreDataObjectMirroring, NSCopying>

- (instancetype)initWithNumberOfDaysSinceStart:(NSUInteger)numberOfDaysSinceStart
                          occurrenceIndexOfDay:(NSUInteger)occurrenceIndexOfDay
                                      activity:(OCKCarePlanActivity *)activity;

@property (nonatomic) OCKCarePlanEventState state;

@property (nonatomic, nullable) OCKCarePlanEventResult *result;

@end

@class OCKCDCarePlanEventResult;
@interface OCKCDCarePlanEvent : NSManagedObject

- (instancetype)initWithEntity:(NSEntityDescription *)entity
insertIntoManagedObjectContext:(nullable NSManagedObjectContext *)context
                         event:(OCKCarePlanEvent *)event
                      cdResult:(nullable OCKCDCarePlanEventResult *)cdResult
                    cdActivity:(OCKCDCarePlanActivity *)cdActivity;

- (void)updateWithState:(OCKCarePlanEventState)state result:(nullable OCKCDCarePlanEventResult *)result;

@end

@class OCKCDCarePlanEventResult;
@interface OCKCDCarePlanEvent (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *occurrenceIndexOfDay;
@property (nullable, nonatomic, retain) NSNumber *numberOfDaysSinceStart;
@property (nullable, nonatomic, retain) NSNumber *state;
@property (nullable, nonatomic, retain) OCKCDCarePlanEventResult *result;
@property (nullable, nonatomic, retain) OCKCDCarePlanActivity *activity;

@end





NS_ASSUME_NONNULL_END
