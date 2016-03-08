//
//  OCKCareSchedule.m
//  CareKit
//
//  Created by Yuan Zhu on 1/29/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import "OCKCareSchedule.h"
#import "OCKCareSchedule_Internal.h"
#import "NSDateComponents+CarePlanInternal.h"
#import "OCKHelpers.h"


@implementation OCKCareSchedule {
    NSCalendar *_calendar;
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

+ (instancetype)dailyScheduleWithStartDate:(NSDateComponents *)startDate
                        occurrencesPerDay:(NSUInteger)occurrencesPerDay {
    return [[OCKCareDailySchedule alloc] initWithStartDate:startDate
                                               daysToSkip:0
                                        occurrencesPerDay:occurrencesPerDay
                                                   EndDate:nil];
}

+ (instancetype)weeklyScheduleWithStartDate:(NSDateComponents *)startDate
                      occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFromSundayToSaturday {
    return [[OCKCareWeeklySchedule alloc] initWithStartDate:startDate
                                               weeksToSkip:0
                                      occurrencesOnEachDay:occurrencesFromSundayToSaturday
                                                    EndDate:nil];
}

+ (instancetype)monthlyScheduleWithStartDate:(NSDateComponents *)startDate
                       occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFrom1stTo31th {
    return [[OCKCareMonthlySchedule alloc] initWithStartDate:startDate
                                               monthsToSkip:0
                                       occurrencesOnEachDay:occurrencesFrom1stTo31th
                                                     EndDate:nil];
}

+ (instancetype)dailyScheduleWithStartDate:(NSDateComponents *)startDate
                        occurrencesPerDay:(NSUInteger)occurrencesPerDay
                               daysToSkip:(NSUInteger)daysToSkip
                                   EndDate:(nullable NSDateComponents *)endDate {
    return [[OCKCareDailySchedule alloc] initWithStartDate:startDate
                                               daysToSkip:daysToSkip
                                        occurrencesPerDay:occurrencesPerDay
                                                   EndDate:endDate];
}

+ (instancetype)weeklyScheduleWithStartDate:(NSDateComponents *)startDate
                      occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFromSundayToSaturday
                               weeksToSkip:(NSUInteger)weeksToSkip
                                    EndDate:(nullable NSDateComponents *)endDate {
    return [[OCKCareWeeklySchedule alloc] initWithStartDate:startDate
                                               weeksToSkip:weeksToSkip
                                      occurrencesOnEachDay:occurrencesFromSundayToSaturday
                                                    EndDate:endDate];
}

+ (instancetype)monthlyScheduleWithStartDate:(NSDateComponents *)startDate
                       occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFrom1stTo31th
                               monthsToSkip:(NSUInteger)monthsToSkip
                                     EndDate:(nullable NSDateComponents *)endDate {
    return [[OCKCareMonthlySchedule alloc] initWithStartDate:startDate
                                               monthsToSkip:monthsToSkip
                                       occurrencesOnEachDay:occurrencesFrom1stTo31th
                                                     EndDate:endDate];
}


- (instancetype)initWithStartDate:(NSDateComponents *)startDate
                          EndDate:(NSDateComponents *)endDate {
    
    NSParameterAssert(startDate);
    if (endDate) {
        NSAssert(![startDate isLaterThan:endDate], @"startDate should be earlier than endDate.");
    }
    
    self = [super init];
    if (self) {
        _startDate = startDate;
        [_startDate adjustEra];
        _endDate = endDate;
        [_endDate adjustEra];
    }
    return self;
    
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        
        OCK_DECODE_OBJ_CLASS(coder, startDate, NSDateComponents);
        OCK_DECODE_OBJ_CLASS(coder, endDate, NSDateComponents);
        OCK_DECODE_OBJ_ARRAY(coder, occurrences, NSNumber);
        OCK_DECODE_INTEGER(coder, timeUnitsToSkip);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    OCK_ENCODE_OBJ(coder, startDate);
    OCK_ENCODE_OBJ(coder, endDate);
    OCK_ENCODE_OBJ(coder, occurrences);
    OCK_ENCODE_INTEGER(coder, timeUnitsToSkip);
}

- (BOOL)isEqual:(id)object {
    BOOL isClassMatch = ([self class] == [object class]);
    
    __typeof(self) castObject = object;
    return (isClassMatch &&
            OCKEqualObjects(self.startDate, castObject.startDate) &&
            OCKEqualObjects(self.endDate, castObject.endDate) &&
            OCKEqualObjects(self.occurrences, castObject.occurrences) &&
            (self.timeUnitsToSkip == castObject.timeUnitsToSkip));
}

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKCareSchedule *schedule = [[[self class] alloc] initWithStartDate:self.startDate EndDate:self.endDate];
    schedule->_timeUnitsToSkip = self.timeUnitsToSkip;
    schedule->_occurrences = self.occurrences;
    return schedule;
}

