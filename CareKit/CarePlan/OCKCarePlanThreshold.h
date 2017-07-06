/*
 Copyright (c) 2017, Apple Inc. All rights reserved.
 
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
 Defines the types of thresholds.
 
 The numeric threshold types are paired with an assessment activity and evaluated against numeric results for that assessment.
 
 The adherance threshold type is paired with a day in a schedule and evaluated against the number of completed events for a given activity on that day.
 */
typedef NS_ENUM(NSInteger, OCKCarePlanThresholdType) {
    // Alert if the activity does not reach the given number of completed events on a day.
    OCKCarePlanThresholdTypeAdherance,
    // Alert if the numeric result is greater than the given value.
    OCKCarePlanThresholdTypeNumericGreaterThan,
    // Alert if the numeric result is greater than or equal to the given value.
    OCKCarePlanThresholdTypeNumericGreaterThanOrEqual,
    // Alert if the numeric result is less than the given value.
    OCKCarePlanThresholdTypeNumericLessThan,
    // Alert if the numeric result is less than or equal to the given value.
    OCKCarePlanThresholdTypeNumericLessThanOrEqual,
    // Alert if the numeric result is equal to the given value.
    OCKCarePlanThresholdTypeNumericEqual,
    // Alert if the numeric result is inside the range [value, upperValue] inclusive.
    OCKCarePlanThresholdTypeNumericRangeInclusive,
    // Alert if the numeric result is inside the range (value, upperValue) exclusive.
    OCKCarePlanThresholdTypeNumericRangeExclusive
};


@interface OCKCarePlanThreshold : NSObject <NSSecureCoding, NSCopying>

- (instancetype)init NS_UNAVAILABLE;

/**
 Convienience initializer for the adherance type threshold.
 This initializer covers necessary attributes for building an adherance threshold.
 
 @param value       The value of the threshold (triggers if less than this value of events are completed).
 @param title       The title associated with the threshold.
 
 @return Initialized OCKCarePlanThreshold instance.
 */
+ (instancetype)adheranceThresholdWithValue:(NSNumber*)value
                                      title:(nullable NSString*)title;
/**
 Convienience initializer for numeric type thresholds.
 This initializer covers necessary attributes for building a numeric threshold.
 
 @param value       The value of the threshold.
 @param type        The type of numeric threshold.
 @param upperValue  The upper value of the threshold, for RangeInclusive and RangeExclusive.
 @param title       The title associated with the threshold.
 
 @return Initialized OCKCarePlanThreshold instance.
 */
+ (instancetype)numericThresholdWithValue:(NSNumber *)value
                                   type:(OCKCarePlanThresholdType)type
                             upperValue:(nullable NSNumber*)upperValue
                                   title:(nullable NSString*)title;

/**
 Evaluates the threshold against a given value.
 
 @param valueToCheck    The value used in evaluating the threshold.
 
 @return    BOOL whether or not the threshold was triggered.
 */
- (BOOL)evaluateThresholdForValue:(NSNumber *)valueToCheck;

/**
 The type of threshold.
 */
@property (nonatomic, readonly) OCKCarePlanThresholdType type;

/**
 The primary value of the threshold.
 */
@property (nonatomic, readonly) NSNumber *value;

/**
 The title associated with the threshold.
 Will be displayed to the user if the threshold is triggered.
 */
@property (nonatomic, readonly, nullable) NSString *title;

/**
 The optional upper value of the threshold.
 Only used for NumericRangeInclusive and NumericRangeExclusive threshold types.
 */
@property (nonatomic, readonly, nullable) NSNumber *upperValue;

@end

NS_ASSUME_NONNULL_END
