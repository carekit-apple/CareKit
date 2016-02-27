//
//  OCKRingButton.m
//  CareKit
//
//  Created by Umer Khan on 2/26/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKRingButton.h"
#import "OCKCircleView.h"


@implementation OCKRingButton

- (void)setCircleView:(OCKCircleView *)circleView {
    [_circleView removeFromSuperview];
    
    _circleView = circleView;
    _circleView.userInteractionEnabled = NO;
    [self addSubview:_circleView];
}

@end
