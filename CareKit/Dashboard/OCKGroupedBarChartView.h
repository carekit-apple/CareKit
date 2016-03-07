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

- (NSInteger)numberOfDataSeriesInChartView:(OCKGroupedBarChartView *)chartView;

- (NSInteger)numberOfCategoriesPerDataSeriesInChartView:(OCKGroupedBarChartView *)chartView;

- (UIColor *)chartView:(OCKGroupedBarChartView *)chartView colorForDataSeries:(NSUInteger)dataSeriesIndex;

- (NSString *)chartView:(OCKGroupedBarChartView *)chartView nameForDataSeries:(NSUInteger)dataSeriesIndex;

- (NSNumber *)chartView:(OCKGroupedBarChartView *)chartView valueForCategory:(NSUInteger)categoryIndex inDataSeries:(NSUInteger)dataSeriesIndex;

- (nullable NSString *)chartView:(OCKGroupedBarChartView *)chartView valueStringForCategory:(NSUInteger)categoryIndex inDataSeries:(NSUInteger)dataSeriesIndex;

- (nullable NSString *)chartView:(OCKGroupedBarChartView *)chartView titleForCategory:(NSUInteger)categoryIndex;

@optional

- (NSString *)chartView:(OCKGroupedBarChartView *)chartView subtitleForCategory:(NSUInteger)categoryIndex;

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
