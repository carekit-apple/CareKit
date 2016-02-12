//
//  OCKConnectTableViewController.h
//  CareKit
//
//  Created by Umer Khan on 1/30/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "OCKConnectTableViewCell.h"


NS_ASSUME_NONNULL_BEGIN

@class OCKContact;

@interface OCKConnectTableViewController : UITableViewController <OCKConnectTableViewCellDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate>

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithContacts:(NSArray<OCKContact *> *)contacts;

@property (nonatomic, copy) NSArray<OCKContact *> *contacts;

@end

NS_ASSUME_NONNULL_END
