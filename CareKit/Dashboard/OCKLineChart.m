//
//  OCKLineChart.m
//  CareKit
//
//  Created by Umer Khan on 1/20/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKLineChart.h"
#import "OCKLineChart_Internal.h"
#import "OCKLine.h"
#import "OCKChart_Internal.h"
#import "OCKHelpers.h"
#import <ResearchKit/ORKLineGraphChartView.h>
#import <ResearchKit/ORKRangedPoint.h>


@implementation OCKLineChart
@synthesize xAxisTitle, yAxisTitle;

+ (instancetype)new {
    OCKThrowMethodUnavailableException();
    return nil;
}

+ (instancetype)lineChartWithTitle:(NSString *)title
                              text:(NSString *)text
                             lines:(NSArray<OCKLine *> *)lines {
    return [[OCKLineChart alloc] initWithTitle:title
                                          text:text
                                         lines:lines];
}

+ (instancetype)lineChartWithLines:(NSArray<OCKLine *> *)lines {
    return [[OCKLineChart alloc] initWithLines:lines];
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithTitle:(NSString *)title
                         text:(NSString *)text
                        lines:(NSArray<OCKLine *> *)lines {
    self = [super init];
    if (self) {
        self.title = [title copy];
        self.text = [text copy];
        _lines = [lines copy];
    }
    return self;
}

- (instancetype)initWithLines:(NSArray<OCKLine *> *)lines {
    return [self initWithTitle:nil
                          text:nil
                         lines:lines];
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            OCKEqualObjects(self.lines, castObject.lines) &&
            OCKEqualObjects(self.xAxisTitle, castObject.xAxisTitle) &&
            OCKEqualObjects(self.yAxisTitle, castObject.yAxisTitle));
}


#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        OCK_DECODE_OBJ_ARRAY(aDecoder, lines, NSArray);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    OCK_ENCODE_OBJ(aCoder, lines);
}


#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKLineChart *chart = [super copyWithZone:zone];
    chart->_lines = [self.lines copy];
    chart->xAxisTitle = [self.xAxisTitle copy];
    chart->yAxisTitle = [self.yAxisTitle copy];
    return chart;
}


#pragma mark - ORKGraphChartViewDataSource

- (NSInteger)graphChartView:(ORKGraphChartView *)graphChartView numberOfPointsForPlotIndex:(NSInteger)plotIndex {
    OCKLine *line = _lines[plotIndex];
    NSArray <OCKLinePoint *> *linePoints = line.points;
    return linePoints.count;
}

- (ORKRangedPoint *)graphChartView:(ORKGraphChartView *)graphChartView pointForPointIndex:(NSInteger)pointIndex plotIndex:(NSInteger)plotIndex {
    OCKLine *line = _lines[plotIndex];
    NSArray <OCKLinePoint *> *linePoints = line.points;
    OCKLinePoint *linePoint = linePoints[pointIndex];
    return [[ORKRangedPoint alloc] initWithValue:linePoint.value];
}

- (NSInteger)numberOfPlotsInGraphChartView:(ORKGraphChartView *)graphChartView {
    return _lines.count;
}

- (UIColor *)graphChartView:(ORKGraphChartView *)graphChartView colorForPlotIndex:(NSInteger)plotIndex {
    OCKLine *line = _lines[plotIndex];
    return line.color;
}


#pragma mark - Internal

- (UIView *)chartView {
    OCKLineChart *lineChart = self;
    ORKLineGraphChartView *chartView = [ORKLineGraphChartView new];
    chartView.dataSource = lineChart;
    chartView.showsHorizontalReferenceLines = YES;
    chartView.showsVerticalReferenceLines = YES;
    chartView.scrubberThumbColor = chartView.tintColor;
    chartView.scrubberLineColor = chartView.tintColor;
    return chartView;
}

@end
