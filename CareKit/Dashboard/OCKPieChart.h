//
//  OCKPieChart.h
//  CareKit
//
//  Created by Umer Khan on 1/20/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKChart.h"


NS_ASSUME_NONNULL_BEGIN

@class OCKSegment;

@interface OCKPieChart : OCKChart

+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)pieChartWithTitle:(nullable NSString *)title
                             text:(nullable NSString *)text
                         segments:(NSArray <OCKSegment *> *)segments;
+ (instancetype)pieChartWithSegments:(NSArray <OCKSegment *> *)segments;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithTitle:(nullable NSString *)title
                         text:(nullable NSString *)text
                     segments:(NSArray <OCKSegment *> *)segments;
- (instancetype)initWithSegments:(NSArray <OCKSegment *> *)segments;

@property (nonatomic, readonly) NSArray <OCKSegment *> *segments;
@property (nonatomic) BOOL showsPercentageLabels;
@property (nonatomic) BOOL usesLineSegments;

@end

NS_ASSUME_NONNULL_END
