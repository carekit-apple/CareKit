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

- (void)setEndDay:(OCKCarePlanDay *)day;

- (NSUInteger)numberOfDaySinceStart:(OCKCarePlanDay *)day;

@end


@interface OCKCareDailySchedule : OCKCareSchedule


- (instancetype)initWithStartDay:(OCKCarePlanDay *)startDay
                      daysToSkip:(NSUInteger)daysToSkip
               occurrencesPerDay:(NSUInteger)occurrencesPerDay
                          endDay:(nullable OCKCarePlanDay *)endDay;

@end


@interface OCKCareWeeklySchedule : OCKCareSchedule

- (instancetype)initWithStartDay:(OCKCarePlanDay *)startDay
                     weeksToSkip:(NSUInteger)weeksToSkip
            occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFromSundayToSaturday
                          endDay:(nullable OCKCarePlanDay *)endDay;

@end


@interface OCKCareMonthlySchedule : OCKCareSchedule

- (instancetype)initWithStartDay:(OCKCarePlanDay *)startDay
                     monthsToSkip:(NSUInteger)monthsToSkip
             occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFrom1stTo31th
                           endDay:(nullable OCKCarePlanDay *)endDay;

@end


NS_ASSUME_NONNULL_END