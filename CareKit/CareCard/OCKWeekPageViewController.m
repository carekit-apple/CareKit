//
//  OCKWeekPageViewController.m
//  CareKit
//
//  Created by Umer Khan on 1/29/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKWeekPageViewController.h"
#import "OCKCareCard.h"
#import "OCKWeekView.h"
#import "OCKHeartWeekView.h"
#import "OCKEvaluationWeekView.h"


@implementation OCKWeekPageViewController {
    OCKHeartWeekView *_heartWeekView;
    OCKEvaluationWeekView *_evaluationWeekView;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    _showHeartWeekView = NO;
    [self prepareView];
}

- (void)prepareView {
    if (_showHeartWeekView) {
        _evaluationWeekView = nil;
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
    } else {
        _heartWeekView = nil;
        if (!_evaluationWeekView) {
            _evaluationWeekView = [[OCKEvaluationWeekView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 15.0)];
            _evaluationWeekView.backgroundColor = [UIColor whiteColor];
            [self.view addSubview:_evaluationWeekView];
        }
        self.view.frame = _evaluationWeekView.frame;
    }
    
    [self setUpConstraints];
}

- (void)setUpConstraints {
    NSMutableArray *constraints = [NSMutableArray new];
    
    if (_heartWeekView) {
        NSDictionary *views = NSDictionaryOfVariableBindings(_heartWeekView);
        _heartWeekView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_heartWeekView]|"
                                                                                 options:NSLayoutFormatDirectionLeadingToTrailing
                                                                                 metrics:nil
                                                                                   views:views]];
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_heartWeekView]|"
                                                                                 options:NSLayoutFormatDirectionLeadingToTrailing
                                                                                 metrics:nil
                                                                                   views:views]];
    } else if (_evaluationWeekView) {
        NSDictionary *views = NSDictionaryOfVariableBindings(_evaluationWeekView);
        _evaluationWeekView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_evaluationWeekView]|"
                                                                                 options:NSLayoutFormatDirectionLeadingToTrailing
                                                                                 metrics:nil
                                                                                   views:views]];
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_evaluationWeekView]|"
                                                                                 options:NSLayoutFormatDirectionLeadingToTrailing
                                                                                 metrics:nil
                                                                                   views:views]];
    }
    
    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)setShowHeartWeekView:(BOOL)showHeartWeekView {
    _showHeartWeekView = showHeartWeekView;
    [self prepareView];
}


#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {

    return self;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {

    return self;
}

@end
