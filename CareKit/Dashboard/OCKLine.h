//
//  OCKPlot.h
//  CareKit
//
//  Created by Umer Khan on 1/20/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "OCKLinePoint.h"


NS_ASSUME_NONNULL_BEGIN

@interface OCKLine : NSObject <NSSecureCoding, NSCopying>

+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)lineWithLinePoints:(NSArray <OCKLinePoint *> *)points
                              color:(nullable UIColor *)color;
+ (instancetype)lineWithLinePoints:(NSArray<OCKLinePoint *> *)points;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithLinePoints:(NSArray <OCKLinePoint *> *)points
                             color:(nullable UIColor *)color;
- (instancetype)initWithLinePoints:(NSArray <OCKLinePoint *> *)points;

@property (nonatomic, readonly) NSArray <OCKLinePoint *> *points;
@property (nonatomic, strong, null_resettable) UIColor *color;

@end

NS_ASSUME_NONNULL_END
