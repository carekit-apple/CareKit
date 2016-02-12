//
//  OCKWeekPageViewController.m
//  CareKit
//
//  Created by Umer Khan on 1/29/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKWeekPageViewController.h"
#import "OCKCareCard.h"
#import "OCKHeartWeekView.h"


@implementation OCKWeekPageViewController {
    OCKHeartWeekView *_heartWeekView;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self prepareView];
}

- (void)prepareView {
    if (!_heartWeekView) {
        _heartWeekView = [[OCKHeartWeekView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 40.0)];
        _heartWeekView.careCards = @[[OCKCareCard careCardWithAdherence:0.5 date:@""],
                                     [OCKCareCard careCardWithAdherence:0.6 date:@""],
                                     [OCKCareCard careCardWithAdherence:1.0 date:@""],
                                     [OCKCareCard careCardWithAdherence:0.35 date:@""],
                                     [OCKCareCard careCardWithAdherence:1.0 date:@""],
                                     [OCKCareCard careCardWithAdherence:1.0 date:@""],
                                     [OCKCareCard careCardWithAdherence:0.0 date:@""]];
        [self.view addSubview:_heartWeekView];
    }
    self.view.frame = _heartWeekView.frame;
}


#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    _heartWeekView.careCards = @[[OCKCareCard careCardWithAdherence:0.5 date:@""],
                                 [OCKCareCard careCardWithAdherence:0.6 date:@""],
                                 [OCKCareCard careCardWithAdherence:1.0 date:@""],
                                 [OCKCareCard careCardWithAdherence:0.35 date:@""],
                                 [OCKCareCard careCardWithAdherence:1.0 date:@""],
                                 [OCKCareCard careCardWithAdherence:1.0 date:@""],
                                 [OCKCareCard careCardWithAdherence:0.0 date:@""]];
    return [UIViewController new];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    _heartWeekView.careCards = @[[OCKCareCard careCardWithAdherence:0.25 date:@""],
                                 [OCKCareCard careCardWithAdherence:0.0 date:@""],
                                 [OCKCareCard careCardWithAdherence:0.5 date:@""],
                                 [OCKCareCard careCardWithAdherence:1.0 date:@""],
                                 [OCKCareCard careCardWithAdherence:0.33 date:@""],
                                 [OCKCareCard careCardWithAdherence:0.1 date:@""],
                                 [OCKCareCard careCardWithAdherence:0.75 date:@""]];
;
    return self;
}

@end
