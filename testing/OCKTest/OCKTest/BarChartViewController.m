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


#import "BarChartViewController.h"

@interface BarDataSource1 : NSObject <OCKGroupedBarChartViewDataSource>

@end

@implementation BarDataSource1

- (NSInteger)numberOfCategoriesPerDataSeriesInChartView:(OCKGroupedBarChartView *)chartView {
    return 5;
}

- (NSInteger)numberOfDataSeriesInChartView:(OCKGroupedBarChartView *)chartView {
    return 4;
}

- (UIColor *)chartView:(OCKGroupedBarChartView *)chartView colorForDataSeriesAtIndex:(NSUInteger)dataSeriesIndex {
    
    return @[
             [[UIColor redColor] colorWithAlphaComponent:0.5],
             [[UIColor orangeColor] colorWithAlphaComponent:0.5],
             [[UIColor purpleColor] colorWithAlphaComponent:0.5],
             [[UIColor brownColor] colorWithAlphaComponent:0.5]
             ][dataSeriesIndex];
}

- (NSString *)chartView:(OCKGroupedBarChartView *)chartView nameForDataSeriesAtIndex:(NSUInteger)dataSeriesIndex {
    return [NSString stringWithFormat:@"Data Series Index %@", @(dataSeriesIndex)];
}

- (NSNumber *)chartView:(OCKGroupedBarChartView *)chartView valueForCategoryAtIndex:(NSUInteger)categoryIndex inDataSeriesAtIndex:(NSUInteger)dataSeriesIndex {
    if (dataSeriesIndex == 1 && categoryIndex == 1) {
        return @(-1);
    }
    return @(dataSeriesIndex);
}

- (NSString *)chartView:(OCKGroupedBarChartView *)chartView valueStringForCategoryAtIndex:(NSUInteger)categoryIndex inDataSeriesAtIndex:(NSUInteger)dataSeriesIndex {
    if (dataSeriesIndex == 1 && categoryIndex == 1) {
        return @"-1";
    }
    return [@(dataSeriesIndex) description];
}

- (NSString *)chartView:(OCKGroupedBarChartView *)chartView titleForCategoryAtIndex:(NSUInteger)categoryIndex {
    return [NSString stringWithFormat:@"Group %@", @(categoryIndex)];
}

- (NSString *)chartView:(OCKGroupedBarChartView *)chartView subtitleForCategoryAtIndex:(NSUInteger)categoryIndex {
    return [NSString stringWithFormat:@"sub %@", @(categoryIndex)];
}

- (NSNumber *)maximumScaleRangeValueOfChartView:(OCKGroupedBarChartView *)chartView {
    return @8;
}

- (NSNumber *)minimumScaleRangeValueOfChartView:(OCKGroupedBarChartView *)chartView {
    return @(-8);
}

@end

@interface BarDataSource2 : NSObject <OCKGroupedBarChartViewDataSource>

@end

@implementation BarDataSource2

- (NSInteger)numberOfCategoriesPerDataSeriesInChartView:(OCKGroupedBarChartView *)chartView {
    return 5;
}

- (NSInteger)numberOfDataSeriesInChartView:(OCKGroupedBarChartView *)chartView {
    return 4;
}

- (UIColor *)chartView:(OCKGroupedBarChartView *)chartView colorForDataSeriesAtIndex:(NSUInteger)dataSeriesIndex {
    
    return @[
             [[UIColor redColor] colorWithAlphaComponent:0.5],
             [[UIColor orangeColor] colorWithAlphaComponent:0.5],
             [[UIColor purpleColor] colorWithAlphaComponent:0.5],
             [[UIColor brownColor] colorWithAlphaComponent:0.5]
             ][dataSeriesIndex];
}

- (NSString *)chartView:(OCKGroupedBarChartView *)chartView nameForDataSeriesAtIndex:(NSUInteger)dataSeriesIndex {
    return [NSString stringWithFormat:@"Data Series Index %@", @(dataSeriesIndex)];
}

- (NSNumber *)chartView:(OCKGroupedBarChartView *)chartView valueForCategoryAtIndex:(NSUInteger)categoryIndex inDataSeriesAtIndex:(NSUInteger)dataSeriesIndex {
    return @(dataSeriesIndex + 10000000);
}

- (NSString *)chartView:(OCKGroupedBarChartView *)chartView valueStringForCategoryAtIndex:(NSUInteger)categoryIndex inDataSeriesAtIndex:(NSUInteger)dataSeriesIndex {
    return [@(dataSeriesIndex + 10000000) description];
}

- (NSString *)chartView:(OCKGroupedBarChartView *)chartView titleForCategoryAtIndex:(NSUInteger)categoryIndex {
    return [NSString stringWithFormat:@"Group %@", @(categoryIndex)];
}

- (NSString *)chartView:(OCKGroupedBarChartView *)chartView subtitleForCategoryAtIndex:(NSUInteger)categoryIndex {
    return [NSString stringWithFormat:@"sub %@", @(categoryIndex)];
}

- (NSNumber *)maximumScaleRangeValueOfChartView:(OCKGroupedBarChartView *)chartView {
    return @(3 + 10000000);
}

- (NSNumber *)minimumScaleRangeValueOfChartView:(OCKGroupedBarChartView *)chartView {
    return @(-1 + 10000000);
}

@end


@implementation BarChartViewController {
    BarDataSource1 *_dataSource1;
    BarDataSource2 *_dataSource2;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"BarChartView";
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    OCKGroupedBarChartView *barChartView = [[OCKGroupedBarChartView alloc] init];
    _dataSource1 = [BarDataSource1 new];
    barChartView.dataSource = _dataSource1;
    barChartView.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.1];
    CGSize size = [barChartView systemLayoutSizeFittingSize:CGSizeMake(self.view.bounds.size.width - 20, 1) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
    barChartView.frame = CGRectMake(10, 80, size.width, size.height);
    [self.view addSubview:barChartView];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [barChartView animateWithDuration:1.5];
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _dataSource2 = [BarDataSource2 new];
        barChartView.dataSource = _dataSource2;
        [barChartView animateWithDuration:1.5];
    });
}

@end
