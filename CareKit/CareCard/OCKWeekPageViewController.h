//
//  OCKWeekPageViewController.h
//  CareKit
//
//  Created by Umer Khan on 1/29/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


@class OCKHeartWeekView;

@interface OCKWeekPageViewController : UIPageViewController

@property (nonatomic, readonly) OCKHeartWeekView *heartWeekView;

@end
