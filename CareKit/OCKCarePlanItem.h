//
//  OCKCarePlanItem.h
//  CareKit
//
//  Created by Yuan Zhu on 2/1/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CareKit/OCKCareSchedule.h>

NS_ASSUME_NONNULL_BEGIN

@interface OCKCarePlanItem : NSObject <NSSecureCoding, NSCopying>

- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, readonly) NSString *identifier;

@property (nonatomic, readonly) NSString *type;

@property (nonatomic, readonly, nullable) NSString *title;

@property (nonatomic, readonly, nullable) NSString *text;

@property (nonatomic, readonly, nullable) UIColor *color;

@property (nonatomic, readonly) OCKCareSchedule *schedule;

@property (nonatomic, readonly) BOOL optional;

// TODO: not working yet!
@property (nonatomic, readonly) BOOL onlyMutableInEventDay;

@end

NS_ASSUME_NONNULL_END