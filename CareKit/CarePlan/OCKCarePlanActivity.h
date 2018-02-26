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


#import <UIKit/UIKit.h>
#import <CareKit/OCKCareSchedule.h>
#import <CareKit/OCKCarePlanThreshold.h>
#import <CareKit/OCKDefines.h>


NS_ASSUME_NONNULL_BEGIN

/**
 Defines the types of activities.
 
 The intervention activity type asks the user to do something related to treatment (such as take medication) 
 and reports the completion status (YES or NO) to the care plan.
 
 Assessment type activity asks user to perform a task in the app and the results can be displayed to user.
 */
OCK_ENUM_AVAILABLE
typedef NS_ENUM(NSInteger, OCKCarePlanActivityType) {
    /** Do something related to the treatment. */
    OCKCarePlanActivityTypeIntervention,
    /** Perform a task in the app. */
    OCKCarePlanActivityTypeAssessment,
    /** ReadOnly content for intervention and assessment. */
    OCKCarePlanActivityTypeReadOnly
};


/**
 An instance of the `OCKCarePlanActivity` class represents a task for user to complete based on a schedule.
 Each activity has a unique identifier.
 An `OCKCareSchedule` object defines the start date, end date, and the recurrence pattern for the activity.
 */
OCK_CLASS_AVAILABLE
@interface OCKCarePlanActivity : NSObject <NSSecureCoding, NSCopying>

- (instancetype)init NS_UNAVAILABLE;

/**
 Convenience initializer for intervention activity type.
 This initializer covers necessary attributes for building an intervention.
 
 @param identifier      Unique identifier string.
 @param groupIdentifier Group identifier string.
                        You can use the identifier to group similar activities.
 @param title           The title for the intervention activity.
 @param text            A descriptive text for the intervention activity.
 @param tintColor       The tint color for the intervention activity.
 @param instructions    Additional instructions for the intervention activity.
 @param imageURL        Image for the intervention activity.
 @param schedule        The schedule for the intervention activity.
 @param userInfo        Save any additional objects that comply with the NSCoding protocol.
 @param optional        Whether or not the activity is optional.

 
 @return Initialized OCKCarePlanActivity instance.
 */
+ (instancetype)interventionWithIdentifier:(NSString *)identifier
                           groupIdentifier:(nullable NSString *)groupIdentifier
                                     title:(NSString *)title
                                      text:(nullable NSString *)text
                                 tintColor:(nullable UIColor *)tintColor
                              instructions:(nullable NSString *)instructions
                                  imageURL:(nullable NSURL *)imageURL
                                  schedule:(OCKCareSchedule *)schedule
                                  userInfo:(nullable NSDictionary *)userInfo
                                  optional:(BOOL)optional;

/**
 Convenience initializer for the assessment activity type.
 This initializer covers necessary attributes for building an assessment.
 
 @param identifier          Unique identifier string.
 @param groupIdentifier     Group identifier string. 
                            You can use the identifier to group similar activities.
 @param title               The title for the assessment activity.
 @param text                A descriptive text for the assessment activity.
 @param tintColor           The tint color for the assessment activity.
 @param resultResettable    Whether or not to allow the user to retake the assessment.
 @param schedule            The schedule for the assessment activity.
 @param userInfo            Save any additional objects that comply with the NSCoding protocol.
 @param thresholds          An array of array of thresholds to apply to numeric result values.
 @param optional            Whether or not the activity is optional.
 
 @return Initialized OCKCarePlanActivity instance.
 */
+ (instancetype)assessmentWithIdentifier:(NSString *)identifier
                         groupIdentifier:(nullable NSString *)groupIdentifier
                                   title:(NSString *)title
                                    text:(nullable NSString *)text
                               tintColor:(nullable UIColor *)tintColor
                        resultResettable:(BOOL)resultResettable
                                schedule:(OCKCareSchedule *)schedule
                                userInfo:(nullable NSDictionary *)userInfo
                              thresholds:(nullable NSArray<NSArray<OCKCarePlanThreshold *> *> *)thresholds
                                optional:(BOOL)optional;


+ (instancetype)assessmentWithIdentifier:(NSString *)identifier
                         groupIdentifier:(nullable NSString *)groupIdentifier
                                   title:(NSString *)title
                                    text:(nullable NSString *)text
                               tintColor:(nullable UIColor *)tintColor
                        resultResettable:(BOOL)resultResettable
                                schedule:(OCKCareSchedule *)schedule
                                userInfo:(nullable NSDictionary *)userInfo
                                optional:(BOOL)optional;

/**
 Convenience initializer for read only activity type.
 This initializer covers necessary attributes for building read only activity.
 
 @param identifier      Unique identifier string.
 @param groupIdentifier Group identifier string.
 You can use the identifier to group similar activities, but they will all be grouped under Read Only section in the table view.
 @param title           The title for the read only activity.
 @param text            A descriptive text for the read only activity.
 @param instructions    Additional instructions for the read only activity.
 @param imageURL        Image for the read only activity.
 @param schedule        The schedule for the read only activity.
 @param userInfo        Save any additional objects that comply with the NSCoding protocol.
 
 
 @return Initialized OCKCarePlanActivity instance.
 */

