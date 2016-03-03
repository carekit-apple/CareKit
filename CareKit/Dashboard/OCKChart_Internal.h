//
//  OCKChart_Internal.h
//  CareKit
//
//  Created by Umer Khan on 1/22/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKChart.h"


NS_ASSUME_NONNULL_BEGIN

@interface OCKChart()

BOOL OCKIsChartValid(OCKChart * chart);

- (UIView *)chartView;

@end

NS_ASSUME_NONNULL_END
