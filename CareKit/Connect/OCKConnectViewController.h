//
//  OCKConnectViewController.h
//  CareKit
//
//  Created by Umer Khan on 1/30/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@class OCKContact, OCKConnectViewController;

@protocol OCKConnectSharingDelegate <NSObject>

- (NSString *)titleForSharingCellForContact:(OCKContact *)contact;

- (void)didSelectShareButtonForContact:(OCKContact *)contact;

@end


@interface OCKConnectViewController : UINavigationController

+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)connectViewControllerWithContacts:(NSArray<OCKContact *> *)contacts
                                  sharingDelegate:(nullable id<OCKConnectSharingDelegate>)sharingDelegate;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithRootViewController:(UIViewController *)rootViewController NS_UNAVAILABLE;
- (instancetype)initWithNavigationBarClass:(nullable Class)navigationBarClass toolbarClass:(nullable Class)toolbarClass NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithContacts:(NSArray<OCKContact *> *)contacts
                 sharingDelegate:(nullable id<OCKConnectSharingDelegate>)sharingDelegate;

@property (nonatomic, copy) NSArray<OCKContact *> *contacts;
@property (nonatomic) id<OCKConnectSharingDelegate> sharingDelegate;

@end

NS_ASSUME_NONNULL_END
