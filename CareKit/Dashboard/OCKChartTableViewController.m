//
//  OCKChartTableViewController.m
//  CareKit
//
//  Created by Umer Khan on 1/21/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKChartTableViewController.h"
#import "OCKChart.h"
#import "OCKChart_Internal.h"
#import "OCKChartTableViewCell.h"
#import "OCKChartTableViewHeaderView.h"
#import "OCKHelpers.h"


@implementation OCKChartTableViewController {
    OCKChartTableViewHeaderView *_headerView;
    BOOL _hasAnimated;
}

+ (instancetype)new {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithCharts:(NSArray<OCKChart *> *)charts {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        
        NSAssert([self isChartArrayValid:charts], @"The chart array can only include objects that are a subclass of OCKChart.");
        
        self.title = @"Insights";
        _charts = [charts copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.tableHeaderView = nil;
    
    if (_headerTitle || _headerText) {
        if (!_headerView) {
            _headerView = [[OCKChartTableViewHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 75.0)];
        }
        _headerView.title = _headerTitle;
        _headerView.text = _headerText;
        self.tableView.tableHeaderView = _headerView;
    }

    _hasAnimated = NO;
    
    self.tableView.sectionHeaderHeight = 5.0;
    self.tableView.sectionFooterHeight = 0.0;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!_hasAnimated) {
        NSArray *visibleCells = self.tableView.visibleCells;
        for (OCKChartTableViewCell *cell in visibleCells) {
            [cell animateWithDuration:1.0];
        }
        _hasAnimated = YES;
    }
}

- (void)setCharts:(NSArray<OCKChart *> *)charts {
    _charts = charts;
    [self.tableView reloadData];
}

- (void)setHeaderTitle:(NSString *)headerTitle {
    _headerTitle = headerTitle;
    _headerView.title = _headerTitle;
    [self.tableView reloadData];
}

- (void)setHeaderText:(NSString *)headerText {
    _headerText = headerText;
    _headerView.text = _headerText;
    [self.tableView reloadData];
}


#pragma mark - Helpers

- (BOOL)isChartArrayValid:(NSArray<OCKChart *> *)charts {
    BOOL isValid = YES;
    for (id chart in charts) {
        if (!OCKIsChartValid((OCKChart *)chart)) {
            isValid = NO;
            break;
        }
    }
    return isValid;
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.charts[indexPath.section].height + 80.0;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.charts.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ChartCell";
    OCKChartTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[OCKChartTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                            reuseIdentifier:CellIdentifier];
    }
    cell.chart = self.charts[indexPath.section];

    return cell;
}

@end
