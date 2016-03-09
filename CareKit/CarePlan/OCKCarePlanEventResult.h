//
//  OCKCarePlanEventResult.h
//  CareKit
//
//  Created by Yuan Zhu on 2/17/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 OCKCarePlanEventResult defines a result object for an OCKCarePlanEvent.
 */
@interface OCKCarePlanEventResult : NSObject

- (instancetype)initWithValueString:(NSString *)valueString
                         unitString:(nullable NSString *)unitString
                           userInfo:(nullable NSDictionary *)userInfo;
/**
 When this result object is created.
 */
@property (nonatomic, strong, readonly) NSDate *creationDate;

/**
 Value string to be displayed in UI
 */
@property (nonatomic, copy, readonly) NSString *valueString;

/**
 Unit string to be displayed in UI
 */
@property (nonatomic, copy, readonly, nullable) NSString *unitString;

/**
 Use this to store NSCoding complianced objects.
 */
@property (nonatomic, copy, readonly, nullable) NSDictionary *userInfo;

@end


NS_ASSUME_NONNULL_END