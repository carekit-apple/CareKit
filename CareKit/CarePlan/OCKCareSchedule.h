//
//  OCKCareSchedule.h
//  CareKit
//
//  Created by Yuan Zhu on 1/29/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, OCKCareScheduleType) {
    OCKCareScheduleTypeDaily,
    OCKCareScheduleTypeWeekly,
    OCKCareScheduleTypeMonthly
};

@class OCKCarePlanDay;

@interface OCKCareSchedule : NSObject <NSSecureCoding, NSCopying>

- (instancetype)init NS_UNAVAILABLE;

/*
 Define a schedule has same number of occurrences every day.
 End day can be set later through CarePlanStore.
 */
+ (instancetype)dailyScheduleWithStartDay:(OCKCarePlanDay *)startDay
                        occurrencesPerDay:(NSUInteger)occurrencesPerDay;

/*
 Define a schedule is repeating every week.
 Each weekday can have different number of occurrences.
 End day can be set later through CarePlanStore.
 */
+ (instancetype)weeklyScheduleWithStartDay:(OCKCarePlanDay *)startDay
                      occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFromSundayToSaturday;

/*
 Define a schedule is repeating every month.
 Each day in a month can have different number of occurrences.
 End day can be set later through CarePlanStore.
 */
+ (instancetype)monthlyScheduleWithStartDay:(OCKCarePlanDay *)startDay
                       occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFrom1stTo31th;

/*
 Define a schedule has same number of occurrences every day.
 End day can be set later through CarePlanStore.
 @param daysToSkip  Number of days betwen two active days, this schedule has no occurrence. 
                    
 */
+ (instancetype)dailyScheduleWithStartDay:(OCKCarePlanDay *)startDay
                        occurrencesPerDay:(NSUInteger)occurrencesPerDay
                               daysToSkip:(NSUInteger)daysToSkip
                                   endDay:(nullable OCKCarePlanDay *)endDay;

/*
 Define a schedule is repeating every week.
 Each weekday can have different number of occurrences.
 @param daysToSkip  Number of days betwen two active days, this schedule has no occurrence.
 */
+ (instancetype)weeklyScheduleWithStartDay:(OCKCarePlanDay *)startDay
                      occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFromSundayToSaturday
                               weeksToSkip:(NSUInteger)weeksToSkip
                                    endDay:(nullable OCKCarePlanDay *)endDay;

/*
 Define a schedule is repeating every month.
 Each day in a month can have different number of occurrences.
 @param daysToSkip  Number of days betwen two active days, this schedule has no occurrence. 
 
 */
+ (instancetype)monthlyScheduleWithStartDay:(OCKCarePlanDay *)startDay
                       occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFrom1stTo31th
                               monthsToSkip:(NSUInteger)monthsToSkip
                                     endDay:(nullable OCKCarePlanDay *)endDay;

@property (nonatomic, readonly) OCKCareScheduleType type;

@property (nonatomic, strong, readonly) OCKCarePlanDay *startDay;

@property (nonatomic, strong, readonly, nullable) OCKCarePlanDay *endDay;

@property (nonatomic, copy, readonly) NSArray<NSNumber *> *occurrences;

@property (nonatomic, readonly) NSUInteger timeUnitsToSkip;

- (NSUInteger)numberOfEventsOnDay:(OCKCarePlanDay *)day;

@end



NS_ASSUME_NONNULL_END
