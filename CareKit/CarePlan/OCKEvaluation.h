//
//  OCKEvaluation.h
//  CareKit
//
//  Created by Yuan Zhu on 1/29/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CareKit/OCKCarePlanActivity.h>
#import <ResearchKit/ResearchKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OCKEvaluation : OCKCarePlanActivity

- (instancetype)initWithIdentifier:(NSString *)identifier
                              type:(nullable NSString *)type
                             title:(nullable NSString *)title
                              text:(nullable NSString *)text
                             color:(nullable UIColor *)color
                          schedule:(OCKCareSchedule *)schedule
                              task:(nullable id<ORKTask, NSSecureCoding>)task
                          optional:(BOOL)optional
                        allowRetry:(NSUInteger)allowRetry;


/**
 A task object defines the evaluation.
 Optional.
 */
@property (nonatomic, strong, readonly, nullable) id<ORKTask, NSSecureCoding> task;

/**
 Allow user to retry an evaluation during a day.
 */
@property (nonatomic, readonly) BOOL allowRetry;

@end

NS_ASSUME_NONNULL_END
