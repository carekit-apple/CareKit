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
  The data source provides the information for a OCKGroupedBarChartView object to draw a group bar chart.
 */
@protocol OCKGroupedBarChartViewDataSource <NSObject>

@required
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
- (UIColor *)chartView:(OCKGroupedBarChartView *)chartView colorForDataSeriesAtIndex:(NSUInteger)dataSeriesIndex;

/**
 Name of a specified data series.
 It will be showed in legend view.
 
 @param     chartView           An object representing the chart view requesting this information.
 @param     dataSeriesIndex     Index of a data series.
 @return    Name of a specified data series.
 */
- (NSString *)chartView:(OCKGroupedBarChartView *)chartView nameForDataSeriesAtIndex:(NSUInteger)dataSeriesIndex;

/**
 Numeric value for bar at category index in a data series.
 
 @param     chartView           An object representing the chart view requesting this information.
 @param     categoryIndex       Index of a category.
 @param     dataSeriesIndex     Index of a data series.
 @return    Numeric value for bar.
 */
- (NSNumber *)chartView:(OCKGroupedBarChartView *)chartView valueForCategoryAtIndex:(NSUInteger)categoryIndex inDataSeriesAtIndex:(NSUInteger)dataSeriesIndex;

/**
 Value string for bar at category index in a data series.
 It will be displayed at the end of bar.
 
 @param     chartView           An object representing the chart view requesting this information.
 @param     categoryIndex       Index of a category.
 @param     dataSeriesIndex     Index of a data series.
 @return    Value string value for bar.
 */
- (nullable NSString *)chartView:(OCKGroupedBarChartView *)chartView valueStringForCategoryAtIndex:(NSUInteger)categoryIndex inDataSeriesAtIndex:(NSUInteger)dataSeriesIndex;

/**
 Title for a category.
 It will be showed as axis index label.
 
 @param     chartView           An object representing the chart view requesting this information.
 @param     categoryIndex       Index of a category.
 @return    Title of a category.
 */
- (nullable NSString *)chartView:(OCKGroupedBarChartView *)chartView titleForCategoryAtIndex:(NSUInteger)categoryIndex;

@optional

/**
 Subtitle for a category.
 It will be showed as axis index subtitle label.
 
 @param     chartView           An object representing the chart view requesting this information.
 @param     categoryIndex       Index of a category.
 @return    Subtitle of a category.
 */
- (nullable NSString *)chartView:(OCKGroupedBarChartView *)chartView subtitleForCategoryAtIndex:(NSUInteger)categoryIndex;

/**
 Maximum value of scale range.
 If this method is not implemented, the maximum value is determined automatically.
 The specified maximum value will be ignored if it is less than the maximum value of the bar values.
 
 @param     chartView           An object representing the chart view requesting this information.
 @return    Maximum value of scale range.
 */
- (nullable NSNumber *)maximumScaleRangeValueOfChartView:(OCKGroupedBarChartView *)chartView;

/**
 Minimum value of scale range.
 If this method is not implemented, the minimum value is determined automatically.
 The specified minimum value will be ignored if it is greater than the minimum value of the bar values.
 
 @param     chartView           An object representing the chart view requesting this information.
 @return    Minimum value of scale range.
 */
- (nullable NSNumber *)minimumScaleRangeValueOfChartView:(OCKGroupedBarChartView *)chartView;

@end


/**
 Class `OCKGroupedBarChartView` defines a view which can draw a grouped bar chart.
 */
@interface OCKGroupedBarChartView : UIView

/*
 All the information for charting are provided by OCKGroupedBarChartViewDataSource.
 */
@property (nonatomic, weak, nullable) id<OCKGroupedBarChartViewDataSource> dataSource;


/*
 Show animation of all the bars and value labels.
 
 @param duration Animation duration in seconds.
 */
- (void)animateWithDuration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END
