//
//  OCKBarChart.m
//  CareKit
//
//  Created by Umer Khan on 3/2/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKBarChart.h"
#import "OCKBarChart_Internal.h"
#import "OCKBarGroup.h"
#import "OCKChart_Internal.h"
#import "OCKHelpers.h"


BOOL OCKIsBarGroupArrayValid(NSArray<OCKBarGroup *> *groups) {
    BOOL isValid = YES;
    NSInteger count = groups.firstObject.values.count;
    for (OCKBarGroup *group in groups) {
        if (group.values.count != count) {
            isValid = NO;
            break;
        }
    }
    return isValid;
}

BOOL OCKIsAxisValid(NSArray<NSString *> *axisTitles, NSArray<NSString *> *axisSubtitles, NSArray <OCKBarGroup *> *groups) {
    BOOL isValid = YES;
    if (axisTitles) {
        isValid = (axisTitles.count == groups.firstObject.values.count);
    }
    if (axisSubtitles && isValid) {
        isValid = (axisSubtitles.count == groups.firstObject.values.count);
    }
    return isValid;
}

@implementation OCKBarChart

+ (instancetype)new {
    OCKThrowMethodUnavailableException();
    return nil;
}

+ (instancetype)barChartWithTitle:(NSString *)title
                             text:(NSString *)text
                       axisTitles:(NSArray<NSString *> *)axisTitles
                    axisSubtitles:(NSArray<NSString *> *)axisSubtitles
                           groups:(NSArray<OCKBarGroup *> *)groups {
    return [[OCKBarChart alloc] initWithWithTitle:title
                                             text:text
                                       axisTitles:axisTitles
                                    axisSubtitles:axisSubtitles
                                           groups:groups];
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithWithTitle:(NSString *)title
                             text:(NSString *)text
                       axisTitles:(NSArray<NSString *> *)axisTitles
                    axisSubtitles:(NSArray<NSString *> *)axisSubtitles
                           groups:(NSArray<OCKBarGroup *> *)groups {

    NSAssert(OCKIsBarGroupArrayValid(groups), @"All bar groups must have the same number of values.");
    NSAssert(OCKIsAxisValid(axisTitles, axisSubtitles, groups), @"The number of axis title strings and chart values must be the same. The number of axis subtitle strings and chart values must also be the same.");
    
    self = [super init];
    if (self) {
        self.title = [title copy];
        self.text = [text copy];
        _axisTitles = [axisTitles copy];
        _axisSubtitles = [axisSubtitles copy];
        _groups = [groups copy];
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            OCKEqualObjects(self.axisTitles, castObject.axisTitles) &&
            OCKEqualObjects(self.axisSubtitles, castObject.axisSubtitles) &&
            OCKEqualObjects(self.groups, castObject.groups));
}

- (CGFloat)height {
    return 250;
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
        OCK_DECODE_OBJ_ARRAY(aDecoder, groups, NSArray);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    OCK_ENCODE_OBJ(aCoder, axisTitles);
    OCK_ENCODE_OBJ(aCoder, axisSubtitles);
    OCK_ENCODE_OBJ(aCoder, groups);
}


#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKBarChart *chart = [super copyWithZone:zone];
    chart->_axisTitles = [_axisTitles copy];
    chart->_axisSubtitles = [_axisSubtitles copy];
    chart->_groups = [_groups copy];
    return chart;
}


#pragma mark - OCKGroupedBarChartDataSource

- (NSInteger)numberOfCategoriesPerDataSeriesInChartView:(OCKGroupedBarChartView *)chartView {
    NSUInteger numberOfGroups = 0;
    for (OCKBarGroup *barGroup in self.groups) {
        NSUInteger numberInBarGroup = barGroup.values.count;
        if (numberInBarGroup > numberOfGroups) {
            numberOfGroups = numberInBarGroup;
        }
    }
    return numberOfGroups;
}

- (NSInteger)numberOfDataSeriesInChartView:(OCKGroupedBarChartView *)chartView {
    return self.groups.count;
}

- (UIColor *)chartView:(OCKGroupedBarChartView *)chartView colorForDataSeries:(NSUInteger)dataSeriesIndex {
    OCKBarGroup *barGroup = self.groups[dataSeriesIndex];
    return barGroup.tintColor;
}

- (NSString *)chartView:(OCKGroupedBarChartView *)chartView nameForDataSeries:(NSUInteger)dataSeriesIndex {
    OCKBarGroup *barGroup = self.groups[dataSeriesIndex];
    return barGroup.title;
}

- (NSNumber *)chartView:(OCKGroupedBarChartView *)chartView valueForCategory:(NSUInteger)categoryIndex inDataSeries:(NSUInteger)dataSeriesIndex {
    OCKBarGroup *barGroup = self.groups[dataSeriesIndex];
    return barGroup.values[categoryIndex];
}

- (NSString *)chartView:(OCKGroupedBarChartView *)chartView valueStringForCategory:(NSUInteger)categoryIndex inDataSeries:(NSUInteger)dataSeriesIndex {
    OCKBarGroup *barGroup = self.groups[dataSeriesIndex];
    return barGroup.valueLabels[categoryIndex];
}

- (NSString *)chartView:(OCKGroupedBarChartView *)chartView titleForCategory:(NSUInteger)categoryIndex {
    return self.axisTitles[categoryIndex];
}

- (NSString *)chartView:(OCKGroupedBarChartView *)chartView subtitleForCategory:(NSUInteger)categoryIndex {
    return self.axisSubtitles[categoryIndex];
}


#pragma mark - OCKChart

- (UIView *)chartView {
    OCKGroupedBarChartView *barChartView = [OCKGroupedBarChartView new];
    barChartView.dataSource = self;
    return barChartView;
}

+ (void)animateView:(UIView *)view withDuration:(NSTimeInterval)duration {
    OCKGroupedBarChartView *chartView = (OCKGroupedBarChartView *)view;
    [chartView animateWithDuration:duration];
}

@end

