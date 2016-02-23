//
//  OCKCarePlanEventResult.h
//  CareKit
//
//  Created by Yuan Zhu on 2/17/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OCKCarePlanEventResult : NSObject

- (instancetype)initWithValueString:(NSString *)valueString
                         unitString:(nullable NSString *)unitString
                           userInfo:(nullable NSDictionary *)userInfo;
/*
 When this result object is created.
 */
@property (nonatomic, strong, readonly) NSDate *creationDate;

@property (nonatomic, copy, readonly) NSString *valueString;

@property (nonatomic, copy, readonly, nullable) NSString *unitString;

@property (nonatomic, copy, readonly, nullable) NSDictionary *userInfo;

@end


NS_ASSUME_NONNULL_END