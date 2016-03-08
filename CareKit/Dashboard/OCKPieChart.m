//
//  OCKPieChart.m
//  CareKit
//
//  Created by Umer Khan on 1/20/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKPieChart.h"
#import "OCKPieChart_Internal.h"
#import "OCKSegment.h"
#import "OCKHelpers.h"
#import <ResearchKit/ORKPieChartView.h>


@implementation OCKPieChart

+ (instancetype)new {
    OCKThrowMethodUnavailableException();
    return nil;
}

+ (instancetype)pieChartWithTitle:(NSString *)title
                             text:(NSString *)text
                         segments:(NSArray<OCKSegment *> *)segments {
    return [[OCKPieChart alloc] initWithTitle:title
                                         text:text
                                     segments:segments];
}

+ (instancetype)pieChartWithSegments:(NSArray<OCKSegment *> *)segments {
    return [[OCKPieChart alloc] initWithSegments:segments];
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithTitle:(NSString *)title
                         text:(NSString *)text
                     segments:(NSArray<OCKSegment *> *)segments {
    self = [super init];
    if (self) {
        self.title = [title copy];
        self.text = [text copy];
        _segments = [segments copy];
        _showsPercentageLabels = YES;
    }
    return self;
}

- (instancetype)initWithSegments:(NSArray<OCKSegment *> *)segments {
    return [self initWithTitle:nil
                          text:nil
                      segments:segments];
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            OCKEqualObjects(self.segments, castObject.segments) &&
            (self.showsPercentageLabels == castObject.showsPercentageLabels) &&
            (self.usesLineSegments == castObject.usesLineSegments));
}


#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        OCK_DECODE_OBJ_ARRAY(aDecoder, segments, NSArray);
        OCK_DECODE_BOOL(aDecoder, showsPercentageLabels);
        OCK_DECODE_BOOL(aDecoder, usesLineSegments);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    OCK_ENCODE_OBJ(aCoder, segments);
    OCK_ENCODE_BOOL(aCoder, showsPercentageLabels);
    OCK_ENCODE_BOOL(aCoder, usesLineSegments);
}


#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKPieChart *chart = [super copyWithZone:zone];
    chart->_segments = [self.segments copy];
    chart->_showsPercentageLabels = self.showsPercentageLabels;
    chart->_usesLineSegments = self.usesLineSegments;
    return chart;
}


#pragma mark - ORKPieChartViewDataSource

- (NSInteger)numberOfSegmentsInPieChartView:(ORKPieChartView *)pieChartView {
    return _segments.count;
}

- (CGFloat)pieChartView:(ORKPieChartView *)pieChartView valueForSegmentAtIndex:(NSInteger)index {
    OCKSegment *segment = _segments[index];
    return segment.value;
}

- (UIColor *)pieChartView:(ORKPieChartView *)pieChartView colorForSegmentAtIndex:(NSInteger)index {
    OCKSegment *segment = _segments[index];
    return segment.color;
}

- (NSString *)pieChartView:(ORKPieChartView *)pieChartView titleForSegmentAtIndex:(NSInteger)index {
    OCKSegment *segment = _segments[index];
    return segment.title;
}


#pragma mark - Internal

- (UIView *)chartView {
    OCKPieChart *pieChart = self;
    ORKPieChartView *chartView = [ORKPieChartView new];
    chartView.dataSource = pieChart;
    chartView.showsPercentageLabels = pieChart.showsPercentageLabels;
    if (!pieChart.usesLineSegments) {
        chartView.lineWidth = NSIntegerMax;
    }
    return chartView;
}

@end
