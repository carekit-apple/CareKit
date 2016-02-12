//
//  OCKChart.h
//  CareKit
//
//  Created by Umer Khan on 1/20/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@protocol OCKChartAxisProtocol <NSObject>

@property (nonatomic, copy, nullable) NSString *xAxisTitle;
@property (nonatomic, copy, nullable) NSString *yAxisTitle;

@end


@interface OCKChart : NSObject <NSSecureCoding, NSCopying>

+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *text;
@property (nonatomic, strong, null_resettable) UIColor *tintColor;
@property (nonatomic) CGFloat height;

@end

NS_ASSUME_NONNULL_END
