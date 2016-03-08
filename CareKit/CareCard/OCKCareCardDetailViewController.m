//
//  OCKCareCardDetailViewController.m
//  CareKit
//
//  Created by Umer Khan on 2/18/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKCareCardDetailViewController.h"
#import "OCKCarePlanActivity.h"
#import "OCKCareCardDetailHeaderView.h"


static const CGFloat HeaderViewHeight = 150.0;

@implementation OCKCareCardDetailViewController {
    OCKCareCardDetailHeaderView *_headerView;
    UIView *_leadingEdge;
    NSMutableArray *_constraints;
}

- (instancetype)initWithTreatment:(OCKCarePlanActivity *)treatment {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _treatment = treatment;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self prepareView];
    self.tableView.tableFooterView = [UIView new];
}

- (void)setTreatment:(OCKCarePlanActivity *)treatment {
    _treatment = treatment;
    [self prepareView];
}

- (void)prepareView {
    if (!_headerView) {
        _headerView = [[OCKCareCardDetailHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, HeaderViewHeight)];
    }
    _headerView.treatment = _treatment;
    
    self.tableView.tableHeaderView = _headerView;
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger numberOfSections = 0;
    if (_treatment.detailText) {
        numberOfSections += 1;
    }
    // TO DO: Implement this for image content.
    // And if statemnet to add to the number of sections.
    numberOfSections += 1;
    return numberOfSections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title;
    switch (section) {
        case 0:
            title = @"Detailed Instructions";
            break;
            
        case 1:
            title = @"Additional Information";
            break;
    }
    return title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                   reuseIdentifier:nil];
    
    switch (indexPath.section) {
        case 0:
            cell.textLabel.text = _treatment.detailText;
            cell.textLabel.numberOfLines = 0;
            cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
            break;
        case 1:
            break;
    }
    
    return cell;
}

@end
