//
//  OCKConnectTableViewCell.h
//  CareKit
//
//  Created by Umer Khan on 2/1/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, OCKConnectType) {
    OCKConnectTypePhone = 0,
    OCKConnectTypeMessage,
    OCKConnectTypeEmail
};

@class OCKContact, OCKConnectTableViewCell;

@protocol OCKConnectTableViewCellDelegate <NSObject>

- (void)connectTableViewCell:(OCKConnectTableViewCell *)cell didSelectConnectType:(OCKConnectType)connectType;

@end


@interface OCKConnectTableViewCell : UITableViewCell

@property (nonatomic) OCKContact *contact;
@property (nonatomic) id<OCKConnectTableViewCellDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
