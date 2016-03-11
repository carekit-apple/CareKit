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
#import "NSDateComponents+CarePlanInternal.h"


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
    _tableViewController.navigationItem.rightBarButtonItem.tintColor = OCKRedColor();
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _tableViewController.delegate = self;
    _tableViewController.weekViewController.careCardWeekView.delegate = self;
}

- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    self.topViewController.title = self.title;
}

- (void)showToday:(id)sender {
    _tableViewController.selectedDate = [[NSDateComponents alloc] initWithDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
}


#pragma mark - OCKCareCardWeekViewDelegate

- (void)careCardWeekViewSelectionDidChange:(OCKCareCardWeekView *)careCardWeekView {
    NSDateComponents *selectedDate = [_tableViewController dateFromSelectedIndex:careCardWeekView.selectedIndex];
    NSDateComponents *today = [[NSDateComponents alloc] initWithDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
    if (![selectedDate isLaterThan:today]) {
        _tableViewController.selectedDate = selectedDate;
    }
}


#pragma mark - OCKCareCardTableViewDelegate

- (void)tableViewDidSelectRowWithTreatment:(OCKCarePlanActivity *)activity {
    OCKCareCardDetailViewController *detailViewController = [[OCKCareCardDetailViewController alloc] initWithTreatment:activity];
    [self pushViewController:detailViewController animated:YES];
}

@end
