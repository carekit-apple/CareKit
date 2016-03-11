//
//  OCKCareCardDetailViewController.h
//  CareKit
//
//  Created by Umer Khan on 2/18/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


@class OCKCarePlanActivity;

@interface OCKCareCardDetailViewController : UITableViewController

- (instancetype)initWithTreatment:(OCKCarePlanActivity *)treatment;

@property (nonatomic) OCKCarePlanActivity *treatment;

@end
