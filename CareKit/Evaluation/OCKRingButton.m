//
//  OCKRingButton.m
//  CareKit
//
//  Created by Umer Khan on 2/26/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKRingButton.h"
#import "OCKRingView.h"


@implementation OCKRingButton

- (void)setRingView:(OCKRingView *)ringView {
    [_ringView removeFromSuperview];
    
    _ringView = ringView;
    _ringView.userInteractionEnabled = NO;
    [self addSubview:_ringView];
}

@end
