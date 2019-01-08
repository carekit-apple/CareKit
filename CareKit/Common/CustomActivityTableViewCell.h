//
//  CustomActivityTableViewCell.h
//  CareKit
//
//  Created by Damian Dara on 9/1/19.
//  Copyright © 2019 carekit.org. All rights reserved.
//

#import <CareKit/CareKit.h>
#import "OCKTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface CustomActivityTableViewCell : OCKTableViewCell

@property (nonatomic, copy) OCKCarePlanEvent *event;
@property (nonatomic, copy) UIColor *cellBackgroundColor;

@end

NS_ASSUME_NONNULL_END
