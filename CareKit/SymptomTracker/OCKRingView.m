/*
 Copyright (c) 2016, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "OCKRingView.h"


static const double VALUE_MIN = 0.0;
static const double VALUE_MAX = 1.0;

@implementation OCKRingView {
    CAShapeLayer *_circleLayer;
    CAShapeLayer *_backgroundLayer;
    CAShapeLayer *_checkmarkLayer;
    UILabel *_label;
    NSNumberFormatter *_numberFormatter;
    NSUUID *_transactionID;
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
        [self updateCheckmarkForValue:_value];
    }
    return self;
}

- (CAShapeLayer *)createShapeLayerWithValue:(double)value {
    
    CGFloat diameter = MIN(self.frame.size.height, self.frame.size.width) * 0.9;
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.path = [self createPathWithValue:value].CGPath;
    layer.fillColor = [UIColor clearColor].CGColor;
    layer.strokeColor = self.tintColor.CGColor;
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
    path.lineCapStyle = kCGLineCapSquare;
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

- (void)tintColorDidChange {
    [super tintColorDidChange];
    _circleLayer.strokeColor = self.tintColor.CGColor;
    if (_circleLayer.fillColor != [UIColor clearColor].CGColor) {
        _circleLayer.fillColor = self.tintColor.CGColor;
    }
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

- (void)updateCheckmarkForValue:(double)value {
    
    [CATransaction begin];
    if (value == VALUE_MAX) {
        [CATransaction setDisableActions:_disableAnimation];
        [_label removeFromSuperview];
        _circleLayer.fillColor = self.tintColor.CGColor;
        _checkmarkLayer.strokeEnd = 1.0;
    } else {
        [CATransaction setDisableActions:YES];
        _circleLayer.fillColor = [UIColor clearColor].CGColor;
        _checkmarkLayer.strokeEnd = 0.0;
    }
    [CATransaction commit];
}

- (void)setValue:(double)value {
   
    value = MAX(MIN(value, VALUE_MAX), VALUE_MIN);
    
    if (value != _value) {
        double oldValue = _value;
        _value = value;
        
        if (_disableAnimation) {
            [self updateLabel];
            [_circleLayer removeFromSuperlayer];
            _circleLayer = [self createShapeLayerWithValue:_value];
            [self.layer insertSublayer:_circleLayer below:_checkmarkLayer];
            [self updateCheckmarkForValue:_value];
        } else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
                [_circleLayer removeAllAnimations];
                NSUUID *caid = [NSUUID UUID];
                _transactionID = caid;

                [self updateCheckmarkForValue:oldValue];
                [self updateLabel];
    
                [CATransaction begin];
                
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
                animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                animation.fillMode = kCAFillModeBoth;
                animation.removedOnCompletion = NO;
                
                [CATransaction setCompletionBlock:^{
                    if ([caid isEqual:_transactionID]) {
                        [self updateLabel];
                        [self updateCheckmarkForValue:_value];
                        if (_value == VALUE_MIN) {
                            [_circleLayer removeFromSuperlayer];
                        }
                    }
                }];
                
                [_circleLayer addAnimation:animation forKey:animation.keyPath];
                [CATransaction commit];
            });
        }
        
    }
}

- (NSString *)accessibilityLabel {
    return [_label accessibilityLabel];
}

@end

