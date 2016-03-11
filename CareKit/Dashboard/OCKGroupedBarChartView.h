/*
 Copyright (c) 2016, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class OCKGroupedBarChartView;


/**
  The data source provides the OCKGroupedBarChartView object with the information it needs to draw a chart.
 */
@protocol OCKGroupedBarChartViewDataSource <NSObject>

/**
 Number of data series in this chart.
 Bars in a same data series share same metrics, color, and legend.
 The minimum value is 1.
 
 @param     chartView   An object representing the chart view requesting this information.
 @return    Number of data series.
 */
- (NSInteger)numberOfDataSeriesInChartView:(OCKGroupedBarChartView *)chartView;

/**
 Number of categories in this chart.
 Bars in a same category are displayed in a same group.
 Each data series should have same number of categories.
 The minimum value is 1.
 
 @param     chartView   An object representing the chart view requesting this information.
 @return    Number of categories.
 */
- (NSInteger)numberOfCategoriesPerDataSeriesInChartView:(OCKGroupedBarChartView *)chartView;

/**
 Bar color of a specified data series.
 
 @param     chartView           An object representing the chart view requesting this information.
 @param     dataSeriesIndex     Index of a data series.
 @return    Color of a specified data series.
 */
- (UIColor *)chartView:(OCKGroupedBarChartView *)chartView colorForDataSeries:(NSUInteger)dataSeriesIndex;

/**
 Name of a specified data series.
 It will be showed in legend view.
 
 @param     chartView           An object representing the chart view requesting this information.
 @param     dataSeriesIndex     Index of a data series.
 @return    Name of a specified data series.
 */
- (NSString *)chartView:(OCKGroupedBarChartView *)chartView nameForDataSeries:(NSUInteger)dataSeriesIndex;

/**
 Numeric value for bar at category index in a data series.
 
 @param     chartView           An object representing the chart view requesting this information.
 @param     categoryIndex       Index of a category.
 @param     dataSeriesIndex     Index of a data series.
 @return    Numeric value for bar.
 */
- (NSNumber *)chartView:(OCKGroupedBarChartView *)chartView valueForCategory:(NSUInteger)categoryIndex inDataSeries:(NSUInteger)dataSeriesIndex;

/**
 Value string for bar at category index in a data series.
 It will be displayed at the end of bar.
 
 @param     chartView           An object representing the chart view requesting this information.
 @param     categoryIndex       Index of a category.
 @param     dataSeriesIndex     Index of a data series.
 @return    Value string value for bar.
 */
- (nullable NSString *)chartView:(OCKGroupedBarChartView *)chartView valueStringForCategory:(NSUInteger)categoryIndex inDataSeries:(NSUInteger)dataSeriesIndex;

/**
 Title of a category.
 It will be showed at axis index label.
 
 @param     chartView           An object representing the chart view requesting this information.
 @param     categoryIndex       Index of a category.
 @return    Title of a category.
 */
- (nullable NSString *)chartView:(OCKGroupedBarChartView *)chartView titleForCategory:(NSUInteger)categoryIndex;

@optional

/**
 Subtitle of a category.
 It will be showed at axis index subtitle label.
 
 @param     chartView           An object representing the chart view requesting this information.
 @param     categoryIndex       Index of a category.
 @return    Subtitle of a category.
 */
- (NSString *)chartView:(OCKGroupedBarChartView *)chartView subtitleForCategory:(NSUInteger)categoryIndex;

@end


/**
 Class `OCKGroupedBarChartView` defines a view which can draw a grouped bar chart.
 */
@interface OCKGroupedBarChartView : UIView

/*
 All the information for charting are provided by OCKGroupedBarChartViewDataSource.
 */
@property (nonatomic, weak, null_resettable) id<OCKGroupedBarChartViewDataSource> dataSource;


/*
 Show filling animation of all the bars and value labels.
 */
- (void)animateWithDuration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END
