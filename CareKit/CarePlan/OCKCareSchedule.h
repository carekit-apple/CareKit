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


#import "OCKDefines.h"


NS_ASSUME_NONNULL_BEGIN

/**
 Defines the schedule types.
 Daily and weekly are predefined types.
 You can subclass the OCKCareScheduleclass to support other types of schedules. These will have the type OCKCareScheduleTypeOther.
 */
OCK_ENUM_AVAILABLE
typedef NS_ENUM(NSInteger, OCKCareScheduleType) {
    /** Same occurrence rate on each day. */
    OCKCareScheduleTypeDaily,
    /** Different occurrence rate on each day in week. */
    OCKCareScheduleTypeWeekly,
    /** Other type */
    OCKCareScheduleTypeOther
};


/**
 An OCKCareSchedule class instance defines start and end dates, and the reccurrence pattern for an activity.
 OCKCareSchedule works only with the Gregorian calendar.
 You must convert date components that use another calendar to the Gregorian calendar before sending to OCKCareSchedule.
 
 Subclass `OCKCareSchedule` to support other type of schedules.
 A subclass must implement numberOfEventsOnDate: and conform to the NSSecureCoding and NSCopying protocols.
 */
OCK_CLASS_AVAILABLE
@interface OCKCareSchedule : NSObject <NSSecureCoding, NSCopying>

- (instancetype)init NS_UNAVAILABLE;

/**
 Defines a schedule that has the same number of occurrences each day.
 
 You can set the end date later by using the CarePlanStore API.
 
 @param startDate           Start date for a schedule, using the Gregorian calendar.
 @param occurrencesPerDay   Number of occurrences in each day.
 
 @return    An OCKCareSchedule instance.
 */
+ (instancetype)dailyScheduleWithStartDate:(NSDateComponents *)startDate
                         occurrencesPerDay:(NSUInteger)occurrencesPerDay;

/**
 Defines a schedule that repeats every week.
 
 Each weekday can have a different number of occurrences.
 You can set the end date later by using the CarePlanStore API.
 
 @param startDate                       Start date for a schedule, using the Gregorian calendar.
 @param occurrencesFromSundayToSaturday Number of occurrences for Sunday through Saturday.
 
 @return    An OCKCareSchedule instance.
 */
+ (instancetype)weeklyScheduleWithStartDate:(NSDateComponents *)startDate
                       occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFromSundayToSaturday;

/**
 Defines a schedule that has the same number of occurrences every day.
 
 @param startDate           Start date for a schedule, using the Gregorian calendar.
 @param occurrencesPerDay   Number of occurrences in each day.
 @param daysToSkip          Number of days between two active days during this period for which the schedule has no occurrence. 
                            (That is, number of skipped days.)
                            First day of a schedule is recognized as an active day.
 @param endDate             End date for a schedule, , using the Gregorian calendar.
 
 @return    An OCKCareSchedule instance.
 */
+ (instancetype)dailyScheduleWithStartDate:(NSDateComponents *)startDate
                         occurrencesPerDay:(NSUInteger)occurrencesPerDay
                                daysToSkip:(NSUInteger)daysToSkip
                                   endDate:(nullable NSDateComponents *)endDate;

/**
 Defines a schedule that repeats every week.
 
 Each weekday can have a different number of occurrences.
 
 @param startDate                       Start date for a schedule, using the Gregorian calendar.
 @param occurrencesFromSundayToSaturday Number of occurrences in each day.
 @param weeksToSkip                     Number of weeks between two active weeks during this period for which the schedule has no occurrence.
                                        (That is, number of skipped weeks.)
 @param endDate                         End date for a schedule, , using the Gregorian calendar.
 
 @return    An OCKCareSchedule instance.
 */
+ (instancetype)weeklyScheduleWithStartDate:(NSDateComponents *)startDate
                       occurrencesOnEachDay:(NSArray<NSNumber *> *)occurrencesFromSundayToSaturday
                                weeksToSkip:(NSUInteger)weeksToSkip
                                    endDate:(nullable NSDateComponents *)endDate;

/**
 Type of schedule.
 */
@property (nonatomic, readonly) OCKCareScheduleType type;

/**
 Start date of schedule.
 
 Gregorian calendar representation of a date.
 Only Era/Year/Month/Day attributes are observed.
 Date components in another calendar must be converted to the Gregorian calendar before using in an OCKCareSchedule object.
 */
@property (nonatomic, readonly) NSDateComponents *startDate;

/**
 End date of schedule.
 
 Gregorian calendar representation of a date.
 Only Era/Year/Month/Day attributes are observed.
 Date components in another calendar must be converted to the Gregorian calendar before using in an OCKCareSchedule object.
 */
@property (nonatomic, readonly, nullable) NSDateComponents *endDate;

/**
 How many occurrences in each day within the time range.
 
 Daily schedule has only one number in array.
 Weekly schedule has 7 numbers mapping from Sunday to Saturday.
 */
@property (nonatomic, copy, readonly) NSArray<NSNumber *> *occurrences;

/**
 Number of inactive time units between two active time units.
 During this period, schedule has no occurrence.
 
 For daily schedule, first day of a schedule is recognized as an active day.
 For weekly schedule, first week of a schedule is recognized as an active week.
 */
@property (nonatomic, readonly) NSUInteger timeUnitsToSkip;


/**
 How many events (occurrences) on a date.
 
 @param date        Gregorian calendar representation of a date.
                    Only Era/Year/Month/Day attributes are observed.
 
 @return    The number of events on the specified date.
 */
- (NSUInteger)numberOfEventsOnDate:(NSDateComponents *)date;

@end

NS_ASSUME_NONNULL_END
