//
//  OCKRangePoint.h
//  CareKit
//
//  Created by Umer Khan on 1/20/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface OCKRangePoint : NSObject <NSSecureCoding, NSCopying>

+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)rangePointWithMinimumValue:(CGFloat)minimumValue
                              maximumValue:(CGFloat)maximumValue;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithMinimumValue:(CGFloat)minimumValue
                        maximumValue:(CGFloat)maximumValue;

@property (readonly) CGFloat minimumValue;
@property (readonly) CGFloat maximumValue;

@end

NS_ASSUME_NONNULL_END
