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
#import <HealthKit/HealthKit.h>

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
                           userInfo:(nullable NSDictionary<NSString *, id<NSCoding>> *)userInfo;

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


/**
 Use HealthKit category if you have a HKSample object is aready in HealthKit to avoid saving duplicated health data.
 Simply pass in the HKSample object with value formatting parameters.
 OCKCarePlanStore only stores UUID and sample type from a HKSample object; 
 Each time the OCKCarePlanStore object uses UUID and type to fetch the actual sample object from HealthKit.
 
 An OCKCarePlanEventResult object uses the HKSample object with the value formatting parameters to populate `valueString` and `unitString`.
 */
@interface OCKCarePlanEventResult (HealthKit)

/**
 Initializer for creating an OCKCarePlanEventResult instance with a HKQuantitySample object.
 Attach created instance to an OCKCarePlanEvent object using the OCKCarePlanStore API.
 
 @param quantitySample          A HKQuantitySample object is in HealthKit.
 @param valueStringFormatter    A formatter formats the value to valueString.
 @param displayUnit             A prefered HKUnit object to display value.
 @param unitStringKeys          A dictionary of localized string keys for possible units.
 @param userInfo                Dictionary to save any additional objects that comply with the NSCoding protocol.
 
 @return Intialized instance.
 */
- (instancetype)initWithQuantitySample:(HKQuantitySample *)quantitySample
                  valueStringFormatter:(nullable NSNumberFormatter *)valueStringFormatter
                           displayUnit:(nullable HKUnit *)displayUnit
                        unitStringKeys:(NSDictionary<HKUnit *, NSString *> *)unitStringKeys
                              userInfo:(nullable NSDictionary<NSString *, id<NSCoding>> *)userInfo;

/**
 Initializer for creating an OCKCarePlanEventResult instance with a HKCorrelation object.
 Attach created instance to an OCKCarePlanEvent object using the OCKCarePlanStore API.
 
 @param correlation              A correlation object is in HealthKit.
                                (Only supports correlation with type HKCorrelationTypeIdentifierBloodPressure)
 @param valueStringFormatter    A formatter formats the systolic and diastolic blood pressure value to valueString.
 @param displayUnit             A prefered HKUnit object to display value.
 @param unitStringKeys          A dictionary of localized string keys for possible units.
 @param userInfo                Dictionary to save any additional objects that comply with the NSCoding protocol.
 
 @return Intialized instance.
 */
- (instancetype)initWitCorrelation:(HKCorrelation *)correlation
              valueStringFormatter:(nullable NSNumberFormatter *)valueStringFormatter
                       displayUnit:(nullable HKUnit *)displayUnit
                    unitStringKeys:(NSDictionary<HKUnit *, NSString *> *)unitStringKeys
                          userInfo:(nullable NSDictionary<NSString *, id<NSCoding>> *)userInfo;

/**
 Initializer for creating an OCKCarePlanEventResult instance with a HKCategorySample object.
 Attach created instance to an OCKCarePlanEvent object using the OCKCarePlanStore API.
 
 @param categorySample          A HKCategorySample object is in HealthKit.
 @param categoryValueStringKeys An array of localized string keys for the enum values in the HKCategorySample.
 @param userInfo                Dictionary to save any additional objects that comply with the NSCoding protocol.
 
 @return Intialized instance.
 */
- (instancetype)initWithCategorySample:(HKCategorySample *)categorySample
                       valueStringKeys:(NSArray<NSString *> *)categoryValueStringKeys
                              userInfo:(nullable NSDictionary<NSString *, id<NSCoding>> *)userInfo;

/**
 UUID of the HKSample object.
 */
@property (nonatomic, strong, readonly, nullable) NSUUID *sampleUUID;

/**
 Type of the HKSample object.
 */
@property (nonatomic, strong, readonly, nullable) HKSampleType *sampleType;

/**
 Prefered HKUnit object to display the value for a HKQuantitySample or HKCorrelation object.
 If this attribute is nil, the OCKCarePlanEventResult object uses a system prefered HKUnit object.
 */
@property (nonatomic, strong, readonly, nullable) HKUnit *displayUnit;

/**
 Localized string keys for units.
 If you provide a display unit, then this dictionary only needs one string key for the display unit.
 Otherwise, you need to provide string keys for all possible system prefered HKUnit objects.
 This attribute only applys to the sample is HKQuantitySample or HKCorrelation type.
 */
@property (nonatomic, copy, readonly, nullable) NSDictionary<HKUnit *, NSString *> * unitStringKeys;

/**
 Formats the quantity value of HKQuantitySample object to value string.
 
 If formatter is nil, framework uses
 `[NSNumberFormatter localizedStringFromNumber:@(value) numberStyle:NSNumberFormatterDecimalStyle]`.
 This attribute only applys to the sample is HKQuantitySample or HKCorrelation type.
 */
@property (nonatomic, strong, readonly, nullable) NSNumberFormatter *valueStringFormatter;

/**
 Localized string keys for the enum values in the HKCategorySample.
 The OCKCarePlanEventResult object use this string array to map an enum value to a string.
 This attribute only applys to the sample is HKCategorySample type.
 */
@property (nonatomic, copy, readonly, nullable) NSArray<NSString *> *categoryValueStringKeys;

/**
 The HKSample object.
 This sample itself is not persisted in care plan store to avoid saving duplicated health data.
 Each time store uses UUID and type to fetch the actual sample object from HealthKit.
 If the sample cannot be found in HealthKit, this attribute returns nil.
 */
@property (nonatomic, strong, readonly, nullable) HKSample *sample;

@end

NS_ASSUME_NONNULL_END
