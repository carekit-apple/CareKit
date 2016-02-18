//
//  OCKCareCardTableViewController_Internal.h
//  CareKit
//
//  Created by Umer Khan on 2/18/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKCareCardTableViewController.h"
#import "OCKCarePlanStore.h"


@interface OCKCareCardTableViewController() <OCKCarePlanStoreDelegate, UIPageViewControllerDataSource, OCKCareCardCellDelegate>

@property (nonatomic) NSDate *selectedDate;

- (NSDate *)dateFromSelectedDay:(NSInteger)day;

@end
