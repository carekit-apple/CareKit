//
//  OCKEvaluationTableViewController.h
//  CareKit
//
//  Created by Umer Khan on 2/2/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@class OCKCarePlanStore, OCKEvaluationEvent;
@protocol OCKEvaluationTableViewDelegate;

@interface OCKEvaluationTableViewController : UITableViewController

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithCarePlanStore:(OCKCarePlanStore *)store
                             delegate:(id<OCKEvaluationTableViewDelegate>)delegate;

@property (nonatomic, readonly) OCKCarePlanStore *store;
@property (nonatomic) id<OCKEvaluationTableViewDelegate> delegate;
@property (nonatomic, readonly) OCKEvaluationEvent *lastSelectedEvaluationEvent;

@end

NS_ASSUME_NONNULL_END
