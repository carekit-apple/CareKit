//
//  OCKTreatmentsViewController.h
//  CareKit
//
//  Created by Umer Khan on 1/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@class OCKCarePlanStore;

@interface OCKCareCardViewController : UINavigationController

+ (instancetype)careCardViewControllerWithCarePlanStore:(OCKCarePlanStore *)store;

- (instancetype)initWithCarePlanStore:(OCKCarePlanStore *)store;

@property (nonatomic, readonly) OCKCarePlanStore *store;

@end

NS_ASSUME_NONNULL_END
