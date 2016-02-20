//
//  OCKCareSchedule.m
//  CareKit
//
//  Created by Yuan Zhu on 1/29/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import "OCKCareSchedule.h"
#import "OCKCareSchedule_Internal.h"
#import "OCKHelpers.h"


@implementation OCKCareSchedule {
    NSCalendar *_calendar;
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

+ (instancetype)dailyScheduleWithStartDate:(NSDate *)startDate
                         occurrencesPerDay:(NSUInteger)occurrencesPerDay {
    return [[OCKCareDailySchedule alloc] initWithStartDate:startDate occurrencesPerDay:occurrencesPerDay];
}

+ (instancetype)weeklyScheduleWithStartDate:(NSDate *)startDate
                       occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFromSundayToSaturday {
    return [[OCKCareWeeklySchedule alloc] initWithStartDate:startDate occurrencesOnEachDay:occurrencesFromSundayToSaturday];
}

+ (instancetype)monthlyScheduleWithStartDate:(NSDate *)startDate
                        occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFrom1stTo31th {
    return [[OCKCareMonthlySchedule alloc] initWithStartDate:startDate occurrencesOnEachDay:occurrencesFrom1stTo31th];
}

+ (instancetype)dailyScheduleWithStartDate:(NSDate *)startDate
                         occurrencesPerDay:(NSUInteger)occurrencesPerDay
                                daysToSkip:(NSUInteger)daysToSkip
                                   endDate:(nullable NSDate *)endDate
                                  timeZone:(nullable NSTimeZone *)timeZone {
    return [[OCKCareDailySchedule alloc] initWithStartDate:startDate daysToSkip:daysToSkip occurrencesPerDay:occurrencesPerDay endDate:endDate timeZone:timeZone];
}

+ (instancetype)weeklyScheduleWithStartDate:(NSDate *)startDate
                       occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFromSundayToSaturday
                                weeksToSkip:(NSUInteger)weeksToSkip
                                    endDate:(nullable NSDate *)endDate
                                   timeZone:(nullable NSTimeZone *)timeZone {
    return [[OCKCareWeeklySchedule alloc] initWithStartDate:startDate
                                                weeksToSkip:weeksToSkip
                                       occurrencesOnEachDay:occurrencesFromSundayToSaturday
                                                    endDate:endDate
                                                   timeZone:timeZone];
}

+ (instancetype)monthlyScheduleWithStartDate:(NSDate *)startDate
                        occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFrom1stTo31th
                                monthsToSkip:(NSUInteger)monthsToSkip
                                     endDate:(nullable NSDate *)endDate
                                    timeZone:(nullable NSTimeZone *)timeZone {
    return [[OCKCareMonthlySchedule alloc] initWithStartDate:startDate monthsToSkip:monthsToSkip occurrencesOnEachDay:occurrencesFrom1stTo31th endDate:endDate timeZone:timeZone];
}


- (instancetype)initWithStartDate:(NSDate *)startDate
                          endDate:(NSDate *)endDate
                         timeZone:(NSTimeZone *)timeZone {
    
    NSParameterAssert(startDate);
    if (endDate) {
        NSAssert(startDate.timeIntervalSince1970 <= endDate.timeIntervalSince1970, @"startDate should be earlier than endDate.");
    }
    
    self = [super init];
    if (self) {
        _timeZone = timeZone;
        NSCalendar *calendar = [self calendar];
        // Find the start of the start day
        _startDate = [calendar startOfDayForDate:startDate];
        // Find the end of the end day
        if (endDate) {
            NSDate *startOfTheNextDayOfEndDay = [calendar startOfDayForDate:[calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:endDate options:0]];
            _endDate = [startOfTheNextDayOfEndDay dateByAddingTimeInterval:-0.01];
        }
       
    }
    return self;
    
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        
        OCK_DECODE_OBJ_CLASS(coder, startDate, NSDate);
        OCK_DECODE_OBJ_CLASS(coder, endDate, NSDate);
        OCK_DECODE_OBJ_CLASS(coder, timeZone, NSTimeZone);
        OCK_DECODE_OBJ_ARRAY(coder, occurrences, NSNumber);
        OCK_DECODE_INTEGER(coder, timeUnitsToSkip);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    OCK_ENCODE_OBJ(coder, startDate);
    OCK_ENCODE_OBJ(coder, endDate);
    OCK_ENCODE_OBJ(coder, timeZone);
    OCK_ENCODE_OBJ(coder, occurrences);
    OCK_ENCODE_INTEGER(coder, timeUnitsToSkip);
}

- (BOOL)isEqual:(id)object {
    BOOL isClassMatch = ([self class] == [object class]);
    
    __typeof(self) castObject = object;
    return (isClassMatch &&
            OCKEqualObjects(self.startDate, castObject.startDate) &&
            OCKEqualObjects(self.endDate, castObject.endDate) &&
            OCKEqualObjects(self.timeZone, castObject.timeZone) &&
            OCKEqualObjects(self.occurrences, castObject.occurrences) &&
            (self.timeUnitsToSkip == castObject.timeUnitsToSkip));
}

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKCareSchedule *schedule = [[[self class] alloc] initWithStartDate:self.startDate
                                                                endDate:self.endDate
                                                               timeZone:self.timeZone];
    
    schedule->_timeUnitsToSkip = self.timeUnitsToSkip;
    schedule->_occurrences = self.occurrences;
    return schedule;
}

