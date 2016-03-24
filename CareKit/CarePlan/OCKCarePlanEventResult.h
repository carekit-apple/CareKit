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


#import <CareKit/OCKDefines.h>


NS_ASSUME_NONNULL_BEGIN

/**
 The 'OCKCarePlanEventResult'class defines a result object for an OCKCarePlanEvent object. 
 Create an instance of this class and attach it to an event using the OCKCarePlanStore API.
 */
OCK_CLASS_AVAILABLE
@interface OCKCarePlanEventResult : NSObject

- (instancetype)init NS_UNAVAILABLE;

/**
 Initializer for creating an OCKCarePlanEventResult instance.
 Attach created instance to an OCKCarePlanEvent object using the OCKCarePlanStore API.
 
 @param valueString     Value string to be displayed to the user.
 @param unitString      Unit string to be displayed to the user.
 @param userInfo        Dictionary to save any additional objects that comply with the NSCoding protocol.
 
 @return Intialized instance.
 */
- (instancetype)initWithValueString:(NSString *)valueString
                         unitString:(nullable NSString *)unitString
                           userInfo:(nullable NSDictionary<NSString *, id<NSCoding>> *)userInfo NS_DESIGNATED_INITIALIZER;

/**
 The time the result object is created.
 */
@property (nonatomic, readonly) NSDate *creationDate;

/**
 A representative value string.
 */
@property (nonatomic, copy, readonly) NSString *valueString;

/**
 A representative unit string for the value string.
 */
@property (nonatomic, copy, readonly, nullable) NSString *unitString;

/**
 Use this dictionary to store objects that comply with the NSCoding protocol.
 */
@property (nonatomic, copy, readonly, nullable) NSDictionary<NSString *, id<NSCoding>> *userInfo;

@end

NS_ASSUME_NONNULL_END
