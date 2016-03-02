//
//  OCKTreatmentsViewController.m
//  CareKit
//
//  Created by Umer Khan on 1/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKCareCardViewController.h"
#import "OCKCareCardViewController_Internal.h"
#import "OCKCarePlanStore.h"
#import "OCKCarePlanEvent.h"
#import "OCKWeekView.h"
#import "OCKWeekViewController.h"
#import "OCKCareCardWeekView.h"
#import "OCKCareCardDetailViewController.h"


@implementation OCKCareCardViewController {
    OCKCareCardTableViewController *_tableViewController;
}

+ (instancetype)careCardViewControllerWithCarePlanStore:(OCKCarePlanStore *)store {
    return [[OCKCareCardViewController alloc] initWithCarePlanStore:store];
}

- (instancetype)initWithCarePlanStore:(OCKCarePlanStore *)store {
    _tableViewController = [[OCKCareCardTableViewController alloc] initWithCarePlanStore:store];
    
    self = [super initWithRootViewController:_tableViewController];
    if (self) {
        _store = store;
    }
    return self;
}

- (void)viewDidLoad {
    _tableViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Today"
                                                                                              style:UIBarButtonItemStylePlain
                                                                                             target:self
                                                                                             action:@selector(showToday:)];
    _tableViewController.navigationItem.rightBarButtonItem.tintColor = OCKPinkColor();
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _tableViewController.delegate = self;
    _tableViewController.weekViewController.careCardWeekView.delegate = self;
    self.navigationBar.tintColor = self.view.tintColor;
}

- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    self.topViewController.title = self.title;
}

- (void)showToday:(id)sender {
    _tableViewController.selectedDate = [[OCKCarePlanDay alloc] initWithDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
}

#pragma mark - OCKCareCardWeekViewDelegate

- (void)careCardWeekViewSelectionDidChange:(OCKCareCardWeekView *)careCardWeekView {
    OCKCarePlanDay *selectedDate = [_tableViewController dateFromSelectedIndex:careCardWeekView.selectedIndex];
    OCKCarePlanDay *today = [[OCKCarePlanDay alloc] initWithDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
    if (![selectedDate isLaterThan:today]) {
        _tableViewController.selectedDate = selectedDate;
    }
}


#pragma mark - OCKCareCardTableViewDelegate

- (void)tableViewDidSelectRowWithTreatment:(OCKCarePlanActivity *)activity {
    OCKCareCardDetailViewController *detailViewController = [OCKCareCardDetailViewController new];
    detailViewController.treatment = activity;
    [self pushViewController:detailViewController animated:YES];
}

@end
