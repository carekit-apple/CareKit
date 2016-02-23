//
//  OCKTreatmentsTableViewController.h
//  CareKit
//
//  Created by Umer Khan on 1/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "OCKCareCardTableViewCell.h"


NS_ASSUME_NONNULL_BEGIN

@class OCKCarePlanActivity, OCKWeekPageViewController, OCKCarePlanStore;

@protocol OCKCareCardTableViewDelegate <NSObject>

- (void)tableViewDidSelectRowWithTreatment:(OCKCarePlanActivity *)activity;

@end


@interface OCKCareCardTableViewController : UITableViewController <OCKCareCardCellDelegate>

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithCarePlanStore:(OCKCarePlanStore *)store;

@property (nonatomic, readonly) OCKCarePlanStore *store;
@property (nonatomic) id<OCKCareCardTableViewDelegate> delegate;
@property (nonatomic, readonly) OCKWeekPageViewController *weekPageViewController;

@end

NS_ASSUME_NONNULL_END
