//
//  OCKWeekPageViewController.m
//  CareKit
//
//  Created by Umer Khan on 1/29/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKWeekPageViewController.h"
#import "OCKWeekView.h"
#import "OCKCareCardWeekView.h"
#import "OCKEvaluationWeekView.h"


@implementation OCKWeekPageViewController {
    OCKCareCardWeekView *_careCardWeekView;
    OCKEvaluationWeekView *_evaluationWeekView;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    _showCareCardWeekView = NO;
    [self prepareView];
}

- (void)prepareView {
    if (_showCareCardWeekView) {
        _evaluationWeekView = nil;
        if (!_careCardWeekView) {
            _careCardWeekView = [[OCKCareCardWeekView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 40.0)];
            [self.view addSubview:_careCardWeekView];
        }
        self.view.frame = _careCardWeekView.frame;
    } else {
        _careCardWeekView = nil;
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
    
    if (_careCardWeekView) {
        NSDictionary *views = NSDictionaryOfVariableBindings(_careCardWeekView);
        _careCardWeekView.translatesAutoresizingMaskIntoConstraints = NO;
        
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

- (void)setShowCareCardWeekView:(BOOL)showHeartWeekView {
    _showCareCardWeekView = showHeartWeekView;
    [self prepareView];
}

@end
