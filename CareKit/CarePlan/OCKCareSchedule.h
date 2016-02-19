//
//  OCKCareSchedule.h
//  CareKit
//
//  Created by Yuan Zhu on 1/29/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OCKCareSchedule : NSObject <NSSecureCoding, NSCopying>

+ (instancetype)dailyScheduleWithStartDate:(NSDate *)startDate
                         occurrencesPerDay:(NSUInteger)occurrencesPerDay;

+ (instancetype)weeklyScheduleWithStartDate:(NSDate *)startDate
                       occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFromSundayToSaturday;

+ (instancetype)monthlyScheduleWithStartDate:(NSDate *)startDate
                        occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFrom1stTo31th;

+ (instancetype)dailyScheduleWithStartDate:(NSDate *)startDate
                         occurrencesPerDay:(NSUInteger)occurrencesPerDay
                                daysToSkip:(NSUInteger)daysToSkip
                                   endDate:(nullable NSDate *)endDate
                                  timeZone:(nullable NSTimeZone *)timeZone;

+ (instancetype)weeklyScheduleWithStartDate:(NSDate *)startDate
                       occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFromSundayToSaturday
                                weeksToSkip:(NSUInteger)weeksToSkip
                                    endDate:(nullable NSDate *)endDate
                                   timeZone:(nullable NSTimeZone *)timeZone;

+ (instancetype)monthlyScheduleWithStartDate:(NSDate *)startDate
                        occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFrom1stTo31th
                                monthsToSkip:(NSUInteger)monthsToSkip
                                     endDate:(nullable NSDate *)endDate
                                    timeZone:(nullable NSTimeZone *)timeZone;

@property (nonatomic, strong, readonly) NSDate *startDate;

@property (nonatomic, strong, readonly, nullable) NSDate *endDate;

@property (nonatomic, copy, readonly) NSArray<NSNumber *> *occurrences;

@property (nonatomic, readonly) NSUInteger timeUnitsToSkip;

@property (nonatomic, readonly, nullable) NSTimeZone *timeZone;

@property (nonatomic, readonly) NSCalendar *calendar;

- (NSUInteger)numberOfEventsOnDay:(NSDate *)day;

@end



NS_ASSUME_NONNULL_END