- (BOOL)isDateInRange:(NSDate *)day {
    return ((day.timeIntervalSince1970 >= _startDate.timeIntervalSince1970) &&
            (_endDate == nil || day.timeIntervalSince1970 <= _endDate.timeIntervalSince1970));
}

- (BOOL)isActiveOnDay:(NSDate *)date {
    return [self isDateInRange:date];
}

- (NSUInteger)numberOfEventsOnDay:(NSDate *)day {
    OCKThrowMethodUnavailableException();
}

- (NSCalendar *)calendar {
    if (_calendar == nil) {
        _calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        if (_timeZone) {
            _calendar.timeZone = _timeZone;
        } else {
            _calendar.timeZone = [NSTimeZone localTimeZone];
        }
    }
    return _calendar;
}

- (NSUInteger)numberOfDaySinceStart:(NSDate *)day {
    
    NSCalendar *calendar = [self calendar];
    NSInteger startDay = [[self calendar] ordinalityOfUnit:NSCalendarUnitDay
                                                    inUnit:NSCalendarUnitEra
                                                   forDate:[calendar startOfDayForDate:self.startDate]];
    
    NSInteger endDay = [[self calendar] ordinalityOfUnit:NSCalendarUnitDay
                                                  inUnit:NSCalendarUnitEra
                                                 forDate:[calendar startOfDayForDate:day]];

    NSUInteger daysSinceStart = endDay - startDay;
    return daysSinceStart;
}

-(void)setEndDate:(NSDate *)date {
    _endDate = date;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@ %@", [super description], _startDate, _endDate];
}

@end


@implementation OCKCareDailySchedule

- (instancetype)initWithStartDate:(NSDate *)startDate
                occurrencesPerDay:(NSUInteger)occurrencesPerDay {
    return [self initWithStartDate:startDate
                        daysToSkip:0
                 occurrencesPerDay:occurrencesPerDay
                           endDate:nil
                          timeZone:nil];
}

- (instancetype)initWithStartDate:(NSDate *)startDate
                       daysToSkip:(NSUInteger)daysToSkip
                occurrencesPerDay:(NSUInteger)occurrencesPerDay
                          endDate:(nullable NSDate *)endDate
                         timeZone:(nullable NSTimeZone *)timeZone {
    self = [self initWithStartDate:startDate endDate:endDate timeZone:timeZone];
    
    if (self) {
        self.timeUnitsToSkip = daysToSkip;
        self.occurrences = @[@(occurrencesPerDay)];
    }
    return self;
}

- (NSUInteger)numberOfEventsOnDay:(NSDate *)day {
    NSUInteger occurrences = 0;
    if ([self isDateInRange:day]) {
        
        NSUInteger occurrencesPerDay = self.occurrences.firstObject.unsignedIntegerValue;
        
        NSCalendar *calendar = [self calendar];
        NSInteger startDay = [calendar ordinalityOfUnit:NSCalendarUnitDay
                                               inUnit:NSCalendarUnitEra
                                              forDate:self.startDate];
        
        NSInteger endDay = [calendar ordinalityOfUnit:NSCalendarUnitDay
                                             inUnit:NSCalendarUnitEra
                                            forDate:[calendar startOfDayForDate:day]];
        NSUInteger daysSinceStart = endDay - startDay;
        occurrences = ((daysSinceStart % (self.timeUnitsToSkip + 1)) == 0) ? occurrencesPerDay : 0;
    }
    return occurrences;
}

