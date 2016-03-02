//
//  OCKEvaluationTableViewController.h
//  CareKit
//
//  Created by Umer Khan on 2/2/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKCarePlanStore.h"


NS_ASSUME_NONNULL_BEGIN

@class OCKCarePlanStore, OCKCarePlanEvent, OCKWeekViewController, OCKCarePlanDay;
@protocol OCKEvaluationTableViewDelegate;

@interface OCKEvaluationTableViewController : UITableViewController <UIPageViewControllerDataSource, OCKCarePlanStoreDelegate>

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithCarePlanStore:(OCKCarePlanStore *)store
                             delegate:(id<OCKEvaluationTableViewDelegate>)delegate;

@property (nonatomic, readonly) OCKCarePlanStore *store;
@property (nonatomic) id<OCKEvaluationTableViewDelegate> delegate;
@property (nonatomic, readonly) OCKWeekViewController *weekPageViewController;
@property (nonatomic, readonly) OCKCarePlanEvent *lastSelectedEvaluationEvent;
@property (nonatomic) OCKCarePlanDay *selectedDate;

- (OCKCarePlanDay *)dateFromSelectedIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
