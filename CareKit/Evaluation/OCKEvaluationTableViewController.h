//
//  OCKEvaluationTableViewController.h
//  CareKit
//
//  Created by Umer Khan on 2/2/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKCarePlanStore.h"


NS_ASSUME_NONNULL_BEGIN

@class OCKCarePlanStore, OCKCarePlanEvent, OCKWeekPageViewController;
@protocol OCKEvaluationTableViewDelegate;

@interface OCKEvaluationTableViewController : UITableViewController <UIPageViewControllerDataSource, OCKCarePlanStoreDelegate>

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithCarePlanStore:(OCKCarePlanStore *)store
                             delegate:(id<OCKEvaluationTableViewDelegate>)delegate;

@property (nonatomic, readonly) OCKCarePlanStore *store;
@property (nonatomic) id<OCKEvaluationTableViewDelegate> delegate;
@property (nonatomic, readonly) OCKWeekPageViewController *weekPageViewController;
@property (nonatomic, readonly) OCKCarePlanEvent *lastSelectedEvaluationEvent;
@property (nonatomic) NSDate *selectedDate;

- (NSDate *)dateFromSelectedDay:(NSInteger)day;

@end

NS_ASSUME_NONNULL_END
