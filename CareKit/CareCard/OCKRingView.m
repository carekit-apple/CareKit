//
//  OCKCircleView.m
//  CareKit
//
//  Created by Yuan Zhu on 2/25/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import "OCKRingView.h"

static const double VALUE_MIN = 0.0;
static const double VALUE_MAX = 1.0;

@implementation OCKRingView {
    CAShapeLayer *_circleLayer;
    CAShapeLayer *_backgroundLayer;
    CAShapeLayer *_checkmarkLayer;
    UILabel *_label;
    NSNumberFormatter *_numberFormatter;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _value = VALUE_MIN;
        _label = [self createLabel];
        
        _numberFormatter = [[NSNumberFormatter alloc] init];
        [_numberFormatter setNumberStyle:NSNumberFormatterPercentStyle];
        [_numberFormatter setMaximumFractionDigits:0];
        [_numberFormatter setMultiplier:@100];
        
        [self updateLabel];
        
        _backgroundLayer = [self createShapeLayerWithValue:VALUE_MAX];
        _backgroundLayer.strokeColor = [UIColor groupTableViewBackgroundColor].CGColor;
        [self.layer addSublayer:_backgroundLayer];
        
        _checkmarkLayer = [self createCheckMarkLayer];
        _checkmarkLayer.strokeEnd = 0.0;
        [self.layer addSublayer:_checkmarkLayer];
        [self updateCheckmark];
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

- (CAShapeLayer *)createCheckMarkLayer {
    
    CGPoint ringCenter = [self ringCenter];
    UIBezierPath *path = [UIBezierPath new];
    
    [path moveToPoint:CGPointMake(ringCenter.x*37.0/61.0, ringCenter.x*65.0/61.0)];
    [path addLineToPoint:CGPointMake(ringCenter.x*50.0/61.0, ringCenter.x*78.0/61.0)];
    [path addLineToPoint:CGPointMake(ringCenter.x*87.0/61.0, ringCenter.x*42.0/61.0)];
    path.lineCapStyle = kCGLineCapRound;
    path.lineWidth = [self ringRadius]*2/9;
    
    CAShapeLayer *shapeLayer = [CAShapeLayer new];
    shapeLayer.path = path.CGPath;
    shapeLayer.lineWidth = path.lineWidth;
    shapeLayer.lineCap = kCALineCapRound;
    shapeLayer.lineJoin = kCALineJoinRound;
    shapeLayer.frame = self.layer.bounds;
    shapeLayer.strokeColor = [UIColor whiteColor].CGColor;
    shapeLayer.backgroundColor = [UIColor clearColor].CGColor;
    shapeLayer.fillColor = nil;
    
    return shapeLayer;
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
    [self updateLabel];
}

- (void)updateLabel {
    if (_hideLabel) {
        [_label removeFromSuperview];
    } else {
        _label.text = [_numberFormatter stringFromNumber:@(_value)];
        [self addSubview:_label];
    }
}

- (void)updateCheckmark {
    if (_value == VALUE_MAX) {
        [_label removeFromSuperview];
        _circleLayer.fillColor = self.tintColor.CGColor;
        _checkmarkLayer.strokeEnd = 1.0;
    } else {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        _circleLayer.fillColor = [UIColor clearColor].CGColor;
        _checkmarkLayer.strokeEnd = 0.0;
        [CATransaction commit];
    }
}

- (void)setValue:(double)value {
    
    double oldValue = _value;
    
    _value = MAX(MIN(value, VALUE_MAX), VALUE_MIN);
    
    if (oldValue != _value) {
        
        [self updateLabel];
        
        if (_disableAnimation) {
            _circleLayer = [self createShapeLayerWithValue:_value];
            [_circleLayer removeFromSuperlayer];
            [self.layer insertSublayer:_circleLayer below:_checkmarkLayer];
            [self updateCheckmark];
            
        } else {
            
            [CATransaction begin];
            
            if (oldValue == VALUE_MAX) {
                [self updateCheckmark];
            }
            
            BOOL reverse = oldValue > _value;
            double delta = ABS(_value - oldValue);
            double maxValue = MAX(oldValue, _value);
            
            [_circleLayer removeFromSuperlayer];
            _circleLayer = [self createShapeLayerWithValue:maxValue];
            [self.layer insertSublayer:_circleLayer below:_checkmarkLayer];
            
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
            
            if (reverse) {
                animation.fromValue = @(VALUE_MIN);
                animation.toValue = @(delta/maxValue);
            } else {
                animation.fromValue = @(delta/maxValue);
                animation.toValue = @(VALUE_MIN);
            }
            
            animation.beginTime = 0.0;
            animation.duration = 1.25;
            animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
            animation.fillMode = kCAFillModeBoth;
            animation.removedOnCompletion = false;
            
            BOOL removeLayerOnCompletion = (_value == VALUE_MIN);
            [CATransaction setCompletionBlock:^{
                [self updateLabel];
                [self updateCheckmark];
                if (removeLayerOnCompletion) {
                    [_circleLayer removeFromSuperlayer];
                }
            }];
            
            [_circleLayer addAnimation:animation forKey:animation.keyPath];
            [CATransaction commit];
        }
        
    }
}

@end

