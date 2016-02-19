//
//  OCKEvaluationTableViewController_Internal.h
//  CareKit
//
//  Created by Umer Khan on 2/17/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKEvaluationTableViewController.h"
#import "OCKCarePlanStore.h"


@interface OCKEvaluationTableViewController() <OCKCarePlanStoreDelegate, UIPageViewControllerDataSource>

@property (nonatomic) NSDate *selectedDate;

- (NSDate *)dateFromSelectedDay:(NSInteger)day;

@end
