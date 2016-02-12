//
//  OCKCareSchedule.m
//  CareKit
//
//  Created by Yuan Zhu on 1/29/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import "OCKCareSchedule.h"
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
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    OCK_ENCODE_OBJ(coder, startDate);
    OCK_ENCODE_OBJ(coder, endDate);
    OCK_ENCODE_OBJ(coder, timeZone);
}

- (BOOL)isEqual:(id)object {
    BOOL isClassMatch = ([self class] == [object class]);
    
    __typeof(self) castObject = object;
    return (isClassMatch &&
            OCKEqualObjects(self.startDate, castObject.startDate) &&
            OCKEqualObjects(self.endDate, castObject.endDate) &&
            OCKEqualObjects(self.timeZone, castObject.timeZone));
}

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKCareSchedule *schedule = [[[self class] alloc] initWithStartDate:self.startDate
                                                                endDate:self.endDate
                                                               timeZone:self.timeZone];
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

@end


@implementation OCKCareDailySchedule

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

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
        _daysToSkip = daysToSkip;
        _occurrencesPerDay = occurrencesPerDay;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        OCK_DECODE_UINT32(coder, daysToSkip);
        OCK_DECODE_UINT32(coder, occurrencesPerDay);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    OCK_ENCODE_UINT32(aCoder, daysToSkip);
    OCK_ENCODE_UINT32(aCoder, occurrencesPerDay);
}

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKCareDailySchedule *schedule = [super copyWithZone:zone];
    schedule->_daysToSkip = self.daysToSkip;
    schedule->_occurrencesPerDay = self.occurrencesPerDay;
    return schedule;
}

- (BOOL)isEqual:(id)object {
    BOOL superEqual = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (superEqual &&
           (self.occurrencesPerDay == castObject.occurrencesPerDay) &&
            (self.daysToSkip == castObject.daysToSkip)
            );
}

- (NSUInteger)numberOfEventsOnDay:(NSDate *)day {
    NSUInteger occurrences = 0;
    if ([self isDateInRange:day]) {
        NSCalendar *calendar = [self calendar];
        NSInteger startDay = [calendar ordinalityOfUnit:NSCalendarUnitDay
                                               inUnit:NSCalendarUnitEra
                                              forDate:self.startDate];
        
        NSInteger endDay = [calendar ordinalityOfUnit:NSCalendarUnitDay
                                             inUnit:NSCalendarUnitEra
                                            forDate:[calendar startOfDayForDate:day]];
        NSUInteger daysSinceStart = endDay - startDay;
        occurrences = ((daysSinceStart % (self.daysToSkip + 1)) == 0) ? self.occurrencesPerDay : 0;
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
        _weeksToSkip = weeksToSkip;
        _occurrencesFromSundayToSaturday = [occurrencesFromSundayToSaturday copy];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        OCK_DECODE_UINT32(coder, weeksToSkip);
        OCK_DECODE_OBJ_ARRAY(coder, occurrencesFromSundayToSaturday, NSNumber);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    OCK_ENCODE_UINT32(aCoder, weeksToSkip);
    OCK_ENCODE_OBJ(aCoder, occurrencesFromSundayToSaturday);
}

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKCareWeeklySchedule *schedule = [super copyWithZone:zone];
    schedule->_weeksToSkip = self.weeksToSkip;
    schedule->_occurrencesFromSundayToSaturday = [self.occurrencesFromSundayToSaturday copy];
    return schedule;
}

- (BOOL)isEqual:(id)object {
    BOOL superEqual = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (superEqual &&
            OCKEqualObjects(self.occurrencesFromSundayToSaturday, castObject.occurrencesFromSundayToSaturday) &&
            (self.weeksToSkip == castObject.weeksToSkip)
            );
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
        occurrences = ((weeksSinceStart % (self.weeksToSkip + 1)) == 0) ? self.occurrencesFromSundayToSaturday[weekday-1].unsignedIntegerValue : 0;
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
        _monthsToSkip = monthsToSkip;
        _occurrencesFrom1stTo31th = [occurrencesFrom1stTo31th copy];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        OCK_DECODE_UINT32(coder, monthsToSkip);
        OCK_DECODE_OBJ_ARRAY(coder, occurrencesFrom1stTo31th, NSNumber);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    OCK_ENCODE_UINT32(aCoder, monthsToSkip);
    OCK_ENCODE_OBJ(aCoder, occurrencesFrom1stTo31th);
}

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKCareMonthlySchedule *schedule = [super copyWithZone:zone];
    schedule->_monthsToSkip = self.monthsToSkip;
    schedule->_occurrencesFrom1stTo31th = [self.occurrencesFrom1stTo31th copy];
    return schedule;
}

- (BOOL)isEqual:(id)object {
    BOOL superEqual = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (superEqual &&
            OCKEqualObjects(self.occurrencesFrom1stTo31th, castObject.occurrencesFrom1stTo31th) &&
            (self.monthsToSkip == castObject.monthsToSkip)
            );
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
        occurrences = ((monthsSinceStart % (self.monthsToSkip + 1)) == 0) ? self.occurrencesFrom1stTo31th[dayInMonth - 1].unsignedIntegerValue : 0;
    }
    return occurrences;
}

@end

