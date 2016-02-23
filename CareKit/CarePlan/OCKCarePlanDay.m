//
//  OCKCarePlanDay.m
//  CareKit
//
//  Created by Yuan Zhu on 2/22/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import "OCKCarePlanDay.h"
#import "OCKHelpers.h"

@implementation OCKCarePlanDay

- (instancetype)initWithYear:(NSUInteger)year
                       month:(NSUInteger)month
                         day:(NSUInteger)day {
    self = [super init];
    if (self) {
        _year = year;
        _month = month;
        _day = day;
    }
    return self;
}

- (instancetype)initWithDate:(NSDate *)date
                    calendar:(NSCalendar *)calendar {
    NSDateComponents *comp = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:date];
    return [self initWithDateComponents:comp];
}

- (instancetype)initWithDateComponents:(NSDateComponents *)dateComp {
    self = [super init];
    if (self) {
        _year = dateComp.year;
        _month = dateComp.month;
        _day = dateComp.day;
    }
    return self;
}

- (BOOL)isEarlierThan:(OCKCarePlanDay *)anotherDay {
    return anotherDay && ((self.year < anotherDay.year) ||
            (self.year == anotherDay.year && self.month < anotherDay.month) ||
            (self.year == anotherDay.year && self.month == anotherDay.month && self.day < anotherDay.day));
}

- (BOOL)isLaterThan:(OCKCarePlanDay *)anotherDay {
    return anotherDay && ((self.year > anotherDay.year) ||
            (self.year == anotherDay.year && self.month > anotherDay.month) ||
            (self.year == anotherDay.year && self.month == anotherDay.month && self.day > anotherDay.day));
}

- (NSDate *)dateWithCalendar:(NSCalendar *)calendar {
    NSDateComponents *dateComp = [[NSDateComponents alloc] init];
    dateComp.year = self.year;
    dateComp.month = self.month;
    dateComp.day = self.day;
    return [calendar dateFromComponents:dateComp];
}

- (NSDateComponents *)dateComponents {
    NSDateComponents *dateComp = [[NSDateComponents alloc] init];
    dateComp.year = self.year;
    dateComp.month = self.month;
    dateComp.day = self.day;
    return dateComp;
}

- (OCKCarePlanDay *)dayByAddingDays:(NSUInteger)days {
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSDate * nextDate =[calendar dateByAddingUnit:NSCalendarUnitDay value:days toDate:[self dateWithCalendar:calendar] options:0];
    NSDateComponents *nextDayComp = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:nextDate];
    return [[OCKCarePlanDay alloc] initWithDateComponents:nextDayComp];
}

- (OCKCarePlanDay *)nextDay {
    return [self dayByAddingDays:1];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@, %@, %@", @(_year), @(_month), @(_day)];
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        OCK_DECODE_INTEGER(coder, year);
        OCK_DECODE_INTEGER(coder, month);
        OCK_DECODE_INTEGER(coder, day);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    OCK_ENCODE_INTEGER(coder, year);
    OCK_ENCODE_INTEGER(coder, month);
    OCK_ENCODE_INTEGER(coder, day);
}

- (BOOL)isEqual:(id)object {
    BOOL isClassMatch = ([self class] == [object class]);
    
    __typeof(self) castObject = object;
    return (isClassMatch &&
            (self.year == castObject.year) &&
            (self.month == castObject.month) &&
            (self.day == castObject.day));
}

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKCarePlanDay *day = [[[self class] alloc] initWithYear:self.year month:self.month day:self.day];
    return day;
}
@end
