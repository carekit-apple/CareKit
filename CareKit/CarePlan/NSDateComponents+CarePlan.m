/*
 Copyright (c) 2016, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "NSDateComponents+CarePlan.h"
#import "NSDateComponents+CarePlanInternal.h"


@implementation NSDateComponents (CarePlan)

- (instancetype)initWithYear:(NSInteger)year
                       month:(NSInteger)month
                         day:(NSInteger)day {
    self = [self init];
    if (self) {
        self.year = year;
        self.month = month;
        self.day = day;
        [self adjustEra];
    }
    
    return [self isValidDateInCalendar:[self UTC_gregorianCalendar]] ? self : nil;
}

- (instancetype)initWithDate:(NSDate *)date
                    calendar:(NSCalendar *)calendar {
    NSDateComponents *comp = [calendar components:NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:date];
    return [self initWithDateComponents:comp];
}

+ (NSDateComponents *)ock_componentsWithDate:(NSDate *)date calendar:(NSCalendar *)calendar {
    NSParameterAssert(date);
    NSParameterAssert(calendar);
    NSAssert([calendar.calendarIdentifier isEqualToString:NSCalendarIdentifierGregorian], @"(ock_componentsWithDate:calendar:) only accepts gregorian calendar.");
    return [calendar components:NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitWeekday|NSCalendarUnitWeekOfYear|NSCalendarUnitWeekOfMonth fromDate:date];
}

- (BOOL)isInSameWeekAsDate:(NSDateComponents *)anotherDate {    
    return [[self UTC_gregorianCalendar] isDate:[self UTC_dateWithGregorianCalendar]
                                    equalToDate:[anotherDate UTC_dateWithGregorianCalendar]
                              toUnitGranularity:NSCalendarUnitWeekOfYear];
}

- (instancetype)initWithDateComponents:(NSDateComponents *)dateComp {
    self = [self initWithYear:dateComp.year month:dateComp.month day:dateComp.day];
    self.era = dateComp.era;
    return self;
}

- (void)adjustEra {
    if (self.era < 0 || self.era > 1) {
        self.era = 1;
    }
}

- (BOOL)isEarlierThan:(NSDateComponents *)anotherDay {
    [self adjustEra];
    [anotherDay adjustEra];
    return anotherDay && ((self.year < anotherDay.year) ||
                          (self.year == anotherDay.year && self.month < anotherDay.month) ||
                          (self.year == anotherDay.year && self.month == anotherDay.month && self.day < anotherDay.day));
}

- (BOOL)isLaterThan:(NSDateComponents *)anotherDay {
    [self adjustEra];
    [anotherDay adjustEra];
    return anotherDay && ((self.year > anotherDay.year) ||
                          (self.year == anotherDay.year && self.month > anotherDay.month) ||
                          (self.year == anotherDay.year && self.month == anotherDay.month && self.day > anotherDay.day));
}

- (NSDate *)UTC_dateWithGregorianCalendar {
    return [[self UTC_gregorianCalendar] dateFromComponents:[self validatedDateComponents]];
}

- (NSDateComponents *)validatedDateComponents {
    NSDateComponents *dateComp = [NSDateComponents new];
    dateComp.era = self.era;
    dateComp.year = self.year;
    dateComp.month = self.month;
    dateComp.day = self.day;
    [dateComp adjustEra];
    
    BOOL valid = [dateComp isValidDateInCalendar:[self UTC_gregorianCalendar]];
    
    if (valid == NO) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"date components is not valid in Gregorian calendar. \n %@", dateComp] userInfo:@{@"date": dateComp}];
    }
    
    return dateComp;
}

- (NSCalendar *)UTC_gregorianCalendar {
    static NSCalendar *calendar;
    if (calendar == nil) {
        calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        calendar.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    }
    return calendar;
}

- (NSDateComponents *)dateCompByAddingDays:(NSInteger)days {
    NSCalendar *calendar = [self UTC_gregorianCalendar];
    NSDate * nextDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:days toDate:[self UTC_dateWithGregorianCalendar] options:0];
    NSDateComponents *nextDayComp = [calendar components:NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:nextDate];
    return [[NSDateComponents alloc] initWithDateComponents:nextDayComp];
}

- (NSDateComponents *)nextDay {
    return [self dateCompByAddingDays:1];
}

- (BOOL)isEqualToDate:(NSDateComponents *)date {
    [self adjustEra];
    [date adjustEra];
    
    BOOL isClassMatch = ([self class] == [date class]);

    __typeof(self) castObject = date;
    return (isClassMatch &&
            (self.era == castObject.era) &&
            (self.year == castObject.year) &&
            (self.month == castObject.month) &&
            (self.day == castObject.day));
}

@end
