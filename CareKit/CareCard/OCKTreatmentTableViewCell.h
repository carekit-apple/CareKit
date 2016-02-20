//
//  OCKTreatmentTableViewCell.h
//  CareKit
//
//  Created by Umer Khan on 1/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@class OCKCarePlanActivity, OCKTreatmentTableViewCell;

@protocol OCKTreatmentCellDelegate <NSObject>

@required

- (void)treatmentCellDidUpdateFrequency:(OCKTreatmentTableViewCell *)cell;

@end


@interface OCKTreatmentTableViewCell : UITableViewCell

@property (nonatomic) OCKCarePlanActivity *treatment;
@property (nonatomic) id<OCKTreatmentCellDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
