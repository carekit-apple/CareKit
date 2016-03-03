//
//  OCKDiscreteChart.m
//  CareKit
//
//  Created by Umer Khan on 1/20/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKDiscreteChart.h"
#import "OCKDiscreteChart_Internal.h"
#import "OCKRangeGroup.h"
#import "OCKHelpers.h"
#import <ResearchKit/ORKGraphChartView.h>
#import <ResearchKit/ORKRangedPoint.h>


@implementation OCKDiscreteChart
@synthesize xAxisTitle, yAxisTitle;

+ (instancetype)new {
    OCKThrowMethodUnavailableException();
    return nil;
}

+ (instancetype)discreteChartWithTitle:(NSString *)title
                                  text:(NSString *)text
                                groups:(NSArray<OCKRangeGroup *> *)groups {
    return [[OCKDiscreteChart alloc] initWithTitle:title
                                              text:text
                                            groups:groups];
}

+ (instancetype)discreteChartWithGroups:(NSArray<OCKRangeGroup *> *)groups {
    return [[OCKDiscreteChart alloc] initWithGroups:groups];
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithTitle:(NSString *)title
                         text:(NSString *)text
                       groups:(NSArray<OCKRangeGroup *> *)groups {
    self = [super init];
    if (self) {
        self.title = [title copy];
        self.text = [text copy];
        _groups = [groups copy];
        _drawsConnectedRanges = YES;
    }
    return self;
}

- (instancetype)initWithGroups:(NSArray<OCKRangeGroup *> *)groups {
    return [self initWithTitle:nil
                          text:nil
                        groups:groups];
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            OCKEqualObjects(self.groups, castObject.groups) &&
            (self.drawsConnectedRanges == castObject.drawsConnectedRanges));
}


#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        OCK_DECODE_OBJ_ARRAY(aDecoder, groups, NSArray);
        OCK_DECODE_BOOL(aDecoder, drawsConnectedRanges);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    OCK_ENCODE_OBJ(aCoder, groups);
    OCK_ENCODE_BOOL(aCoder, drawsConnectedRanges);
}


#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKDiscreteChart *chart = [super copyWithZone:zone];
    chart->_groups = [self.groups copy];
    chart->_drawsConnectedRanges = self.drawsConnectedRanges;
    chart->xAxisTitle = [self.xAxisTitle copy];
    chart->yAxisTitle = [self.yAxisTitle copy];
    return chart;
}


#pragma mark - ORKGraphChartViewDataSource

- (NSInteger)graphChartView:(ORKGraphChartView *)graphChartView numberOfPointsForPlotIndex:(NSInteger)plotIndex {
    OCKRangeGroup *rangeGroup = _groups[plotIndex];
    NSArray <OCKRangePoint *> *rangePoints = rangeGroup.points;
    return rangePoints.count;
}

- (ORKRangedPoint *)graphChartView:(ORKGraphChartView *)graphChartView pointForPointIndex:(NSInteger)pointIndex plotIndex:(NSInteger)plotIndex {
    OCKRangeGroup *rangeGroup = _groups[plotIndex];
    NSArray <OCKRangePoint *> *rangePoints = rangeGroup.points;
    OCKRangePoint *rangePoint = rangePoints[pointIndex];
    return [[ORKRangedPoint alloc] initWithMinimumValue:rangePoint.minimumValue
                                           maximumValue:rangePoint.maximumValue];
}

- (NSInteger)numberOfPlotsInGraphChartView:(ORKGraphChartView *)graphChartView {
    return _groups.count;
}

- (UIColor *)graphChartView:(ORKGraphChartView *)graphChartView colorForPlotIndex:(NSInteger)plotIndex {
    OCKRangeGroup *rangeGroup = _groups[plotIndex];
    return rangeGroup.color;
}


#pragma mark - Internal

- (UIView *)chartView {
    OCKDiscreteChart *discreteChart = self;
    ORKDiscreteGraphChartView *chartView = [ORKDiscreteGraphChartView new];
    chartView.dataSource = discreteChart;
    chartView.drawsConnectedRanges = discreteChart.drawsConnectedRanges;
    chartView.scrubberThumbColor = chartView.tintColor;
    chartView.scrubberLineColor = chartView.tintColor;
    return chartView;
}

@end
