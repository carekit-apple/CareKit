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


#import "OCKCarePlanThreshold.h"
#import "OCKHelpers.h"


@implementation OCKCarePlanThreshold

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithType:(OCKCarePlanThresholdType)type
                       value:(NSNumber *)value
                       title:(NSString *)title
                  upperValue:(NSNumber *)upperValue {
    
    self = [super init];
    if (self) {
        _type = type;
        _value = [value copy];
        _title = [title copy];
        _upperValue = [upperValue copy];
    }
    
    return self;
}

+ (instancetype)adheranceThresholdWithValue:(NSNumber *)value
                                      title:(NSString *)title {
    return [[self alloc] initWithType:OCKCarePlanThresholdTypeAdherance
                                value:value
                                title:title
                           upperValue:nil];
}

+ (instancetype)numericThresholdWithValue:(NSNumber *)value
                                     type:(OCKCarePlanThresholdType)type
                               upperValue:(NSNumber *)upperValue
                                    title:(NSString *)title {
    return [[self alloc] initWithType:type
                                value:value
                                title:title
                           upperValue:upperValue];
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        OCK_DECODE_ENUM(coder, type);
        OCK_DECODE_OBJ_CLASS(coder, value, NSNumber);
        OCK_DECODE_OBJ_CLASS(coder, title, NSString);
        OCK_DECODE_OBJ_CLASS(coder, upperValue, NSNumber);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    OCK_ENCODE_ENUM(coder, type);
    OCK_ENCODE_OBJ(coder, value);
    OCK_ENCODE_OBJ(coder, title);
    OCK_ENCODE_OBJ(coder, upperValue);
}

- (BOOL)isEqual:(id)object {
    BOOL isClassMatch = ([self class] == [object class]);
    
    __typeof(self) castObject = object;
    return (isClassMatch &&
            self.type == castObject.type &&
            OCKEqualObjects(self.value, castObject.value) &&
            OCKEqualObjects(self.title, castObject.title) &&
            OCKEqualObjects(self.upperValue, castObject.upperValue)
            );
}

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKCarePlanThreshold *threshold = [[[self class] alloc] initWithType:self.type value:self.value title:self.title upperValue:self.upperValue];
    return threshold;
}



- (BOOL)evaluateThresholdForValue:(NSNumber *)valueToCheck {
    NSComparisonResult result = [self.value compare:valueToCheck];
    NSComparisonResult secondResult;
    switch (self.type) {
        case OCKCarePlanThresholdTypeAdherance:
            return (result == NSOrderedDescending);
            
        case OCKCarePlanThresholdTypeNumericGreaterThan:
            return (result == NSOrderedAscending);
            
        case OCKCarePlanThresholdTypeNumericGreaterThanOrEqual:
            return ((result == NSOrderedAscending) || (result == NSOrderedSame));
            
        case OCKCarePlanThresholdTypeNumericLessThan:
            return (result == NSOrderedDescending);
            
        case OCKCarePlanThresholdTypeNumericLessThanOrEqual:
            return ((result == NSOrderedDescending) || (result == NSOrderedSame));
            
        case OCKCarePlanThresholdTypeNumericEqual:
            return (result == NSOrderedSame);
            
        case OCKCarePlanThresholdTypeNumericRangeInclusive:
            secondResult = [self.upperValue compare:valueToCheck];
            return (((result == NSOrderedAscending) || (result == NSOrderedSame)) && ((secondResult == NSOrderedDescending) || (secondResult == NSOrderedSame)));
            
        case OCKCarePlanThresholdTypeNumericRangeExclusive:
            secondResult = [self.upperValue compare:valueToCheck];
            return ((result == NSOrderedAscending) && (secondResult == NSOrderedDescending));
    }
}

@end
