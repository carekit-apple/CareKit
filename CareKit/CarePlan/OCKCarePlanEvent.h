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


#import <CareKit/OCKCarePlanActivity.h>
#import <CareKit/OCKCarePlanEventResult.h>
#import <CareKit/OCKDefines.h>


NS_ASSUME_NONNULL_BEGIN

/**
 The possible states for an `OCKCarePlanEvent` object.
 */
OCK_ENUM_AVAILABLE
typedef NS_ENUM(NSInteger, OCKCarePlanEventState) {
    /** Initial state with no response. */
    OCKCarePlanEventStateInitial,
    /** Marked not completed. */
    OCKCarePlanEventStateNotCompleted,
    /** Marked completed. */
    OCKCarePlanEventStateCompleted
};


/**
 An instance of `OCKCarePlanEvent` defines an occurrence of an activty.
 An activity is uniquely defined by two indices: numberOfDaysSinceStart and occurrenceIndexOfDay. 
 For example, the second event on day 1 is defined using numberOfDaysSinceStart = 0 and occurrenceIndexOfDay = 1.
 
 An `OCKCarePlanEvent` instance cannot be created directly.
 All events are populated by saved activities in an OCKCarePlanStore object.
 
 Use OCKCarePlanStore API to update an event's state and change its result.
 */
OCK_CLASS_AVAILABLE
@interface OCKCarePlanEvent : NSObject 

- (instancetype)init NS_UNAVAILABLE;

/**
 The index of this event on a particular date. 
 For example, if an activity has three occurrences in a day, 
 then it would be represented by three CarePlanEvent objects with index 0, 1, 2 respectively.
 */
@property (nonatomic, readonly) NSUInteger occurrenceIndexOfDay;

/**
 Counting from the start date, the in which this event takes place. 
 For example, if the event is on start date, this value is 0
 */
@property (nonatomic, readonly) NSUInteger numberOfDaysSinceStart;

/**
 The date of this event, in the Gregorian calendar, represented by era, year, month, and day.
 */
@property (nonatomic, readonly) NSDateComponents *date;

/**
 The activity associated with this event.
 */
@property (nonatomic, readonly) OCKCarePlanActivity *activity;

/**
 The state of this event (Initial / NotCompleted / Completed).
 An event starts with the state set to Initial. 
 Use the OCKCarePlanStore API to update the state of an event.
 */
@property (nonatomic, readonly) OCKCarePlanEventState state;

/**
 A result object can be attached to event by using the OCKCarePlanStore API.
 */
@property (nonatomic, readonly, nullable) OCKCarePlanEventResult *result;

@end

NS_ASSUME_NONNULL_END
