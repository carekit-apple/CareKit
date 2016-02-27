//
//  OCKCircleView.m
//  CareKit
//
//  Created by Yuan Zhu on 2/25/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import "OCKRingView.h"

@implementation OCKRingView {
    CAShapeLayer *_circleLayer;
    CAShapeLayer *_backgroundLayer;
    UILabel *_label;
    NSNumberFormatter *_numberFormatter;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _value = 0.0;
        _label = [self createLabel];
        [self addSubview:_label];
        
        _numberFormatter = [[NSNumberFormatter alloc] init];
        [_numberFormatter setNumberStyle:NSNumberFormatterPercentStyle];
        [_numberFormatter setMaximumFractionDigits:0];
        [_numberFormatter setMultiplier:@100];
        
        _label.text = [_numberFormatter stringFromNumber:@(_value)];
        
        _backgroundLayer = [self createShapeLayerWithValue:1.0];
        _backgroundLayer.strokeColor = [UIColor lightGrayColor].CGColor;
        [self.layer addSublayer:_backgroundLayer];
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
    
    CGFloat radius = [self ringRadius];
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:[self ringCenter]
                                                 radius:radius
                                             startAngle:2 * M_PI * (value - 0.25)
                                               endAngle:-M_PI_2
                                              clockwise:NO];
    
    return path;
}

- (CGFloat)ringRadius {
    CGFloat radius = MIN(self.frame.size.height, self.frame.size.width) * 0.9 * 0.5;
    return radius;
}

- (CGPoint)ringCenter {
    CGFloat radius = [self ringRadius];
    CGFloat OuterMargin = radius / 9;
    return CGPointMake(radius + OuterMargin, radius + OuterMargin);
}

- (UILabel *)createLabel {
    UILabel *label = [[UILabel alloc] init];
    CGFloat radius = [self ringRadius];
    label.frame = CGRectMake(0, 0, radius * 1.414, radius);
    label.center = [self ringCenter];
    label.textAlignment = NSTextAlignmentCenter;
   
    label.adjustsFontSizeToFitWidth = YES;
    label.numberOfLines = 1;
    
    label.font = [UIFont fontWithName:label.font.fontName size:radius/2.2];
    
    return label;
}

- (void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
    _circleLayer.strokeColor = self.tintColor.CGColor;
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    _circleLayer.strokeColor = self.tintColor.CGColor;
}

- (void)setHideLabel:(BOOL)hideLabel {
    _hideLabel = hideLabel;
    if (_hideLabel) {
        [_label removeFromSuperview];
    } else {
        _label.text = [_numberFormatter stringFromNumber:@(_value)];
        [self addSubview:_label];
    }
}

- (void)setValue:(double)value {
    
    double oldValue = _value;
    
    _value = MAX(MIN(value, 1), 0);
    
    if (oldValue != _value) {
        
        if (_disableAnimation) {
            _circleLayer = [self createShapeLayerWithValue:_value];
            [_circleLayer removeFromSuperlayer];
            [self.layer addSublayer:_circleLayer];
        } else {
            BOOL reverse = oldValue > _value;
            double delta = ABS(_value - oldValue);
            double maxValue = MAX(oldValue, _value);
            
            _circleLayer = [self createShapeLayerWithValue:maxValue];
            [_circleLayer removeFromSuperlayer];
            [self.layer addSublayer:_circleLayer];
            
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
            
            if (reverse) {
                animation.fromValue = @(0.0);
                animation.toValue = @(delta/maxValue);
            } else {
                animation.fromValue = @(delta/maxValue);
                animation.toValue = @(0.0);
            }
            
            animation.duration = 1.25; //2.0 * delta;
            animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
            animation.fillMode = kCAFillModeBoth;
            animation.removedOnCompletion = false;
            
            [_circleLayer addAnimation:animation forKey:animation.keyPath];
        }
        
        if (_hideLabel == NO) {
            _label.text = [_numberFormatter stringFromNumber:@(_value)];
            [self addSubview:_label];
        }
    }
}

@end

