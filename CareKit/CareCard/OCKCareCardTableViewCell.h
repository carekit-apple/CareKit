//
//  OCKTreatmentTableViewCell.h
//  CareKit
//
//  Created by Umer Khan on 1/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@class OCKCarePlanEvent, OCKCareCardTableViewCell;

@protocol OCKCareCardCellDelegate <NSObject>

@required

- (void)careCardCellDidUpdateFrequency:(OCKCareCardTableViewCell *)cell ofTreatmentEvent:(OCKCarePlanEvent *)event;

@end


@interface OCKCareCardTableViewCell : UITableViewCell

@property (nonatomic) NSArray<OCKCarePlanEvent *> *treatmentEvents;
@property (nonatomic) id<OCKCareCardCellDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
