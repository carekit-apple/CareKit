//
//  OCKRangeGroup.h
//  CareKit
//
//  Created by Umer Khan on 1/20/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "OCKRangePoint.h"


NS_ASSUME_NONNULL_BEGIN

@interface OCKRangeGroup : NSObject <NSSecureCoding, NSCopying>

+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)rangeGroupWithRangePoints:(NSArray <OCKRangePoint *> *)points
                                    color:(nullable UIColor *)color;
+ (instancetype)rangeGroupWithRangePoints:(NSArray <OCKRangePoint *> *)points;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithRangePoints:(NSArray <OCKRangePoint *> *)points
                              color:(nullable UIColor *)color;
- (instancetype)initWithRangePoints:(NSArray <OCKRangePoint *> *)points;

@property (nonatomic, readonly) NSArray <OCKRangePoint *> *points;
@property (nonatomic, strong, null_resettable) UIColor *color;

@end

NS_ASSUME_NONNULL_END
