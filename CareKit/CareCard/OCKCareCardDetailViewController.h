//
//  OCKCareCardDetailViewController.h
//  CareKit
//
//  Created by Umer Khan on 2/18/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


@class OCKTreatmentEvent;

@interface OCKCareCardDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) NSArray<OCKTreatmentEvent *> *treatmentEvents;

@end
