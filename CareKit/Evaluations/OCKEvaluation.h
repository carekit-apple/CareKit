//
//  OCKEvaluation.h
//  CareKit
//
//  Created by Umer Khan on 2/2/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <ResearchKit/ResearchKit.h>


NS_ASSUME_NONNULL_BEGIN

@class OCKEvaluation;

@protocol OCKEvaluationDelegate <NSObject>

@required
- (CGFloat)normalizedValueOfEvaluation:(OCKEvaluation *)evaluation
                         forTaskResult:(ORKTaskResult *)result;

@end


@interface OCKEvaluation : NSObject <NSSecureCoding, NSCopying>

+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)evaluationWithTitle:(NSString *)title
                               text:(NSString *)text
                               task:(ORKOrderedTask *)task
                           delegate:(id<OCKEvaluationDelegate>)delegate;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithTitle:(NSString *)title
                         text:(NSString *)text
                         task:(ORKOrderedTask *)task
                     delegate:(id<OCKEvaluationDelegate>)delegate;


@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, readonly) ORKOrderedTask *task;
@property (nonatomic) id<OCKEvaluationDelegate> delegate;
@property (nonatomic, strong, null_resettable) UIColor *tintColor;
@property (nonatomic, readonly) CGFloat value;

@end

NS_ASSUME_NONNULL_END
