//
//  OCKCareSchedule_Internal.h
//  CareKit
//
//  Created by Yuan Zhu on 2/4/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import <CareKit/CareKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OCKCareSchedule ()

@property (nonatomic, copy) NSArray<NSNumber *> *occurrences;

@property (nonatomic) NSUInteger timeUnitsToSkip;

- (void)setEndDate:(NSDate *)date;

- (NSUInteger)numberOfDaySinceStart:(NSDate *)day;

- (BOOL)isActiveOnDay:(NSDate *)date;

@end


@interface OCKCareDailySchedule : OCKCareSchedule

- (instancetype)initWithStartDate:(NSDate *)startDate
                occurrencesPerDay:(NSUInteger)occurrencesPerDay;

- (instancetype)initWithStartDate:(NSDate *)startDate
                       daysToSkip:(NSUInteger)daysToSkip
                occurrencesPerDay:(NSUInteger)occurrencesPerDay
                          endDate:(nullable NSDate *)endDate
                         timeZone:(nullable NSTimeZone *)timeZone;

@end


@interface OCKCareWeeklySchedule : OCKCareSchedule

- (instancetype)initWithStartDate:(NSDate *)startDate
             occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFromSundayToSaturday;

- (instancetype)initWithStartDate:(NSDate *)startDate
                      weeksToSkip:(NSUInteger)weeksToSkip
             occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFromSundayToSaturday
                          endDate:(nullable NSDate *)endDate
                         timeZone:(nullable NSTimeZone *)timeZone;

@end


@interface OCKCareMonthlySchedule : OCKCareSchedule

- (instancetype)initWithStartDate:(NSDate *)startDate
             occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFrom1stTo31th;

- (instancetype)initWithStartDate:(NSDate *)startDate
                     monthsToSkip:(NSUInteger)monthsToSkip
             occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFrom1stTo31th
                          endDate:(nullable NSDate *)endDate
                         timeZone:(nullable NSTimeZone *)timeZone;

@end


NS_ASSUME_NONNULL_END