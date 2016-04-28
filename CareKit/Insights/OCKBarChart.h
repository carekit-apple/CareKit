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


#import <CareKit/CareKit.h>


NS_ASSUME_NONNULL_BEGIN

/**
 The `OCKBarChart` represents a vertical grouped bar chart.
 */
OCK_CLASS_AVAILABLE
@interface OCKBarChart : OCKChart

- (instancetype)init NS_UNAVAILABLE;

/**
 Returns an initialzed bar chart using the specified values.
 The number of categories is determined by the array with the largest count.
 
 @param title                       The title for the chart (see `OCKInsightItem`).
 @param text                        The description text for the chart (see `OCKInsightItem`).
 @param tintColor                   The tint color for the chart (see `OCKInsightItem`).
 @param axisTitles                  An array of strings representing the y-axis title for each category.
 @param axisSubtitles               An array of strings representing the y-axis subtitle for each category.
 @param dataSeries                  An array of `OCKBarSeries` objects.
 @param minimumScaleRangeValue      The minimum value of scale range.
 @param maximumScaleRangeValue      The maximum value of scale range.
 
 @return An initialzed bar chart object.
 */
- (instancetype)initWithTitle:(nullable NSString *)title
                         text:(nullable NSString *)text
                    tintColor:(nullable UIColor *)tintColor
                   axisTitles:(nullable NSArray<NSString *> *)axisTitles
                axisSubtitles:(nullable NSArray<NSString *> *)axisSubtitles
                   dataSeries:(NSArray<OCKBarSeries *> *)dataSeries
       minimumScaleRangeValue:(nullable NSNumber *)minimumScaleRangeValue
       maximumScaleRangeValue:(nullable NSNumber *)maximumScaleRangeValue;

/**
 Returns an initialzed bar chart using the specified values.
 The number of categories is determined by the array with the largest count.
 
 @param title                       The title for the chart (see `OCKInsightItem`).
 @param text                        The description text for the chart (see `OCKInsightItem`).
 @param tintColor                   The tint color for the chart (see `OCKInsightItem`).
 @param axisTitles                  An array of strings representing the y-axis title for each category.
 @param axisSubtitles               An array of strings representing the y-axis subtitle for each category.
 @param dataSeries                  An array of `OCKBarSeries` objects.
 
 @return An initialzed bar chart object.
 */
- (instancetype)initWithTitle:(nullable NSString *)title
                         text:(nullable NSString *)text
                    tintColor:(nullable UIColor *)tintColor
                   axisTitles:(nullable NSArray<NSString *> *)axisTitles
                axisSubtitles:(nullable NSArray<NSString *> *)axisSubtitles
                   dataSeries:(NSArray<OCKBarSeries *> *)dataSeries;

/**
 An array of strings representing the axis titles.
 */
@property (nonatomic, copy, readonly, nullable) NSArray<NSString *> *axisTitles;

/**
 An array of strings representing the axis subtitles.
 */
@property (nonatomic, copy, readonly, nullable) NSArray<NSString *> *axisSubtitles;

/**
 An array of data series.
 */
@property (nonatomic, copy, readonly) NSArray<OCKBarSeries *> *dataSeries;

/**
 Maximum value of scale range.
 If this value is not specified, the maximum value is determined automatically.
 
 The specified maximum value will be ignored if it is less than the maximum value of the bar values.
 */
@property (nonatomic, readonly, nullable) NSNumber *maximumScaleRangeValue;


/**
 Minimum value of scale range.
 If this value is not specified, the minimum value is determined automatically.
 
 The specified minimum value will be ignored if it is greater than the minimum value of the bar values.
 */
@property (nonatomic, readonly, nullable) NSNumber *minimumScaleRangeValue;


@end

NS_ASSUME_NONNULL_END
