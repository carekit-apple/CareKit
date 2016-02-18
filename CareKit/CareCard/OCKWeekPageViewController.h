//
//  OCKWeekPageViewController.h
//  CareKit
//
//  Created by Umer Khan on 1/29/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


@class OCKCareCardWeekView, OCKEvaluationWeekView;

@interface OCKWeekPageViewController : UIPageViewController

@property (nonatomic) BOOL showCareCardWeekView;
@property (nonatomic, readonly) OCKCareCardWeekView *careCardWeekView;
@property (nonatomic, readonly) OCKEvaluationWeekView *evaluationWeekView;

@end
