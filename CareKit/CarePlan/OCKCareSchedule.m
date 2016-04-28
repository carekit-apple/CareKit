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
                                                   endDate:nil];
}

+ (instancetype)weeklyScheduleWithStartDate:(NSDateComponents *)startDate
                       occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFromSundayToSaturday {
    return [[OCKCareWeeklySchedule alloc] initWithStartDate:startDate
                                               weeksToSkip:0
                                      occurrencesOnEachDay:occurrencesFromSundayToSaturday
                                                    endDate:nil];
}

+ (instancetype)dailyScheduleWithStartDate:(NSDateComponents *)startDate
                         occurrencesPerDay:(NSUInteger)occurrencesPerDay
                                daysToSkip:(NSUInteger)daysToSkip
                                   endDate:(nullable NSDateComponents *)endDate {
    return [[OCKCareDailySchedule alloc] initWithStartDate:startDate
                                               daysToSkip:daysToSkip
                                        occurrencesPerDay:occurrencesPerDay
                                                   endDate:endDate];
}

+ (instancetype)weeklyScheduleWithStartDate:(NSDateComponents *)startDate
                       occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFromSundayToSaturday
                                weeksToSkip:(NSUInteger)weeksToSkip
                                    endDate:(nullable NSDateComponents *)endDate {
    return [[OCKCareWeeklySchedule alloc] initWithStartDate:startDate
                                               weeksToSkip:weeksToSkip
                                      occurrencesOnEachDay:occurrencesFromSundayToSaturday
                                                    endDate:endDate];
}

- (instancetype)initWithStartDate:(NSDateComponents *)startDate
                          endDate:(NSDateComponents *)endDate
                      occurrences:(NSArray<NSNumber *> *)occurrences
                  timeUnitsToSkip:(NSUInteger)timeUnitsToSkip {
    
    OCKThrowInvalidArgumentExceptionIfNil(startDate);
    if (endDate) {
        NSAssert(![startDate isLaterThan:endDate], @"startDate should be earlier than endDate.");
    }
    
    self = [super init];
    if (self) {
        _startDate = [startDate validatedDateComponents];
        _endDate = [endDate validatedDateComponents];
        _occurrences = [occurrences copy];
        _timeUnitsToSkip = timeUnitsToSkip;
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
    OCKCareSchedule *schedule = [[[self class] alloc] initWithStartDate:self.startDate endDate:self.endDate occurrences:self.occurrences timeUnitsToSkip:self.timeUnitsToSkip];
    return schedule;
}

- (BOOL)isDateInRange:(NSDateComponents *)day {
    return (([day isLaterThan:_startDate] || [day isEqualToDate:_startDate]) &&
            (_endDate == nil || [day isEarlierThan:_endDate] || [day isEqualToDate:_endDate]));
}

- (NSCalendar *)UTC_calendar {
    if (!_calendar) {
        _calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        _calendar.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    }
    return _calendar;
}

- (NSUInteger)numberOfEventsOnDate:(NSDateComponents *)day {
    OCKThrowMethodUnavailableException();
}

- (NSUInteger)numberOfDaySinceStart:(NSDateComponents *)day {
    
    NSCalendar *calendar = [self UTC_calendar];
    NSInteger startDate = [calendar ordinalityOfUnit:NSCalendarUnitDay
                                             inUnit:NSCalendarUnitEra
                                            forDate:[_startDate UTC_dateWithGregorianCalendar]];
    
    NSInteger endDate = [calendar ordinalityOfUnit:NSCalendarUnitDay
                                           inUnit:NSCalendarUnitEra
                                          forDate:[day UTC_dateWithGregorianCalendar]];

    NSUInteger daysSinceStart = endDate - startDate;
    return daysSinceStart;
}

-(void)setEndDate:(NSDateComponents *)endDate {
    NSAssert(![_startDate isLaterThan:endDate], @"startDate should be earlier than endDate. %@ %@", _startDate, endDate);
    _endDate = [endDate validatedDateComponents];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@ %@", [super description], _startDate, _endDate];
}

- (OCKCareScheduleType)type {
    return OCKCareScheduleTypeOther;
}

@end


@implementation OCKCareDailySchedule

- (OCKCareScheduleType)type {
    return OCKCareScheduleTypeDaily;
}

- (instancetype)initWithStartDate:(NSDateComponents *)startDate
                       daysToSkip:(NSUInteger)daysToSkip
                occurrencesPerDay:(NSUInteger)occurrencesPerDay
                          endDate:(nullable NSDateComponents *)endDate {
    self = [self initWithStartDate:startDate endDate:endDate occurrences: @[@(occurrencesPerDay)] timeUnitsToSkip:daysToSkip];
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
                          endDate:(nullable NSDateComponents *)endDate {
    
    OCKThrowInvalidArgumentExceptionIfNil(occurrencesFromSundayToSaturday);
    NSParameterAssert(occurrencesFromSundayToSaturday.count == 7);
    
    self = [self initWithStartDate:startDate endDate:endDate occurrences:occurrencesFromSundayToSaturday timeUnitsToSkip:weeksToSkip];
    return self;
}

- (NSUInteger)numberOfEventsOnDate:(NSDateComponents *)day {
    NSUInteger occurrences = 0;
    if ([self isDateInRange:day]) {
        NSCalendar *calendar = [self UTC_calendar];
        
        NSInteger startWeek = [calendar ordinalityOfUnit:NSCalendarUnitWeekOfYear
                                                 inUnit:NSCalendarUnitEra
                                                forDate:[self.startDate UTC_dateWithGregorianCalendar]];
        
        NSInteger endWeek = [calendar ordinalityOfUnit:NSCalendarUnitWeekOfYear
                                               inUnit:NSCalendarUnitEra
                                              forDate:[day UTC_dateWithGregorianCalendar]];
       
        NSUInteger weeksSinceStart = endWeek - startWeek;
        NSUInteger weekday = [calendar component:NSCalendarUnitWeekday fromDate:[day UTC_dateWithGregorianCalendar]];
        occurrences = ((weeksSinceStart % (self.timeUnitsToSkip + 1)) == 0) ? self.occurrences[weekday-1].unsignedIntegerValue : 0;
    }
    return occurrences;
}

@end
