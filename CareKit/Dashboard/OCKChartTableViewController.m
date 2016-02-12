//
//  OCKChartTableViewController.m
//  CareKit
//
//  Created by Umer Khan on 1/21/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKChartTableViewController.h"
#import "OCKChartTableViewController_Internal.h"
#import "OCKChart.h"
#import "OCKChart_Internal.h"
#import "OCKChartTableViewCell.h"
#import "OCKChartTableViewHeaderView.h"
#import "OCKHelpers.h"


@implementation OCKChartTableViewController {
    NSArray<OCKChartTableViewCell *> *_chartTableViewCells;
    OCKChartTableViewHeaderView *_headerView;
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
        
        self.title = @"Dashboard";
        _charts = [charts copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _chartTableViewCells = nil;
    self.tableView.tableHeaderView = nil;
    
    if (self.isViewLoaded) {
        
        if (_headerTitle || _headerText) {
            if (!_headerView) {
                _headerView = [[OCKChartTableViewHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 75.0)];
            }
            _headerView.title = _headerTitle;
            _headerView.text = _headerText;
            self.tableView.tableHeaderView = _headerView;
        }

        self.tableView.sectionHeaderHeight = 5.0;
        self.tableView.sectionFooterHeight = 0.0;
        
        NSMutableArray <UITableViewCell *> *cells = [NSMutableArray new];
        for (id chart in self.charts) {
            static NSString *CellIdentifier = @"ChartCell";
            OCKChartTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[OCKChartTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                    reuseIdentifier:CellIdentifier];
            }
            cell.chart = chart;
            [cells addObject:cell];
        }
        _chartTableViewCells = [cells copy];
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
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return tableView.rowHeight;
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
    return _chartTableViewCells[indexPath.section];
}


#pragma mark - UIViewControllerRestoration

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
    OCKChartTableViewController *viewController = [[[self class] alloc] init];
    viewController.restorationIdentifier = identifierComponents.lastObject;
    viewController.restorationClass = self;
    return viewController;
}


@end
