//
//  OCKChart.h
//  CareKit
//
//  Created by Umer Khan on 1/20/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface OCKChart : NSObject <NSSecureCoding, NSCopying>

+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *text;
@property (nonatomic, strong, null_resettable) UIColor *tintColor;

+ (void)animateView:(UIView *)view withDuration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END
