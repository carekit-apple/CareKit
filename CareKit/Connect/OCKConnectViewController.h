//
//  OCKConnectViewController.h
//  CareKit
//
//  Created by Umer Khan on 1/30/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@class OCKContact, OCKConnectDetailViewController;

@protocol OCKConnectViewControllerDelegate <NSObject>

- (NSString *)connectDetailViewController:(OCKConnectDetailViewController *)connectDetailViewController titleForSharingCellForContact:(OCKContact *)contact;

- (void)connectDetailViewController:(OCKConnectDetailViewController *)connectDetailViewController didSelectShareButtonForContact:(OCKContact *)contact;

@end


@interface OCKConnectViewController : UIViewController

- (instancetype)initWithContacts:(NSArray<OCKContact *> *)contacts;

@property (nonatomic, copy) NSArray<OCKContact *> *contacts;
@property (nonatomic, weak, nullable) id<OCKConnectViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
