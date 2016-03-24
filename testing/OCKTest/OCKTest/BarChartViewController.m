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


@implementation BarChartViewController 

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"BarChartView";
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    OCKGroupedBarChartView *barChartView = [[OCKGroupedBarChartView alloc] initWithFrame:CGRectMake(10, 60, self.view.bounds.size.width - 20, 400)];
    barChartView.dataSource = self;
    [self.view addSubview:barChartView];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [barChartView animateWithDuration:2.0];
    });
    
}

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
    return [NSString stringWithFormat:@"Bar %@", @(dataSeriesIndex)];
}

- (NSNumber *)chartView:(OCKGroupedBarChartView *)chartView valueForCategoryAtIndex:(NSUInteger)categoryIndex inDataSeriesAtIndex:(NSUInteger)dataSeriesIndex {
    return @(dataSeriesIndex + 1);
}

- (NSString *)chartView:(OCKGroupedBarChartView *)chartView valueStringForCategoryAtIndex:(NSUInteger)categoryIndex inDataSeriesAtIndex:(NSUInteger)dataSeriesIndex {
    return [@(dataSeriesIndex + 1) description];
}

- (NSString *)chartView:(OCKGroupedBarChartView *)chartView titleForCategoryAtIndex:(NSUInteger)categoryIndex {
    return [NSString stringWithFormat:@"Group %@", @(categoryIndex)];
}

- (NSString *)chartView:(OCKGroupedBarChartView *)chartView subtitleForCategoryAtIndex:(NSUInteger)categoryIndex {
    return [NSString stringWithFormat:@"sub %@", @(categoryIndex)];
}

@end
