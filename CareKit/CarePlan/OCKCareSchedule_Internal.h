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

- (void)setEndDate:(NSDateComponents *)date;

- (NSUInteger)numberOfDaySinceStart:(NSDateComponents *)date;

@end


@interface OCKCareDailySchedule : OCKCareSchedule


- (instancetype)initWithStartDate:(NSDateComponents *)startDate
                      daysToSkip:(NSUInteger)daysToSkip
               occurrencesPerDay:(NSUInteger)occurrencesPerDay
                          EndDate:(nullable NSDateComponents *)endDate;

@end


@interface OCKCareWeeklySchedule : OCKCareSchedule

- (instancetype)initWithStartDate:(NSDateComponents *)startDate
                     weeksToSkip:(NSUInteger)weeksToSkip
            occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFromSundayToSaturday
                          EndDate:(nullable NSDateComponents *)endDate;

@end


@interface OCKCareMonthlySchedule : OCKCareSchedule

- (instancetype)initWithStartDate:(NSDateComponents *)startDate
                     monthsToSkip:(NSUInteger)monthsToSkip
             occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFrom1stTo31th
                           EndDate:(nullable NSDateComponents *)endDate;

@end


NS_ASSUME_NONNULL_END