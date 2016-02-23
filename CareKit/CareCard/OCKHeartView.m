//
//  OCKHeartView.m
//  CareKit
//
//  Created by Umer Khan on 2/22/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKHeartView.h"


@implementation OCKHeartView {
    CAShapeLayer *_heartLayer;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _heartLayer = [CAShapeLayer layer];
        _heartLayer.path = [[UIBezierPath bezierPathWithArcCenter:CGPointMake(150/2, 150/2)
                                                           radius:150/2
                                                       startAngle:M_PI + M_PI_2
                                                         endAngle:-M_PI_2
                                                        clockwise:NO] CGPath];
        _heartLayer.fillColor = [UIColor clearColor].CGColor;
        _heartLayer.strokeColor = self.tintColor.CGColor;
        _heartLayer.lineWidth = 2.0;
        [self.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
        [self.layer addSublayer:_heartLayer];
    }
    return self;
}

- (void)startAnimateWithDuration:(NSTimeInterval)duration {
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"strokeEnd"];
    animation.duration = duration * 2;
    animation.values = @[@(1.0), @(0.0), @(0.0)];
    animation.keyTimes =  @[@(0.0), @(0.5), @(1.0)];
    animation.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    [_heartLayer addAnimation:animation forKey:@"drawCircleAnimation"];
}



@end