+ (instancetype)readOnlyWithIdentifier:(NSString *)identifier
                                   groupIdentifier:(nullable NSString *)groupIdentifier
                                             title:(NSString *)title
                                              text:(nullable NSString *)text
                                      instructions:(nullable NSString *)instructions
                                          imageURL:(nullable NSURL *)imageURL
                                          schedule:(OCKCareSchedule *)schedule
                                          userInfo:(nullable NSDictionary *)userInfo;

/**
 Default initializer for OCKCarePlanActivity.
 
 @param identifier          Unique identifier string.
 @param groupIdentifier     Group identifier string.
                            You can use the identifier to group similar activities.
 @param type                Type defines the category of an activity.
 @param title               The title for the activity.
 @param text                A descriptive text for the activity.
 @param tintColor           The tint color for the activity.
 @param instructions        Long description string to be display in details view.
 @param imageURL            Optional image displayed in details view.
 @param schedule            The schedule for the activity.
 @param resultResettable    Whether or not to allow the user to retake the assessment.
 @param userInfo            Save any addtional NSCoding complianced objects.
 @param thresholds          An array of array of thresholds to apply to numeric result values.
 @param optional            Whether or not the activity is optional.
 
 @return Initialized OCKCarePlanActivity instance.
 */
- (instancetype)initWithIdentifier:(NSString *)identifier
                   groupIdentifier:(nullable NSString *)groupIdentifier
                              type:(OCKCarePlanActivityType)type
                             title:(NSString *)title
                              text:(nullable NSString *)text
                         tintColor:(nullable UIColor *)tintColor
                      instructions:(nullable NSString *)instructions
                          imageURL:(nullable NSURL *)imageURL
                          schedule:(OCKCareSchedule *)schedule
                  resultResettable:(BOOL)resultResettable
                          userInfo:(nullable NSDictionary<NSString *, id<NSCoding>> *)userInfo
                        thresholds:(nullable NSArray<NSArray<OCKCarePlanThreshold *> *> *)thresholds
                          optional:(BOOL)optional NS_DESIGNATED_INITIALIZER;



- (instancetype)initWithIdentifier:(NSString *)identifier
                   groupIdentifier:(nullable NSString *)groupIdentifier
                              type:(OCKCarePlanActivityType)type
                             title:(NSString *)title
                              text:(nullable NSString *)text
                         tintColor:(nullable UIColor *)tintColor
                      instructions:(nullable NSString *)instructions
                          imageURL:(nullable NSURL *)imageURL
                          schedule:(OCKCareSchedule *)schedule
                  resultResettable:(BOOL)resultResettable
                          userInfo:(nullable NSDictionary<NSString *, id<NSCoding>> *)userInfo;

/**
 Unique identifier string.
 In store scope, each activity's identifer has to be unique.
 You can use this identifier as a key to retrieve the activity instance from the store.
 */
@property (nonatomic, readonly) NSString *identifier;

/**
 Group identifier string.
 You can use the identifier to group similar activities.
 You can use this identifier as a key to retrieve multiple activity instances from the store.
 */
@property (nonatomic, readonly, nullable) NSString *groupIdentifier;


/**
 Type defines the category of an activity.
 
 The intervention activity type asks the user to do something related to treatment (such as take medication)
 and reports the completion status (YES or NO) to the care plan. 
 
 The assessment activity type asks the user to perform a task that evaluates their condition (such as complete a survey). 
 The result can be displayed to the user.
 */
@property (nonatomic, readonly) OCKCarePlanActivityType type;

/**
 The title for the activity.
 */
@property (nonatomic, readonly) NSString *title;

/**
 A descriptive text for the activity.
 */
@property (nonatomic, readonly, nullable) NSString *text;

/**
 The tint color for the activity.
 */
@property (nonatomic, readonly, nullable) UIColor *tintColor;

/**
 Additional instructions for the intervention activity.
 */
@property (nonatomic, readonly, nullable) NSString *instructions;

/**
 Image for the intervention activity.
 */
@property (nonatomic, readonly, nullable) NSURL *imageURL;

/**
 The schedule for the activity.
 The schedule defines the start and end date, and the recurrence pattern.
 */
@property (nonatomic, readonly) OCKCareSchedule *schedule;

/**
 Whether or not to allow the user to retake the assessment.
 This attribute has no effect in view controller.
 But developer can use this parameter to decide the behavior if a user want to redo a completed assessment.
 Default value is NO.
 */
@property (nonatomic, readonly) BOOL resultResettable;

/**
 Save any additional objects that comply with the NSCoding protocol.
 */
@property (nonatomic, copy, readonly, nullable) NSDictionary<NSString *, id<NSCoding>> *userInfo;

/**
 An optional array of array of thresholds pertianing to the values of associated results objects.
 These thresholds are checked against any numeric result values when an event's evaluateNumericThresholds()
    method is called.
 Each array of thresholds corresponds to one of the values in the result's value array.
 Because of this, thresholds can have either 1 or 2 sub-arrays.
 */
@property (nonatomic, copy, readonly, nullable) NSArray<NSArray<OCKCarePlanThreshold *> *> *thresholds;

/**
 Whether or not the activity is optional.
 
 An optional activity does not count towards total completion.
 Default value is NO.
 */
@property (nonatomic, readonly) BOOL optional;

@end

NS_ASSUME_NONNULL_END