- (BOOL)isDateInRange:(NSDateComponents *)day {
    return (([day isLaterThan:_startDate] || [day isEqual:_startDate]) &&
            (_endDate == nil || [day isEarlierThan:_endDate] || [day isEqual:_endDate]));
}

- (NSCalendar *)calendar {
    return [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
}

- (NSUInteger)numberOfEventsOnDate:(NSDateComponents *)day {
    OCKThrowMethodUnavailableException();
}

- (NSUInteger)numberOfDaySinceStart:(NSDateComponents *)day {
    
    NSCalendar *calendar = [self calendar];
    NSInteger startDate = [calendar ordinalityOfUnit:NSCalendarUnitDay
                                             inUnit:NSCalendarUnitEra
                                            forDate:[_startDate dateWithCalendar:calendar]];
    
    NSInteger endDate = [calendar ordinalityOfUnit:NSCalendarUnitDay
                                           inUnit:NSCalendarUnitEra
                                          forDate:[day dateWithCalendar:calendar]];

    NSUInteger daysSinceStart = endDate - startDate;
    return daysSinceStart;
}

-(void)setEndDate:(NSDateComponents *)day {
    NSAssert(![_startDate isLaterThan:day], @"startDate should be earlier than endDate. %@ %@", _startDate, day);
    _endDate = day;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@ %@", [super description], _startDate, _endDate];
}

@end


@implementation OCKCareDailySchedule

- (OCKCareScheduleType)type {
    return OCKCareScheduleTypeDaily;
}

- (instancetype)initWithStartDate:(NSDateComponents *)startDate
                       daysToSkip:(NSUInteger)daysToSkip
                occurrencesPerDay:(NSUInteger)occurrencesPerDay
                          EndDate:(nullable NSDateComponents *)endDate {
    self = [self initWithStartDate:startDate EndDate:endDate];
    
    if (self) {
        self.timeUnitsToSkip = daysToSkip;
        self.occurrences = @[@(occurrencesPerDay)];
    }
    return self;
}

- (NSUInteger)numberOfEventsOnDate:(NSDateComponents *)day {
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

- (instancetype)initWithStartDate:(NSDateComponents *)startDate
                     weeksToSkip:(NSUInteger)weeksToSkip
            occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFromSundayToSaturday
                          EndDate:(nullable NSDateComponents *)endDate {
    
    NSParameterAssert(occurrencesFromSundayToSaturday);
    NSParameterAssert(occurrencesFromSundayToSaturday.count == 7);
    
    self = [self initWithStartDate:startDate EndDate:endDate];
    
    if (self) {
        self.timeUnitsToSkip = weeksToSkip;
        self.occurrences = [occurrencesFromSundayToSaturday copy];
    }
    return self;
}

- (NSUInteger)numberOfEventsOnDate:(NSDateComponents *)day {
    NSUInteger occurrences = 0;
    if ([self isDateInRange:day]) {
        NSCalendar *calendar = [self calendar];
        
        NSInteger startWeek = [calendar ordinalityOfUnit:NSCalendarUnitWeekOfYear
                                                 inUnit:NSCalendarUnitEra
                                                forDate:[self.startDate dateWithCalendar:calendar]];
        
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

- (instancetype)initWithStartDate:(NSDateComponents *)startDate
                    monthsToSkip:(NSUInteger)monthsToSkip
            occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFrom1stTo31th
                          EndDate:(nullable NSDateComponents *)endDate {
    
    NSParameterAssert(occurrencesFrom1stTo31th);
    NSParameterAssert(occurrencesFrom1stTo31th.count == 31);
    
   self = [self initWithStartDate:startDate EndDate:endDate];
    
    if (self) {
        self.timeUnitsToSkip = monthsToSkip;
        self.occurrences = [occurrencesFrom1stTo31th copy];
    }
    return self;
}

- (NSUInteger)numberOfEventsOnDate:(NSDateComponents *)day {
    NSUInteger occurrences = 0;
    if ([self isDateInRange:day]) {
        NSCalendar *calendar = [self calendar];
        NSInteger startMonth = [calendar ordinalityOfUnit:NSCalendarUnitMonth
                                                  inUnit:NSCalendarUnitEra
                                                 forDate:[self.startDate dateWithCalendar:calendar]];
        
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

