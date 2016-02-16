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


typedef struct _OCKDayRange {
    NSUInteger daysBeforeEventDay;
    NSUInteger daysAfterEventDay;
} OCKDayRange;

/**
 Abstract care plan activity Class
 */
@interface OCKCarePlanActivity : NSObject <NSSecureCoding, NSCopying>

- (instancetype)init NS_UNAVAILABLE;

/**
 Unique identifier of this item.
 */
@property (nonatomic, readonly) NSString *identifier;

/**
 Type is a string can be used to group different items into sets .
 */
@property (nonatomic, readonly) NSString *type;

/**
 Displayable title.
 */
@property (nonatomic, readonly, nullable) NSString *title;

/**
 Displayable text.
 */
@property (nonatomic, readonly, nullable) NSString *text;

/**
 A color can be used to render UI.
 */
@property (nonatomic, readonly, nullable) UIColor *color;

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
 [0, 0] means event is only mutable during event day.
 [1, 1] means event is mutable one day before event day, event day, and one day after event day.
 */
@property (nonatomic, readonly) OCKDayRange eventMutableDayRange;

@end

NS_ASSUME_NONNULL_END