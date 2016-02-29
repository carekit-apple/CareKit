//
//  OCKReportTableViewCell.h
//  CareKit
//
//  Created by Umer Khan on 2/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


@class OCKContact, OCKReportsTableViewCell;

@protocol OCKReportsTableViewCellDelegate <NSObject>

- (void)reportsTableViewCellDidSelectShareButton:(OCKReportsTableViewCell *)cell;

@end

@interface OCKReportsTableViewCell : UITableViewCell

@property (nonatomic) NSString *title;
@property (nonatomic) OCKContact *contact;
@property (nonatomic) id<OCKReportsTableViewCellDelegate> delegate;

@end
