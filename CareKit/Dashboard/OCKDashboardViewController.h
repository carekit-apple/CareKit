//
//  OCKDashboardViewController.h
//  CareKit
//
//  Created by Umer Khan on 1/20/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@class OCKChart;

@interface OCKDashboardViewController : UINavigationController

+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)dashboardWithCharts:(NSArray<OCKChart *> *)charts;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithRootViewController:(UIViewController *)rootViewController NS_UNAVAILABLE;
- (instancetype)initWithNavigationBarClass:(nullable Class)navigationBarClass toolbarClass:(nullable Class)toolbarClass NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCharts:(NSArray<OCKChart*> *)charts NS_DESIGNATED_INITIALIZER;

@property (nonatomic, copy) NSArray<OCKChart *> *charts;
@property (nonatomic, copy) NSString *headerTitle;
@property (nonatomic, copy) NSString *headerText;

@end

NS_ASSUME_NONNULL_END
