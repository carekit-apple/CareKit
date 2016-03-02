//
//  OCKWeekPageViewController.m
//  CareKit
//
//  Created by Umer Khan on 1/29/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKWeekViewController.h"
#import "OCKWeekView.h"
#import "OCKCareCardWeekView.h"
#import "OCKEvaluationWeekView.h"


@implementation OCKWeekViewController {
    OCKCareCardWeekView *_careCardWeekView;
    OCKEvaluationWeekView *_evaluationWeekView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _showCareCardWeekView = YES;
    [self prepareView];
}

- (void)prepareView {
    if (_showCareCardWeekView) {
        if (!_careCardWeekView) {
            _careCardWeekView = [[OCKCareCardWeekView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 40.0)];
            [self.view addSubview:_careCardWeekView];
            [_evaluationWeekView removeFromSuperview];
        }
    } else {
        if (!_evaluationWeekView) {
            _evaluationWeekView = [[OCKEvaluationWeekView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 40.0)];
            [self.view addSubview:_evaluationWeekView];
            [_careCardWeekView removeFromSuperview];
        }
    }
    self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, 60.0);
}

- (void)setShowCareCardWeekView:(BOOL)showCareCardWeekView {
    _showCareCardWeekView = showCareCardWeekView;
    [self prepareView];
}

@end
