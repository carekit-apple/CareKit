//
//  NSDateComponents+CarePlan.m
//  CareKit
//
//  Created by Yuan Zhu on 3/8/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

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
    
    return [self isValidDateInCalendar:[self gregorianCalendar]] ? self : nil;
}

- (instancetype)initWithDate:(NSDate *)date
                    calendar:(NSCalendar *)calendar {
    NSDateComponents *comp = [calendar components:NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:date];
    return [self initWithDateComponents:comp];
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

- (NSDate *)dateWithCalendar:(NSCalendar *)calendar {
    return [calendar dateFromComponents:[self dateComponents]];
}

- (NSDateComponents *)dateComponents {
    NSDateComponents *dateComp = [[NSDateComponents alloc] init];
    dateComp.era = self.era;
    dateComp.year = self.year;
    dateComp.month = self.month;
    dateComp.day = self.day;
    [dateComp adjustEra];
    return dateComp;
}

- (NSCalendar *)gregorianCalendar {
    static NSCalendar *calendar;
    if (calendar == nil) {
        calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    }
    return calendar;
}

- (NSDateComponents *)dateByAddingDays:(NSInteger)days {
    NSCalendar *calendar = [self gregorianCalendar];
    NSDate * nextDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:days toDate:[self dateWithCalendar:calendar] options:0];
    NSDateComponents *nextDayComp = [calendar components:NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:nextDate];
    return [[NSDateComponents alloc] initWithDateComponents:nextDayComp];
}

- (NSDateComponents *)nextDay {
    return [self dateByAddingDays:1];
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