@end

@implementation OCKCareWeeklySchedule

- (instancetype)initWithStartDate:(NSDate *)startDate
             occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFromSundayToSaturday {
    return [self initWithStartDate:startDate
                       weeksToSkip:0
              occurrencesOnEachDay:occurrencesFromSundayToSaturday
                           endDate:nil timeZone:nil];
}

- (instancetype)initWithStartDate:(NSDate *)startDate
                      weeksToSkip:(NSUInteger)weeksToSkip
             occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFromSundayToSaturday
                          endDate:(nullable NSDate *)endDate
                         timeZone:(nullable NSTimeZone *)timeZone {
    
    NSParameterAssert(occurrencesFromSundayToSaturday);
    NSParameterAssert(occurrencesFromSundayToSaturday.count == 7);
    
    self = [self initWithStartDate:startDate endDate:endDate timeZone:timeZone];
    
    if (self) {
        self.timeUnitsToSkip = weeksToSkip;
        self.occurrences = [occurrencesFromSundayToSaturday copy];
    }
    return self;
}

- (NSUInteger)numberOfEventsOnDay:(NSDate *)day {
    NSUInteger occurrences = 0;
    if ([self isDateInRange:day]) {
        NSCalendar *calendar = [self calendar];
        
        NSInteger startWeek = [calendar ordinalityOfUnit:NSCalendarUnitWeekOfYear
                                                 inUnit:NSCalendarUnitEra
                                                forDate:self.startDate];
        
        NSInteger endWeek = [calendar ordinalityOfUnit:NSCalendarUnitWeekOfYear
                                               inUnit:NSCalendarUnitEra
                                              forDate:day];
       
        NSUInteger weeksSinceStart = endWeek - startWeek;
        NSUInteger weekday = [calendar component:NSCalendarUnitWeekday fromDate:day];
        occurrences = ((weeksSinceStart % (self.timeUnitsToSkip + 1)) == 0) ? self.occurrences[weekday-1].unsignedIntegerValue : 0;
    }
    return occurrences;
}

@end

@implementation OCKCareMonthlySchedule

- (instancetype)initWithStartDate:(NSDate *)startDate
             occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFrom1stTo31th {
    return [self initWithStartDate:startDate
                      monthsToSkip:0
              occurrencesOnEachDay:occurrencesFrom1stTo31th
                           endDate:nil
                          timeZone:nil];
}

- (instancetype)initWithStartDate:(NSDate *)startDate
                     monthsToSkip:(NSUInteger)monthsToSkip
             occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFrom1stTo31th
                          endDate:(nullable NSDate *)endDate
                         timeZone:(nullable NSTimeZone *)timeZone {
    
    NSParameterAssert(occurrencesFrom1stTo31th);
    NSParameterAssert(occurrencesFrom1stTo31th.count == 31);
    
    self = [self initWithStartDate:startDate endDate:endDate timeZone:timeZone];
    
    if (self) {
        self.timeUnitsToSkip = monthsToSkip;
        self.occurrences = [occurrencesFrom1stTo31th copy];
    }
    return self;
}

- (NSUInteger)numberOfEventsOnDay:(NSDate *)day {
    NSUInteger occurrences = 0;
    if ([self isDateInRange:day]) {
        NSCalendar *calendar = [self calendar];
        NSInteger startMonth = [calendar ordinalityOfUnit:NSCalendarUnitMonth
                                                  inUnit:NSCalendarUnitEra
                                                 forDate:self.startDate];
        
        NSInteger endMonth = [calendar ordinalityOfUnit:NSCalendarUnitMonth
                                                inUnit:NSCalendarUnitEra
                                               forDate:day];
        NSUInteger monthsSinceStart = endMonth - startMonth;
        NSUInteger dayInMonth = [calendar component:NSCalendarUnitDay fromDate:day];
        occurrences = ((monthsSinceStart % (self.timeUnitsToSkip + 1)) == 0) ? self.occurrences[dayInMonth - 1].unsignedIntegerValue : 0;
    }
    return occurrences;
}

@end

