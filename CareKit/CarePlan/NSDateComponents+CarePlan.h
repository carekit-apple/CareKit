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


#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

/**
 NSDateComponents CarePlan category provides convenient intializers to define date representation in Gregorian calendar.
 
 OCKCarePlanStore and OCKCareSchedule only accept date(NSDateComponents) representation in Gregorian calendar.
 */
@interface NSDateComponents (CarePlan)

/**
 Convenience initializer takes Year/Month/Day from Gregorian calendar.
 
 Era will be set to default value 1.
 
 @param year    Year value in Gregorian calendar.
 @param month   Month value in Gregorian calendar.
 @param day     Day in month value in Gregorian calendar.
 
 @return Intialized date representation in Gregorian calendar.
 */
- (instancetype)initWithYear:(NSInteger)year
                       month:(NSInteger)month
                         day:(NSInteger)day;

/**
 Convenience initializer takes a NSDate and a calendar to parse it date representation in Gregorian calendar.
 
 @param date        UTC date.
 @param calendar    Calendar for interprecting the date .
 
 @return Intialized date representation in Gregorian calendar.
 */
- (instancetype)initWithDate:(NSDate *)date
                    calendar:(NSCalendar *)calendar;

@end

NS_ASSUME_NONNULL_END

