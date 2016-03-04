//
//  OCKAdherenceChartView.h
//  CareKit
//
//  Created by Yuan Zhu on 2/29/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class OCKGroupedBarChartView;
@protocol OCKGroupedBarChartViewDataSource <NSObject>

- (NSInteger)numberOfGroupsInChartView:(OCKGroupedBarChartView *)chartView;

- (NSInteger)numberOfBarsPerGroupInChartView:(OCKGroupedBarChartView *)chartView;

- (UIColor *)chartView:(OCKGroupedBarChartView *)chartView colorForBar:(NSUInteger)barIndex;

- (NSString *)chartView:(OCKGroupedBarChartView *)chartView nameForBar:(NSUInteger)barIndex;

- (NSNumber *)chartView:(OCKGroupedBarChartView *)chartView valueForBar:(NSUInteger)barIndex inGroup:(NSUInteger)groupIndex;

- (nullable NSString *)chartView:(OCKGroupedBarChartView *)chartView stringForBar:(NSUInteger)barIndex inGroup:(NSUInteger)groupIndex;

- (nullable NSString *)chartView:(OCKGroupedBarChartView *)chartView titleForGroup:(NSUInteger)groupIndex;

@optional

- (NSString *)chartView:(OCKGroupedBarChartView *)chartView textForGroup:(NSUInteger)groupIndex;

@end


@interface OCKGroupedBarChartView : UIView

/*
 All the information for charting are provided by OCKGroupedBarChartViewDataSource.
 */
@property (nonatomic, weak, null_resettable) id<OCKGroupedBarChartViewDataSource> dataSource;


/*
 Show filling animation of all the bars.
 */
- (void)animateWithDuration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END
