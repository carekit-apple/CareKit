//
//  CareKitPDFTests.m
//  CareKit
//
//  Created by Yuan Zhu on 2/23/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CareKit/CareKit.h>
#import "OCKChartTableViewCell.h"
#import "OCKChart_Internal.h"

@interface CareKitPDFTests : XCTestCase <ORKGraphChartViewDataSource, ORKPieChartViewDataSource> {
    ORKLineGraphChartView *_lineChartView;
}

@end

@implementation CareKitPDFTests

- (NSString *)testPath {
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docPath = [searchPaths objectAtIndex:0];
    NSString *storePath = [docPath stringByAppendingPathComponent:@"testpdf"];
    [[NSFileManager defaultManager] createDirectoryAtPath:storePath withIntermediateDirectories:YES attributes:nil error:nil];
    
    return storePath;
}

- (NSString *)cleanTestPath {
    NSString *testPath = [self testPath];
    [[NSFileManager defaultManager] removeItemAtPath:testPath error:nil];
    return [self testPath];
}

- (OCKLineChart *)createLineChart {
    OCKLinePoint *point1 = [OCKLinePoint linePointWithValue:1.0];
    OCKLinePoint *point2 = [OCKLinePoint linePointWithValue:2.0];
    OCKLinePoint *point3 = [OCKLinePoint linePointWithValue:3.0];
    OCKLinePoint *point4 = [OCKLinePoint linePointWithValue:4.0];
    OCKLinePoint *point5 = [OCKLinePoint linePointWithValue:5.0];
    OCKLine *line1 = [OCKLine lineWithLinePoints:@[point1, point2, point3, point4, point5]];
    line1.color = OCKGrayColor();
    OCKLine *line2 = [OCKLine lineWithLinePoints:@[point4, point3, point5, point1, point2]];
    line2.color = OCKYellowColor();
    OCKLineChart *lineChart = [OCKLineChart lineChartWithTitle:@"Line Chart"
                                                          text:@"Text : Lorem ipsum dolor sit amet"
                                                         lines:@[line1, line2]];
    
    lineChart.xAxisTitle = @"xAxisTitle";
    lineChart.yAxisTitle = @"yAxisTitle";
    
    lineChart.tintColor = OCKYellowColor();
    return lineChart;
}

- (OCKDiscreteChart *)createDiscreteChart {
    OCKRangePoint *range1 = [OCKRangePoint rangePointWithMinimumValue:0 maximumValue:6.0];
    OCKRangePoint *range2 = [OCKRangePoint rangePointWithMinimumValue:0 maximumValue:8.0];
    OCKRangePoint *range3 = [OCKRangePoint rangePointWithMinimumValue:0 maximumValue:7.0];
    OCKRangePoint *range4 = [OCKRangePoint rangePointWithMinimumValue:0 maximumValue:9.0];
    OCKRangePoint *range5 = [OCKRangePoint rangePointWithMinimumValue:0 maximumValue:10.0];
    OCKRangePoint *range6 = [OCKRangePoint rangePointWithMinimumValue:0 maximumValue:5.0];
    OCKRangePoint *range7 = [OCKRangePoint rangePointWithMinimumValue:0 maximumValue:4.0];
    
    OCKRangeGroup *rangeGroup1 = [OCKRangeGroup rangeGroupWithRangePoints:@[range1, range2, range3, range4, range5, range6, range7]];
    rangeGroup1.color = OCKBlueColor();
    OCKRangeGroup *rangeGroup2 = [OCKRangeGroup rangeGroupWithRangePoints:@[range1, range5, range7, range4, range3, range6, range2]];
    rangeGroup2.color = OCKGrayColor();
    
    OCKDiscreteChart *discreteChart = [OCKDiscreteChart discreteChartWithGroups:@[rangeGroup1, rangeGroup2]];
    discreteChart.title = @"Discrete Chart";
    discreteChart.text = @"Daily sales of hardware and software but I want to test multiple lines, so here's some more text.";
    discreteChart.tintColor = OCKBlueColor();
    discreteChart.xAxisTitle = @"Day";
    discreteChart.yAxisTitle = @"Sales";
    
    return discreteChart;
}

- (OCKPieChart *)createPieChart {
    OCKSegment *segment1 = [OCKSegment segmentWithValue:0.25 color:[UIColor brownColor] title:@"Brown"];
    OCKSegment *segment2 = [OCKSegment segmentWithValue:0.15 color:[UIColor purpleColor] title:@"Purple"];
    OCKSegment *segment3 = [OCKSegment segmentWithValue:0.05 color:[UIColor cyanColor] title:@"Cyan"];
    OCKSegment *segment4 = [OCKSegment segmentWithValue:0.55 color:[UIColor orangeColor] title:@"Orange"];
    OCKPieChart *pieChart = [OCKPieChart pieChartWithTitle:@"Pie Chart"
                                                      text:@"Apple employee color preference"
                                                  segments:@[segment1, segment2, segment3, segment4]];
    pieChart.showsPercentageLabels = YES;
    pieChart.usesLineSegments = YES;
    pieChart.tintColor = OCKRedColor();
    pieChart.height = 300.0;
    
    return pieChart;
}

