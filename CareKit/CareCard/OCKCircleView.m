//
//  OCKCircleView.m
//  CareKit
//
//  Created by Yuan Zhu on 2/25/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKCircleView.h"


@implementation OCKCircleView {
    CAShapeLayer *_circleLayer;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _value = 0.0;
    }
    return self;
}

- (CAShapeLayer *)createShapeLayerWithValue:(double)value {
    CGFloat diameter = MIN(self.frame.size.height, self.frame.size.width) * 0.9;
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.path = [self createPathWithValue:value].CGPath;
    layer.fillColor = [UIColor clearColor].CGColor;
    layer.strokeColor = self.tintColor.CGColor;
    layer.lineCap = @"round";
    layer.lineWidth = diameter * 0.1;
    
    return layer;
}

- (UIBezierPath *)createPathWithValue:(double)value {
    CGFloat diameter = MIN(self.frame.size.height, self.frame.size.width) * 0.9;

    CGFloat ProgressIndicatorRadius = diameter / 2;
    CGFloat OuterMargin = ProgressIndicatorRadius / 9;
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(ProgressIndicatorRadius + OuterMargin, ProgressIndicatorRadius + OuterMargin)
                                                 radius:ProgressIndicatorRadius
                                             startAngle: 2 * M_PI * (value - 0.25) 
                                               endAngle:-M_PI_2
                                              clockwise:NO];
    
    return path;
}

- (void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
    _circleLayer.strokeColor = self.tintColor.CGColor;
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    _circleLayer.strokeColor = self.tintColor.CGColor;
}

- (void)setValue:(double)value {
    double oldValue = _value;
    
    _value = MAX(MIN(value, 1), 0);
    
    if (oldValue != _value) {
        
        BOOL reverse = oldValue > _value;
        double delta = ABS(_value - oldValue);
        double maxValue = MAX(oldValue, _value);
        
        _circleLayer = [self createShapeLayerWithValue:maxValue];
        [self.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
        [self.layer addSublayer:_circleLayer];
        
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
        
        if (reverse) {
            animation.fromValue = @(0.0);
            animation.toValue = @(delta/maxValue);
        } else {
            animation.fromValue = @(delta/maxValue);
            animation.toValue = @(0.0);
        }
        
        animation.duration = 2.0 * delta;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        animation.fillMode = kCAFillModeBoth;
        animation.removedOnCompletion = false;
        
        [_circleLayer addAnimation:animation forKey:animation.keyPath];
       
    }
}

@end

