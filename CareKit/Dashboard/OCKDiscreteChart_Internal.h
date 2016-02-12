//
//  OCKDiscreteChart_Internal.h
//  CareKit
//
//  Created by Umer Khan on 1/21/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKDiscreteChart.h"
#import <ResearchKit/ORKDiscreteGraphChartView.h>


NS_ASSUME_NONNULL_BEGIN

@interface OCKDiscreteChart() <ORKGraphChartViewDataSource>

+ (ORKDiscreteGraphChartView *)discreteChartView:(OCKChart *)chart;

@end

NS_ASSUME_NONNULL_END
