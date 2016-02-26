//
//  OCKHeartButton.m
//  CareKit
//
//  Created by Umer Khan on 2/25/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKHeartButton.h"
#import "OCKHeartView.h"


@implementation OCKHeartButton

- (void)setHeartView:(OCKHeartView *)heartView {
    [_heartView removeFromSuperview];
    
    _heartView = heartView;
    _heartView.userInteractionEnabled = NO;
    [self addSubview:_heartView];
}

@end
