//
//  OCKTreatmentsTableViewController.h
//  CareKit
//
//  Created by Umer Khan on 1/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKCarePlanStore.h"
#import "OCKCareCardTableViewCell.h"


NS_ASSUME_NONNULL_BEGIN

@class OCKCarePlanActivity, OCKWeekViewController, OCKCarePlanStore, NSDateComponents;

@protocol OCKCareCardTableViewDelegate <NSObject>

- (void)tableViewDidSelectRowWithTreatment:(OCKCarePlanActivity *)activity;

@end


@interface OCKCareCardTableViewController : UITableViewController <OCKCarePlanStoreDelegate, UIPageViewControllerDelegate, UIPageViewControllerDataSource, OCKCareCardCellDelegate>

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithCarePlanStore:(OCKCarePlanStore *)store;

@property (nonatomic, readonly) OCKCarePlanStore *store;
@property (nonatomic) id<OCKCareCardTableViewDelegate> delegate;
@property (nonatomic, readonly) OCKWeekViewController *weekViewController;
@property (nonatomic) NSDateComponents *selectedDate;

- (NSDateComponents *)dateFromSelectedIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
