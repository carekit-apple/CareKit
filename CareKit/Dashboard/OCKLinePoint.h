//
//  OCKLinePoint.h
//  CareKit
//
//  Created by Umer Khan on 1/20/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface OCKLinePoint : NSObject <NSSecureCoding, NSCopying>

+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)linePointWithValue:(CGFloat)value;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithValue:(CGFloat)value;

@property (readonly) CGFloat value;

@end

NS_ASSUME_NONNULL_END
