//
//  OCKConnectTableViewController.h
//  CareKit
//
//  Created by Umer Khan on 1/30/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import "OCKConnectTableViewCell.h"


NS_ASSUME_NONNULL_BEGIN

@class OCKContact;
@protocol OCKConnectSharingDelegate;

@protocol OCKConnectTableViewDelegate <NSObject>

- (void)tableView:(UITableView *)tableView didSelectRowWithContact:(OCKContact *)contact;

@end


@interface OCKConnectTableViewController : UITableViewController

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithContacts:(NSArray<OCKContact *> *)contacts;

@property (nonatomic, copy) NSArray<OCKContact *> *contacts;
@property (nonatomic) id<OCKConnectTableViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
