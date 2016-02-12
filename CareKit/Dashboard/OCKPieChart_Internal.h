//
//  OCKPieChart_Internal.h
//  CareKit
//
//  Created by Umer Khan on 1/21/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKPieChart.h"
#import <ResearchKit/ORKPieChartView.h>


NS_ASSUME_NONNULL_BEGIN

@class ORKPieChartView;

@interface OCKPieChart() <ORKPieChartViewDataSource>

+ (ORKPieChartView *)pieChartView:(OCKChart *)chart;

@end

NS_ASSUME_NONNULL_END
