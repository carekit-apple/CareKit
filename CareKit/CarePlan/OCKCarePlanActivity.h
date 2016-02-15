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
 Allow user to report completion outside the day for a event
 */
@property (nonatomic, readonly) BOOL onlyMutableDuringEventDay;

@end

NS_ASSUME_NONNULL_END