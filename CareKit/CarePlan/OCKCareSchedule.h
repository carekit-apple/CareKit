//
//  OCKCareSchedule.h
//  CareKit
//
//  Created by Yuan Zhu on 1/29/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OCKCareSchedule : NSObject  <NSSecureCoding, NSCopying>

+ (instancetype)dailyScheduleWithStartDate:(NSDate *)startDate
                         occurrencesPerDay:(NSUInteger)occurrencesPerDay;

+ (instancetype)weeklyScheduleWithStartDate:(NSDate *)startDate
                       occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFromSundayToSaturday;

+ (instancetype)monthlyScheduleWithStartDate:(NSDate *)startDate
                        occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFrom1stTo31th;

@property (nonatomic, readonly) NSDate *startDate;

@property (nonatomic, readonly, nullable) NSDate *endDate;

@property (nonatomic, readonly, nullable) NSTimeZone *timeZone;

@end

@interface OCKCareDailySchedule : OCKCareSchedule

- (instancetype)initWithStartDate:(NSDate *)startDate
                occurrencesPerDay:(NSUInteger)occurrencesPerDay;

- (instancetype)initWithStartDate:(NSDate *)startDate
                       daysToSkip:(NSUInteger)daysToSkip
                occurrencesPerDay:(NSUInteger)occurrencesPerDay
                          endDate:(nullable NSDate *)endDate
                         timeZone:(nullable NSTimeZone *)timeZone;

@property (nonatomic, readonly) NSUInteger occurrencesPerDay;

@property (nonatomic, readonly) NSUInteger daysToSkip;

@end

@interface OCKCareWeeklySchedule : OCKCareSchedule

- (instancetype)initWithStartDate:(NSDate *)startDate
             occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFromSundayToSaturday;

- (instancetype)initWithStartDate:(NSDate *)startDate
                      weeksToSkip:(NSUInteger)weeksToSkip
             occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFromSundayToSaturday
                          endDate:(nullable NSDate *)endDate
                         timeZone:(nullable NSTimeZone *)timeZone;

@property (nonatomic, readonly) NSArray<NSNumber *> *occurrencesFromSundayToSaturday;

@property (nonatomic, readonly) NSUInteger weeksToSkip;

@end

@interface OCKCareMonthlySchedule : OCKCareSchedule

- (instancetype)initWithStartDate:(NSDate *)startDate
             occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFrom1stTo31th;

- (instancetype)initWithStartDate:(NSDate *)startDate
                     monthsToSkip:(NSUInteger)monthsToSkip
             occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFrom1stTo31th
                          endDate:(nullable NSDate *)endDate
                         timeZone:(nullable NSTimeZone *)timeZone;

@property (nonatomic, readonly) NSArray<NSNumber *> *occurrencesFrom1stTo31th;

@property (nonatomic, readonly) NSUInteger monthsToSkip;

@end

NS_ASSUME_NONNULL_END
