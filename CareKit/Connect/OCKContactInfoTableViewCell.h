//
//  OCKContactInfoTableViewCell.h
//  CareKit
//
//  Created by Umer Khan on 2/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKConnectTableViewCell.h"


@class OCKContact, OCKContactInfoTableViewCell;

@protocol OCKContactInfoTableViewCellDelegate <NSObject>

- (void)contactInfoTableViewCellDidSelectConnection:(OCKContactInfoTableViewCell *)cell;

@end


@interface OCKContactInfoTableViewCell : UITableViewCell

@property (nonatomic) OCKContact *contact;
@property (nonatomic) OCKConnectType connectType;
@property (nonatomic) id<OCKContactInfoTableViewCellDelegate> delegate;

@end
