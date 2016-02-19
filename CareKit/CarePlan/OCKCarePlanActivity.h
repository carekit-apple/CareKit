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
    OCKCarePlanActivityTypeTreatment,
    OCKCarePlanActivityTypeAssessment
};


typedef struct _OCKDayRange {
    NSUInteger daysBeforeEventDay;
    NSUInteger daysAfterEventDay;
} OCKDayRange;

/**
 Abstract care plan activity Class
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
                         tintColor:(nullable UIColor *)tintColor
                          schedule:(OCKCareSchedule *)schedule
                          optional:(BOOL)optional
              eventMutableDayRange:(OCKDayRange)eventMutableDayRange
                  resultResettable:(BOOL)resultResettable
                          userInfo:(nullable NSDictionary *)userInfo;

/**
 Unique identifier of this item.
 */
@property (nonatomic, readonly) NSString *identifier;

/**
 Type is a string can be used to group different items into sets .
 */
@property (nonatomic, readonly) NSString *groupIdentifier;


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
 A color can be used to render UI.
 */
@property (nonatomic, readonly, nullable) UIColor *tintColor;

/**
 Schedule defines the start/end and reoccurence pattern.
 */
@property (nonatomic, readonly) OCKCareSchedule *schedule;

/**
 Whether this plan item is optional
 */
@property (nonatomic, readonly) BOOL optional;

/**
 When a user is able to respond to an event.
 [0, 0] means event is only mutable during event day. Which is the default value.
 [1, 1] means event is mutable one day before event day, event day, and one day after event day.
 */
@property (nonatomic, readonly) OCKDayRange eventMutableDayRange;

/**
 Allow user to reset the result of an event.
 Default value is NO.
 */
@property (nonatomic, readonly) BOOL resultResettable;

/**
 Developer can save any custom object which is NSCoding complianced.
 */
@property (nonatomic, copy, readonly, nullable) NSDictionary *userInfo;

@end

NS_ASSUME_NONNULL_END