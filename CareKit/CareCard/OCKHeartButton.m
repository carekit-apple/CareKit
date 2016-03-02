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
    _heartView.maskImage = [UIImage imageNamed:@"heart-small" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    _heartView.userInteractionEnabled = NO;
    [self addSubview:_heartView];
}

@end
