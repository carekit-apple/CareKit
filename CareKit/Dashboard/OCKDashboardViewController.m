//
//  OCKDashboardViewController.m
//  CareKit
//
//  Created by Umer Khan on 1/20/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKDashboardViewController.h"
#import "OCKChart.h"
#import "OCKChartTableViewController.h"
#import "OCKHelpers.h"


@implementation OCKDashboardViewController {
    OCKChartTableViewController *_tableViewController;
}

+ (instancetype)new {
    OCKThrowMethodUnavailableException();
    return nil;
}

+ (instancetype)dashboardWithCharts:(NSArray<OCKChart *> *)charts {
    return [[OCKDashboardViewController alloc] initWithCharts:charts];
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithCharts:(NSArray<OCKChart *> *)charts {
    _tableViewController = [[OCKChartTableViewController alloc] initWithCharts:[charts copy]];

    self = [super initWithRootViewController:_tableViewController];
    if (self) {
        _charts = [charts copy];
    }
    return self;
}

- (void)setCharts:(NSArray<OCKChart *> *)charts {
    _charts = [charts copy];
    _tableViewController.charts = _charts;
}

- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    self.topViewController.title = self.title;
}

- (void)setHeaderTitle:(NSString *)headerTitle {
    _tableViewController.headerTitle = headerTitle;
}

- (void)setHeaderText:(NSString *)headerText {
    _tableViewController.headerText = headerText;
}

@end
