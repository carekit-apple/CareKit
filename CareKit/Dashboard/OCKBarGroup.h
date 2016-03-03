//
//  OCKBarGroup.h
//  CareKit
//
//  Created by Umer Khan on 3/2/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface OCKBarGroup : NSObject <NSSecureCoding, NSCopying>

+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)barGroupWithTitle:(NSString *)title
                           values:(NSArray<NSNumber *> *)values
                      valueLabels:(NSArray<NSString *> *)valueLabels
                        tintColor:(UIColor *)tintColor;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithTitle:(NSString *)title
                       values:(NSArray<NSNumber *> *)values
                  valueLabels:(NSArray<NSString *> *)valueLabels
                    tintColor:(UIColor *)tintColor;

@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSArray<NSNumber *> *values;
@property (nonatomic, readonly) NSArray<NSString *> *valueLabels;
@property (nonatomic, readonly) UIColor *tintColor;

@end

NS_ASSUME_NONNULL_END
