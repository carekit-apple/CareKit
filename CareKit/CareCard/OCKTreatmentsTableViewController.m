//
//  OCKTreatmentsTableViewController.m
//  CareKit
//
//  Created by Umer Khan on 1/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKTreatmentsTableViewController.h"
#import "OCKCareCard.h"
#import "OCKCareCardView.h"
#import "OCKHelpers.h"
#import "OCKTreatment.h"
#import "OCKTreatmentTableViewCell.h"
#import "OCKWeekPageViewController.h"


static const CGFloat CellHeight = 85.0;
static const CGFloat CareCardHeight = 200.0;

@implementation OCKTreatmentsTableViewController {
    OCKCareCardView *_careCardView;
}

- (instancetype)initWithCarePlanStore:(OCKCarePlanStore *)store {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _store = store;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self prepareView];
}

- (void)prepareView {
    if (!_careCardView) {
        _careCardView = [[OCKCareCardView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 200.0)];
    }
    [self generateCareCardView];
    
    _weekPageViewController = [[OCKWeekPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                                   navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                                 options:nil];
    
    self.tableView.tableHeaderView = _weekPageViewController.view;
}

- (void)generateCareCardView {
    _careCardView.careCard = [OCKCareCard careCardWithAdherence:0.0 date:@"Friday, Jan 22, 2016"];
}

- (void)updateCareCardView {
    NSInteger totalFrequency = 0;
    NSInteger totalCompleted = 0;
//    for (id treatment in _treatments) {
//        NSInteger frequency = ((OCKTreatment *)treatment).frequency;
//        NSInteger completed = ((OCKTreatment *)treatment).completed;
//        totalFrequency += frequency;
//        totalCompleted += completed;
//    }
    
    CGFloat adherence = (CGFloat)totalCompleted/totalFrequency;
    OCKCareCard *updatedCard = _careCardView.careCard;
    updatedCard.adherence = adherence;
    _careCardView.careCard = updatedCard;
}

- (OCKCareCard *)careCard {
    return _careCardView.careCard;
}

- (NSString *)title {
    return @"CareCard";
}


#pragma mark - OCKTreatmentCellDelegate
- (void)treatmentCellDidUpdateFrequency:(OCKTreatmentTableViewCell *)cell {
    [self updateCareCardView];
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return tableView.rowHeight;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return _careCardView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CareCardHeight;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section {
    return CareCardHeight;
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    OCKTreatmentTableViewCell *cell = [OCKTreatmentTableViewCell new];
//    cell.treatment = self.treatments[indexPath.row];
//    cell.delegate = self;
    return cell;
}


@end
