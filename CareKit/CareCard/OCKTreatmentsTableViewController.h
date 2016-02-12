//
//  OCKTreatmentsTableViewController.h
//  CareKit
//
//  Created by Umer Khan on 1/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "OCKTreatmentTableViewCell.h"


NS_ASSUME_NONNULL_BEGIN

@class OCKTreatment, OCKCareCard, OCKWeekPageViewController;

@interface OCKTreatmentsTableViewController : UITableViewController <OCKTreatmentCellDelegate>

- (instancetype)initWithTreatments:(nullable NSArray<OCKTreatment *> *)treatments;

@property (nonatomic, readonly) OCKWeekPageViewController *weekPageViewController;
@property (nonatomic, copy, nullable) NSArray<OCKTreatment *> *treatments;
@property (nonatomic, readonly) OCKCareCard *careCard;

@end

NS_ASSUME_NONNULL_END
