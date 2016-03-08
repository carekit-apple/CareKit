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


@interface OCKCareSchedule : NSObject <NSSecureCoding, NSCopying>

- (instancetype)init NS_UNAVAILABLE;

/**
 Define a schedule has same number of occurrences every day.
 End date can be set later through CarePlanStore.
 */
+ (instancetype)dailyScheduleWithStartDate:(NSDateComponents *)startDate
                         occurrencesPerDay:(NSUInteger)occurrencesPerDay;

/**
 Define a schedule is repeating every week.
 Each weekday can have different number of occurrences.
 End date can be set later through CarePlanStore.
 */
+ (instancetype)weeklyScheduleWithStartDate:(NSDateComponents *)startDate
                       occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFromSundayToSaturday;

/**
 Define a schedule is repeating every month.
 Each day in a month can have different number of occurrences.
 End date can be set later through CarePlanStore.
 */
+ (instancetype)monthlyScheduleWithStartDate:(NSDateComponents *)startDate
                        occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFrom1stTo31th;

/**
 Define a schedule has same number of occurrences every day.
 End date can be set later through CarePlanStore.
 @param daysToSkip  Number of days betwen two active days, this schedule has no occurrence. 
                    
 */
+ (instancetype)dailyScheduleWithStartDate:(NSDateComponents *)startDate
                         occurrencesPerDay:(NSUInteger)occurrencesPerDay
                                daysToSkip:(NSUInteger)daysToSkip
                                   EndDate:(nullable NSDateComponents *)endDate;

/**
 Define a schedule is repeating every week.
 Each weekday can have different number of occurrences.
 @param daysToSkip  Number of days betwen two active days, this schedule has no occurrence.
 */
+ (instancetype)weeklyScheduleWithStartDate:(NSDateComponents *)startDate
                       occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFromSundayToSaturday
                                weeksToSkip:(NSUInteger)weeksToSkip
                                    EndDate:(nullable NSDateComponents *)endDate;

/**
 Define a schedule is repeating every month.
 Each day in a month can have different number of occurrences.
 @param daysToSkip  Number of days betwen two active days, this schedule has no occurrence. 
 
 */
+ (instancetype)monthlyScheduleWithStartDate:(NSDateComponents *)startDate
                        occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFrom1stTo31th
                                monthsToSkip:(NSUInteger)monthsToSkip
                                     EndDate:(nullable NSDateComponents *)endDate;

@property (nonatomic, readonly) OCKCareScheduleType type;

@property (nonatomic, strong, readonly) NSDateComponents *startDate;

@property (nonatomic, strong, readonly, nullable) NSDateComponents *endDate;

@property (nonatomic, copy, readonly) NSArray<NSNumber *> *occurrences;

@property (nonatomic, readonly) NSUInteger timeUnitsToSkip;

- (NSUInteger)numberOfEventsOnDate:(NSDateComponents *)date;

@end



NS_ASSUME_NONNULL_END
