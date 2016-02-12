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


static NSString *const _OCKChartsRestoreKey = @"charts";
static NSString *const _OCKHeaderTitleRestoreKey = @"headerTitle";
static NSString *const _OCKHeaderTextRestoreKey = @"headerText";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:_charts forKey:_OCKChartsRestoreKey];
    [coder encodeObject:_headerTitle forKey:_OCKHeaderTitleRestoreKey];
    [coder encodeObject:_headerText forKey:_OCKHeaderTextRestoreKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    self.charts = [coder decodeObjectOfClass:[NSArray class] forKey:_OCKChartsRestoreKey];
    self.headerTitle = [coder decodeObjectOfClass:[NSString class] forKey:_OCKHeaderTitleRestoreKey];
    self.headerText = [coder decodeObjectOfClass:[NSString class] forKey:_OCKHeaderTextRestoreKey];
}

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    OCKDashboardViewController *viewController = [[[self class] alloc] init];
    viewController.restorationIdentifier = identifierComponents.lastObject;
    viewController.restorationClass = self;
    return viewController;
}

@end