- (void)testHTML {
    OCKDocumentElementSubtitle *subtitle = [[OCKDocumentElementSubtitle alloc] initWithSubtitle:@"First subtitle"];
    OCKDocumentElementParagrah *paragrah = [[OCKDocumentElementParagrah alloc] initWithContent:@"Lorem ipsum dolor sit amet, vim primis noster sententiae ne, et albucius apeirian accusata mea, vim at dicunt laoreet. Eu probo omnes inimicus ius, duo at veritus alienum. Nostrud facilisi id pro. Putant oporteat id eos. Admodum antiopam mel in, at per everti quaeque. Lorem ipsum dolor sit amet, vim primis noster sententiae ne, et albucius apeirian accusata mea, vim at dicunt laoreet. Eu probo omnes inimicus ius, duo at veritus alienum. Nostrud facilisi id pro. Putant oporteat id eos. Admodum antiopam mel in, at per everti quaeque. Lorem ipsum dolor sit amet, vim primis noster sententiae ne, et albucius apeirian accusata mea, vim at dicunt laoreet. Eu probo omnes inimicus ius, duo at veritus alienum. Nostrud facilisi id pro. Putant oporteat id eos. Admodum antiopam mel in, at per everti quaeque."];
    
    OCKDocumentElementChart *lineChart = [[OCKDocumentElementChart alloc] initWithChart:[self createLineChart]];
    OCKDocumentElementChart *discreteChart = [[OCKDocumentElementChart alloc] initWithChart:[self createDiscreteChart]];
    OCKDocumentElementChart *pieChart = [[OCKDocumentElementChart alloc] initWithChart:[self createPieChart]];
    
    UIView *sampleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 200)];
    sampleView.backgroundColor = [UIColor grayColor];
    sampleView.layer.borderColor = [UIColor blackColor].CGColor;
    sampleView.layer.borderWidth = 2.0;
    OCKDocumentElementUIView *viewElement = [[OCKDocumentElementUIView alloc] initWithView:sampleView];
    
    OCKDocument *doc = [[OCKDocument alloc] initWithTitle:@"This is a title" elements:@[subtitle, paragrah, lineChart, pieChart, paragrah, discreteChart, paragrah, paragrah, viewElement, paragrah]];
    doc.style = @"body {\n"
    "font-family: -apple-system, Helvetica, Arial;\n"
    "}\n";
    doc.pageHeader = @"App Name: ABC, User Name: John Appleseed";
    
    NSString *path = [[self cleanTestPath] stringByAppendingPathComponent:@"x.html"];
    
    [[doc htmlContent] writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    NSLog(@"open %@", path);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"pdf"];
    
    [doc createPDFWithCompletion:^(NSData * _Nonnull data, NSError * _Nonnull error) {
        NSString *path = [[self testPath] stringByAppendingPathComponent:@"x.pdf"];
        [data writeToFile:path atomically:YES];
        NSLog(@"open %@", path);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
}

- (void)testDiscreteChart {
    
    OCKDiscreteChart *discreteChart = [self createDiscreteChart];
    UIView *chartView = [discreteChart chartView];
    
    chartView.frame = CGRectMake(0, 0, 640, 480);
    chartView.backgroundColor = [UIColor whiteColor];
    [self imageWithView:chartView filename:@"d.png"];
}

- (void)testLineChart {
    ORKLineGraphChartView *lineChartView = [[ORKLineGraphChartView alloc] initWithFrame:CGRectMake(0, 0, 640, 480)];
    _lineChartView = lineChartView;
    
    lineChartView.dataSource = self;
    lineChartView.showsHorizontalReferenceLines = YES;
    lineChartView.showsVerticalReferenceLines = YES;
    lineChartView.backgroundColor = [UIColor whiteColor];
    
    [self imageWithView:lineChartView filename:@"l.png"];
}

- (void)testPieChart {
    ORKPieChartView *chartView = [[ORKPieChartView alloc] initWithFrame:CGRectMake(0, 0, 640, 480)];
    chartView.frame = CGRectMake(0, 0, 640, 480);
    chartView.dataSource = self;
    chartView.title = @"title";
    chartView.backgroundColor = [UIColor whiteColor];
    
    UITableViewCell *view = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, 640, 480)];
    [view.contentView addSubview:chartView];
    view.frame = CGRectMake(0, 0, 640, 480);
    
    [self imageWithView:chartView filename:@"p.png"];
}

- (void)imageWithView:(UIView *)view filename:(NSString *)filename {
    UIGraphicsBeginImageContextWithOptions(view.frame.size, YES, 2.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSData *data = UIImagePNGRepresentation(viewImage);
    NSString *path = [[self cleanTestPath] stringByAppendingPathComponent:filename];
    [data writeToFile:path atomically:YES];
    NSLog(@"open %@", path);
}

- (NSInteger)graphChartView:(ORKGraphChartView *)graphChartView numberOfPointsForPlotIndex:(NSInteger)plotIndex {
    return 5;
}

- (ORKRangedPoint *)graphChartView:(ORKGraphChartView *)graphChartView pointForPointIndex:(NSInteger)pointIndex plotIndex:(NSInteger)plotIndex {
    return [[ORKRangedPoint alloc] initWithValue:pointIndex];
}

- (NSInteger)numberOfSegmentsInPieChartView:(ORKPieChartView *)pieChartView {
    return 3;
}

- (CGFloat)pieChartView:(ORKPieChartView *)pieChartView valueForSegmentAtIndex:(NSInteger)index {
    return index + 1.0;
}

- (UIColor *)pieChartView:(ORKPieChartView *)pieChartView colorForSegmentAtIndex:(NSInteger)index {
    return @[[UIColor redColor], [UIColor orangeColor], [UIColor brownColor]][index];
}


- (NSString *)pieChartView:(ORKPieChartView *)pieChartView titleForSegmentAtIndex:(NSInteger)index {
    return @(index).description;
}


@end
