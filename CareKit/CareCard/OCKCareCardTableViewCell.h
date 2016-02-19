//
//  OCKTreatmentTableViewCell.h
//  CareKit
//
//  Created by Umer Khan on 1/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@class OCKTreatmentEvent, OCKCareCardTableViewCell;

@protocol OCKCareCardCellDelegate <NSObject>

@required

- (void)careCardCellDidUpdateFrequency:(OCKCareCardTableViewCell *)cell ofTreatmentEvent:(OCKTreatmentEvent *)event;

@end


@interface OCKCareCardTableViewCell : UITableViewCell

@property (nonatomic) NSArray<OCKTreatmentEvent *> *treatmentEvents;
@property (nonatomic) id<OCKCareCardCellDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
