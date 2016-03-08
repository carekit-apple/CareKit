//
//  OCKCarePlanActivity.h
//  CareKit
//
//  Created by Yuan Zhu on 2/1/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CareKit/OCKCareSchedule.h>

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSInteger, OCKCarePlanActivityType) {
    OCKCarePlanActivityTypeIntervention,
    OCKCarePlanActivityTypeAssessment
};

/**
  Care plan activity Class
 */
@interface OCKCarePlanActivity : NSObject <NSSecureCoding, NSCopying>

- (instancetype)init NS_UNAVAILABLE;


- (instancetype)initWithIdentifier:(NSString *)identifier
                              type:(OCKCarePlanActivityType)type
                             title:(nullable NSString *)title
                              text:(nullable NSString *)text
                         tintColor:(nullable UIColor *)tintColor
                          schedule:(OCKCareSchedule *)schedule;


- (instancetype)initWithIdentifier:(NSString *)identifier
                   groupIdentifier:(nullable NSString *)groupIdentifier
                              type:(OCKCarePlanActivityType)type
                             title:(nullable NSString *)title
                              text:(nullable NSString *)text
                        detailText:(nullable NSString *)detailText
                         tintColor:(nullable UIColor *)tintColor
                          schedule:(OCKCareSchedule *)schedule
                          optional:(BOOL)optional
              numberOfDaysWriteable:(NSUInteger)numberOfDaysWriteable
                  resultResettable:(BOOL)resultResettable
                          userInfo:(nullable NSDictionary *)userInfo;

/**
 Unique identifier of this item.
 */
@property (nonatomic, readonly) NSString *identifier;

/**
 Type is a string can be used to group different items into sets .
 */
@property (nonatomic, readonly, nullable) NSString *groupIdentifier;


/**
 Type is a string can be used to group different items into sets .
 */
@property (nonatomic, readonly) OCKCarePlanActivityType type;

/**
 String key for the Displayable title.
 */
@property (nonatomic, readonly, nullable) NSString *title;

/**
 Displayable text.
 */
@property (nonatomic, readonly, nullable) NSString *text;

/**
 Displayable detailed text.
 */
@property (nonatomic, readonly, nullable) NSString *detailText;

/**
 A color can be used in UI rendering.
 */
@property (nonatomic, readonly, nullable) UIColor *tintColor;

/**
 Schedule defines the start/end and reoccurence pattern.
 */
@property (nonatomic, readonly) OCKCareSchedule *schedule;

/**
 Whether this plan item is optional.
 Optional activity is not counting towards to total adherence rate.
 */
@property (nonatomic, readonly) BOOL optional;

/**
 For the events of this activity, how many days after the begin the event day, user is allowed to modify the response.
 Default value is 1, and min value is 1 as well. Indicating user can only respond to an event in its event day.
 */
@property (nonatomic, readonly) NSUInteger numberOfDaysWriteable;

/**
 Allow user to redo an assessment.
 This attribute only applies to assessments.
 Default value is NO.
 */
@property (nonatomic, readonly) BOOL resultResettable;

/**
 Developer can save any custom object which is NSCoding complianced.
 */
@property (nonatomic, copy, readonly, nullable) NSDictionary *userInfo;

@end

NS_ASSUME_NONNULL_END