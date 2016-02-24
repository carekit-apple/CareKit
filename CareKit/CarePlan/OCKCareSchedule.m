//
//  OCKCareSchedule.m
//  CareKit
//
//  Created by Yuan Zhu on 1/29/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import "OCKCareSchedule.h"
#import "OCKCareSchedule_Internal.h"
#import "OCKCarePlanDay_Internal.h"
#import "OCKHelpers.h"


@implementation OCKCareSchedule {
    NSCalendar *_calendar;
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

+ (instancetype)dailyScheduleWithStartDay:(OCKCarePlanDay *)startDay
                        occurrencesPerDay:(NSUInteger)occurrencesPerDay {
    return [[OCKCareDailySchedule alloc] initWithStartDay:startDay
                                               daysToSkip:0
                                        occurrencesPerDay:occurrencesPerDay
                                                   endDay:nil];
}

+ (instancetype)weeklyScheduleWithStartDay:(OCKCarePlanDay *)startDay
                      occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFromSundayToSaturday {
    return [[OCKCareWeeklySchedule alloc] initWithStartDay:startDay
                                               weeksToSkip:0
                                      occurrencesOnEachDay:occurrencesFromSundayToSaturday
                                                    endDay:nil];
}

+ (instancetype)monthlyScheduleWithStartDay:(OCKCarePlanDay *)startDay
                       occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFrom1stTo31th {
    return [[OCKCareMonthlySchedule alloc] initWithStartDay:startDay
                                               monthsToSkip:0
                                       occurrencesOnEachDay:occurrencesFrom1stTo31th
                                                     endDay:nil];
}

+ (instancetype)dailyScheduleWithStartDay:(OCKCarePlanDay *)startDay
                        occurrencesPerDay:(NSUInteger)occurrencesPerDay
                               daysToSkip:(NSUInteger)daysToSkip
                                   endDay:(nullable OCKCarePlanDay *)endDay {
    return [[OCKCareDailySchedule alloc] initWithStartDay:startDay
                                               daysToSkip:daysToSkip
                                        occurrencesPerDay:occurrencesPerDay
                                                   endDay:endDay];
}

+ (instancetype)weeklyScheduleWithStartDay:(OCKCarePlanDay *)startDay
                      occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFromSundayToSaturday
                               weeksToSkip:(NSUInteger)weeksToSkip
                                    endDay:(nullable OCKCarePlanDay *)endDay {
    return [[OCKCareWeeklySchedule alloc] initWithStartDay:startDay
                                               weeksToSkip:weeksToSkip
                                      occurrencesOnEachDay:occurrencesFromSundayToSaturday
                                                    endDay:endDay];
}

+ (instancetype)monthlyScheduleWithStartDay:(OCKCarePlanDay *)startDay
                       occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFrom1stTo31th
                               monthsToSkip:(NSUInteger)monthsToSkip
                                     endDay:(nullable OCKCarePlanDay *)endDay {
    return [[OCKCareMonthlySchedule alloc] initWithStartDay:startDay
                                               monthsToSkip:monthsToSkip
                                       occurrencesOnEachDay:occurrencesFrom1stTo31th
                                                     endDay:endDay];
}


- (instancetype)initWithStartDay:(OCKCarePlanDay *)startDay
                          endDay:(OCKCarePlanDay *)endDay {
    
    NSParameterAssert(startDay);
    if (endDay) {
        NSAssert(![startDay isLaterThan:endDay], @"startDay should be earlier than endDay.");
    }
    
    self = [super init];
    if (self) {
        _startDay = startDay;
        _endDay = endDay;
    }
    return self;
    
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        
        OCK_DECODE_OBJ_CLASS(coder, startDay, OCKCarePlanDay);
        OCK_DECODE_OBJ_CLASS(coder, endDay, OCKCarePlanDay);
        OCK_DECODE_OBJ_ARRAY(coder, occurrences, NSNumber);
        OCK_DECODE_INTEGER(coder, timeUnitsToSkip);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    OCK_ENCODE_OBJ(coder, startDay);
    OCK_ENCODE_OBJ(coder, endDay);
    OCK_ENCODE_OBJ(coder, occurrences);
    OCK_ENCODE_INTEGER(coder, timeUnitsToSkip);
}

- (BOOL)isEqual:(id)object {
    BOOL isClassMatch = ([self class] == [object class]);
    
    __typeof(self) castObject = object;
    return (isClassMatch &&
            OCKEqualObjects(self.startDay, castObject.startDay) &&
            OCKEqualObjects(self.endDay, castObject.endDay) &&
            OCKEqualObjects(self.occurrences, castObject.occurrences) &&
            (self.timeUnitsToSkip == castObject.timeUnitsToSkip));
}

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKCareSchedule *schedule = [[[self class] alloc] initWithStartDay:self.startDay endDay:self.endDay];
    schedule->_timeUnitsToSkip = self.timeUnitsToSkip;
    schedule->_occurrences = self.occurrences;
    return schedule;
}

- (BOOL)isDateInRange:(OCKCarePlanDay *)day {
    return (([day isLaterThan:_startDay] || [day isEqual:_startDay]) &&
            (_endDay == nil || [day isEarlierThan:_endDay] || [day isEqual:_endDay]));
}

