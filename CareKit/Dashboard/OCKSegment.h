//
//  OCKSegment.h
//  CareKit
//
//  Created by Umer Khan on 1/20/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface OCKSegment : NSObject <NSSecureCoding, NSCopying>

+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)segmentWithValue:(CGFloat)value
                           color:(nullable UIColor *)color
                           title:(nullable NSString *)title;
+ (instancetype)segmentWithValue:(CGFloat)value;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithValue:(CGFloat)value
                        color:(nullable UIColor *)color
                        title:(nullable NSString *)title;
- (instancetype)initWithValue:(CGFloat)value;

@property (readonly) CGFloat value;
@property (nonatomic, strong, null_resettable) UIColor *color;
@property (nonatomic, copy, nullable) NSString *title;

@end

NS_ASSUME_NONNULL_END
