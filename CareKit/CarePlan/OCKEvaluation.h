//
//  OCKEvaluation.h
//  CareKit
//
//  Created by Yuan Zhu on 1/29/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CareKit/OCKCarePlanItem.h>
#import <ResearchKit/ResearchKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OCKEvaluation : OCKCarePlanItem

- (instancetype)initWithType:(nullable NSString *)type
                       title:(nullable NSString *)title
                        text:(nullable NSString *)text
                       color:(nullable UIColor *)color
                    schedule:(OCKCareSchedule *)schedule
                        task:(nullable id<ORKTask, NSSecureCoding>)task
                    optional:(BOOL)optional
                  retryLimit:(NSUInteger)retryLimit;


/**
 A task object defines the evaluation.
 Optional.
 */
@property (nonatomic, strong, readonly, nullable) id<ORKTask, NSSecureCoding> task;

/**
 How many times user can retry an evaluation during a day.
 0 stands for unlimited.
 */
@property (nonatomic, readonly) NSUInteger retryLimit;

@end

NS_ASSUME_NONNULL_END
