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
                     completionDate:(nullable NSDate *)completionDate
                           userInfo:(nullable NSDictionary *)userInfo;

@property (nonatomic, strong, readonly) NSDate *creationDate;

@property (nonatomic, strong, readonly) NSDate *completionDate;

@property (nonatomic, copy, readonly) NSString *valueString;

@property (nonatomic, copy, readonly, nullable) NSString *unitString;

@property (nonatomic, copy, readonly, nullable) NSDictionary *userInfo;

@end


NS_ASSUME_NONNULL_END