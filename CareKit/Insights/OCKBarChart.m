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


#import "OCKBarChart.h"
#import "OCKBarSeries.h"
#import "OCKHelpers.h"
#import "OCKGroupedBarChartView.h"


@interface OCKBarChart() <OCKGroupedBarChartViewDataSource>

@end


@implementation OCKBarChart

+ (instancetype)new {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithTitle:(NSString *)title
                         text:(NSString *)text
                    tintColor:(UIColor *)tintColor
                   axisTitles:(NSArray<NSString *> *)axisTitles
                axisSubtitles:(NSArray<NSString *> *)axisSubtitles
                  chartHeight:(CGFloat)chartHeight
                   dataSeries:(NSArray<OCKBarSeries *> *)dataSeries {
    self = [super init];
    if (self) {
        self.title = [title copy];
        self.text = [text copy];
        self.tintColor = tintColor;
        _axisTitles = OCKArrayCopyObjects(axisTitles);
        _axisSubtitles = OCKArrayCopyObjects(axisSubtitles);
        _chartHeight = chartHeight;
        _dataSeries = OCKArrayCopyObjects(dataSeries);
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            OCKEqualObjects(self.axisTitles, castObject.axisTitles) &&
            OCKEqualObjects(self.axisSubtitles, castObject.axisSubtitles) &&
            (self.chartHeight == castObject.chartHeight) &&
            OCKEqualObjects(self.dataSeries, castObject.dataSeries));
}


#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        OCK_DECODE_OBJ_ARRAY(aDecoder, axisTitles, NSArray);
        OCK_DECODE_OBJ_ARRAY(aDecoder, axisSubtitles, NSArray);
        OCK_DECODE_DOUBLE(aDecoder, chartHeight);
        OCK_DECODE_OBJ_ARRAY(aDecoder, dataSeries, NSArray);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    OCK_ENCODE_OBJ(aCoder, axisTitles);
    OCK_ENCODE_OBJ(aCoder, axisSubtitles);
    OCK_ENCODE_OBJ(aCoder, dataSeries);
    OCK_ENCODE_DOUBLE(aCoder, chartHeight);
}


#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKBarChart *chart = [super copyWithZone:zone];
    chart->_axisTitles = OCKArrayCopyObjects(_axisTitles);
    chart->_axisSubtitles = OCKArrayCopyObjects(_axisSubtitles);
    chart->_chartHeight = _chartHeight;
    chart->_dataSeries = OCKArrayCopyObjects(_dataSeries);
    return chart;
}


#pragma mark - Helpers

- (BOOL)isCategoryIndex:(NSUInteger)index outofBoundsInArray:(NSArray *)array {
    return (index > array.count - 1);
}


#pragma mark - OCKGroupedBarChartViewDataSource

- (UIView *)chartView {
    OCKGroupedBarChartView *barChartView = [OCKGroupedBarChartView new];
    barChartView.dataSource = self;
    return barChartView;
}

- (CGFloat)height {
    return _chartHeight;
}

+ (void)animateView:(UIView *)view withDuration:(NSTimeInterval)duration {
    NSAssert([view isKindOfClass:[OCKGroupedBarChartView class]], @"View must be of type OCKGroupedBarChartView");
    OCKGroupedBarChartView *chartView = (OCKGroupedBarChartView *)view;
    [chartView animateWithDuration:duration];
}


#pragma mark - OCKGroupedBarChartDataSource

- (NSInteger)numberOfCategoriesPerDataSeriesInChartView:(OCKGroupedBarChartView *)chartView {
    NSUInteger numberOfGroups = 0;
    for (OCKBarSeries *dataSeries in _dataSeries) {
        if (dataSeries.values.count > numberOfGroups) {
            numberOfGroups = dataSeries.values.count;
        }
    }
    if (_axisTitles.count > numberOfGroups) {
        numberOfGroups = _axisTitles.count;
    }
    if (_axisSubtitles.count > numberOfGroups) {
        numberOfGroups = _axisSubtitles.count;
    }
    return numberOfGroups;
}

- (NSInteger)numberOfDataSeriesInChartView:(OCKGroupedBarChartView *)chartView {
    return _dataSeries.count;
}

- (UIColor *)chartView:(OCKGroupedBarChartView *)chartView colorForDataSeriesAtIndex:(NSUInteger)dataSeriesIndex {
    OCKBarSeries *dataSeries = _dataSeries[dataSeriesIndex];
    return dataSeries.tintColor;
}

- (NSString *)chartView:(OCKGroupedBarChartView *)chartView nameForDataSeriesAtIndex:(NSUInteger)dataSeriesIndex {
    OCKBarSeries *dataSeries = _dataSeries[dataSeriesIndex];
    return dataSeries.title;
}

- (NSNumber *)chartView:(OCKGroupedBarChartView *)chartView valueForCategoryAtIndex:(NSUInteger)categoryIndex inDataSeriesAtIndex:(NSUInteger)dataSeriesIndex {
    OCKBarSeries *dataSeries = _dataSeries[dataSeriesIndex];
    return [self isCategoryIndex:categoryIndex outofBoundsInArray:dataSeries.values] ? 0 : dataSeries.values[categoryIndex];
}

- (NSString *)chartView:(OCKGroupedBarChartView *)chartView valueStringForCategoryAtIndex:(NSUInteger)categoryIndex inDataSeriesAtIndex:(NSUInteger)dataSeriesIndex {
    OCKBarSeries *dataSeries = _dataSeries[dataSeriesIndex];
    return [self isCategoryIndex:categoryIndex outofBoundsInArray:dataSeries.valueLabels] ? nil : dataSeries.valueLabels[categoryIndex];
}

- (NSString *)chartView:(OCKGroupedBarChartView *)chartView titleForCategoryAtIndex:(NSUInteger)categoryIndex {
    return ([self isCategoryIndex:categoryIndex outofBoundsInArray:_axisTitles]) ? nil : _axisTitles[categoryIndex];
}

- (NSString *)chartView:(OCKGroupedBarChartView *)chartView subtitleForCategoryAtIndex:(NSUInteger)categoryIndex {
    return [self isCategoryIndex:categoryIndex outofBoundsInArray:_axisSubtitles] ? nil : _axisSubtitles[categoryIndex];
}

@end
