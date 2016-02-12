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
                    optional:(BOOL)optional;

@property (nonatomic, strong, readonly, nullable) id<ORKTask, NSSecureCoding> task;
//TODO: not working yet
@property (nonatomic, strong, readonly, nullable) ORKHealthKitQuantityTypeAnswerFormat *answerFormat;
//TODO: not working yet
@property (nonatomic, readonly) BOOL allowRedo;

@end

NS_ASSUME_NONNULL_END