- (NSCalendar *)calendar {
    return [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
}

- (NSUInteger)numberOfEventsOnDay:(OCKCarePlanDay *)day {
    OCKThrowMethodUnavailableException();
}

- (NSUInteger)numberOfDaySinceStart:(OCKCarePlanDay *)day {
    
    NSCalendar *calendar = [self calendar];
    NSInteger startDay = [calendar ordinalityOfUnit:NSCalendarUnitDay
                                             inUnit:NSCalendarUnitEra
                                            forDate:[_startDay dateWithCalendar:calendar]];
    
    NSInteger endDay = [calendar ordinalityOfUnit:NSCalendarUnitDay
                                           inUnit:NSCalendarUnitEra
                                          forDate:[day dateWithCalendar:calendar]];

    NSUInteger daysSinceStart = endDay - startDay;
    return daysSinceStart;
}

-(void)setEndDay:(OCKCarePlanDay *)day {
    NSAssert(![_startDay isLaterThan:day], @"startDay should be earlier than endDay. %@ %@", _startDay, day);
    _endDay = day;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@ %@", [super description], _startDay, _endDay];
}

@end


@implementation OCKCareDailySchedule

- (OCKCareScheduleType)type {
    return OCKCareScheduleTypeDaily;
}

- (instancetype)initWithStartDay:(OCKCarePlanDay *)startDay
                       daysToSkip:(NSUInteger)daysToSkip
                occurrencesPerDay:(NSUInteger)occurrencesPerDay
                          endDay:(nullable OCKCarePlanDay *)endDay {
    self = [self initWithStartDay:startDay endDay:endDay];
    
    if (self) {
        self.timeUnitsToSkip = daysToSkip;
        self.occurrences = @[@(occurrencesPerDay)];
    }
    return self;
}

- (NSUInteger)numberOfEventsOnDay:(OCKCarePlanDay *)day {
    NSUInteger occurrences = 0;
    if ([self isDateInRange:day]) {
        
        NSUInteger occurrencesPerDay = self.occurrences.firstObject.unsignedIntegerValue;
        NSUInteger daysSinceStart = [self numberOfDaySinceStart:day];
        occurrences = ((daysSinceStart % (self.timeUnitsToSkip + 1)) == 0) ? occurrencesPerDay : 0;
    }
    return occurrences;
}

@end

@implementation OCKCareWeeklySchedule

- (OCKCareScheduleType)type {
    return OCKCareScheduleTypeWeekly;
}

- (instancetype)initWithStartDay:(OCKCarePlanDay *)startDay
                     weeksToSkip:(NSUInteger)weeksToSkip
            occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFromSundayToSaturday
                          endDay:(nullable OCKCarePlanDay *)endDay {
    
    NSParameterAssert(occurrencesFromSundayToSaturday);
    NSParameterAssert(occurrencesFromSundayToSaturday.count == 7);
    
    self = [self initWithStartDay:startDay endDay:endDay];
    
    if (self) {
        self.timeUnitsToSkip = weeksToSkip;
        self.occurrences = [occurrencesFromSundayToSaturday copy];
    }
    return self;
}

- (NSUInteger)numberOfEventsOnDay:(OCKCarePlanDay *)day {
    NSUInteger occurrences = 0;
    if ([self isDateInRange:day]) {
        NSCalendar *calendar = [self calendar];
        
        NSInteger startWeek = [calendar ordinalityOfUnit:NSCalendarUnitWeekOfYear
                                                 inUnit:NSCalendarUnitEra
                                                forDate:[self.startDay dateWithCalendar:calendar]];
        
        NSInteger endWeek = [calendar ordinalityOfUnit:NSCalendarUnitWeekOfYear
                                               inUnit:NSCalendarUnitEra
                                              forDate:[day dateWithCalendar:calendar]];
       
        NSUInteger weeksSinceStart = endWeek - startWeek;
        NSUInteger weekday = [calendar component:NSCalendarUnitWeekday fromDate:[day dateWithCalendar:calendar]];
        occurrences = ((weeksSinceStart % (self.timeUnitsToSkip + 1)) == 0) ? self.occurrences[weekday-1].unsignedIntegerValue : 0;
    }
    return occurrences;
}

@end

@implementation OCKCareMonthlySchedule

- (OCKCareScheduleType)type {
    return OCKCareScheduleTypeMonthly;
}

- (instancetype)initWithStartDay:(OCKCarePlanDay *)startDay
                    monthsToSkip:(NSUInteger)monthsToSkip
            occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFrom1stTo31th
                          endDay:(nullable OCKCarePlanDay *)endDay {
    
    NSParameterAssert(occurrencesFrom1stTo31th);
    NSParameterAssert(occurrencesFrom1stTo31th.count == 31);
    
   self = [self initWithStartDay:startDay endDay:endDay];
    
    if (self) {
        self.timeUnitsToSkip = monthsToSkip;
        self.occurrences = [occurrencesFrom1stTo31th copy];
    }
    return self;
}

- (NSUInteger)numberOfEventsOnDay:(OCKCarePlanDay *)day {
    NSUInteger occurrences = 0;
    if ([self isDateInRange:day]) {
        NSCalendar *calendar = [self calendar];
        NSInteger startMonth = [calendar ordinalityOfUnit:NSCalendarUnitMonth
                                                  inUnit:NSCalendarUnitEra
                                                 forDate:[self.startDay dateWithCalendar:calendar]];
        
        NSInteger endMonth = [calendar ordinalityOfUnit:NSCalendarUnitMonth
                                                inUnit:NSCalendarUnitEra
                                               forDate:[day dateWithCalendar:calendar]];
        
        NSUInteger monthsSinceStart = endMonth - startMonth;
        NSUInteger dayInMonth = [calendar component:NSCalendarUnitDay fromDate:[day dateWithCalendar:calendar]];
        occurrences = ((monthsSinceStart % (self.timeUnitsToSkip + 1)) == 0) ? self.occurrences[dayInMonth - 1].unsignedIntegerValue : 0;
    }
    return occurrences;
}

@end

