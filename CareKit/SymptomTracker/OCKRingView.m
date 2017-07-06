/*
 Copyright (c) 2017, Apple Inc. All rights reserved.
 
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
#import "OCKGlyph_Internal.h"
#import "OCKHeaderView.h"
#import "OCKRingButton.h"


static const double VALUE_MIN = 0.0;
static const double VALUE_MAX = 1.0;


@implementation OCKRingView {
    CAShapeLayer *_circleLayer;
    CAShapeLayer *_backgroundLayer;
    CAShapeLayer *_activeGlyphLayer;
    CAShapeLayer *_filledCircleLayer;
    
    NSNumberFormatter *_numberFormatter;
    NSUUID *_transactionID;
    
    UIImageView *_glyphImageView;
}

- (instancetype)initWithFrame:(CGRect)frame
                 useSmallRing:(BOOL)useSmallRing {
    self = [super initWithFrame:frame];
    if (self) {
        _value = VALUE_MIN;
        
        _useSmallRing = useSmallRing;
        
        _numberFormatter = [[NSNumberFormatter alloc] init];
        [_numberFormatter setNumberStyle:NSNumberFormatterPercentStyle];
        [_numberFormatter setMaximumFractionDigits:0];
        [_numberFormatter setMultiplier:@100];
        
        _backgroundLayer = [self createShapeLayerWithValue:VALUE_MAX];
        _backgroundLayer.borderWidth = 10;
        _backgroundLayer.borderColor = self.tintColor.CGColor;
        _backgroundLayer.strokeColor = [UIColor groupTableViewBackgroundColor].CGColor;
        [self.layer addSublayer:_backgroundLayer];
        
        _activeGlyphLayer = [self createActiveGlyphLayer];
        _activeGlyphLayer.strokeEnd = 0.0;
        
        [self.layer addSublayer:_activeGlyphLayer];
        _glyphImageView = [self createGlyphView];
        
        _filledCircleLayer = [self filledCircleLayer];
        
        [self addSubview:_glyphImageView];
        
    }
    return self;
}

- (void)setValue:(double)value {
    if (value != _value) {
        
        double oldValue = _value;
        _value = value;
        
        if (_disableAnimation) {
            [_circleLayer removeFromSuperlayer];
            _circleLayer = [self createShapeLayerWithValue:_value];
            [self.layer insertSublayer:_circleLayer below:_activeGlyphLayer];
            [self updateGlyphForValue:_value animate:NO];
            
        } else {
            
            if (oldValue == VALUE_MAX && _value < VALUE_MAX) {
                [self updateGlyphForValue:_value animate:NO];
            }
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSNumber *presentationLayerValue;
                if (![_circleLayer.presentationLayer animationForKey:@"strokeStart"]) {
                    presentationLayerValue = @(1.0 - oldValue);
                } else {
                    presentationLayerValue = [_circleLayer.presentationLayer valueForKey:@"strokeStart"];
                    [_circleLayer removeAllAnimations];
                }
                
                NSUUID *caid = [NSUUID UUID];
                _transactionID = caid;
                
                [CATransaction begin];
                
                [_circleLayer removeFromSuperlayer];
                _circleLayer = [self createShapeLayerWithValue:VALUE_MAX];
                [self.layer insertSublayer:_circleLayer below:_activeGlyphLayer];
                
                CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
                animation.fromValue = @([presentationLayerValue doubleValue]);
                animation.toValue = @(1.0 - value);
                animation.beginTime = 0.0;
                animation.duration = 1.25;
                animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                animation.fillMode = kCAFillModeBoth;
                animation.removedOnCompletion = NO;
                
                [CATransaction setCompletionBlock:^{
                    if([caid isEqual:_transactionID]){
                        if ((oldValue == VALUE_MAX && _value < VALUE_MAX) || (oldValue < VALUE_MAX && _value == VALUE_MAX)) {
                            [self updateGlyphForValue:value animate:YES];
                        }
                        if (_value == VALUE_MIN) {
                            [_circleLayer removeFromSuperlayer];
                        }
                    }
                }];
                
                [_circleLayer addAnimation:animation forKey:animation.keyPath];
                [CATransaction commit];
            });
        }
        
    } else {
        if (value != VALUE_MAX) {
            if(![self.superview isKindOfClass:[OCKHeaderView class]]){
                _glyphImageView.image = nil;
                _backgroundLayer.fillColor = [UIColor clearColor].CGColor;
            } else{
                [_glyphImageView setImage:[self getGlyphImage]];
                _backgroundLayer.fillColor = [UIColor clearColor].CGColor;
                [_filledCircleLayer removeFromSuperlayer];
                
                CAShapeLayer *maskLayer = [self getGlyphMaskLayer];
                _glyphImageView.layer.mask = maskLayer;
            }
        }
    }
}

- (UIImageView *)createGlyphView {
    NSInteger viewSize = self.useSmallRing ? 15.0 : 75.0;
    CGRect glyphViewFrame = CGRectMake(self.frame.origin.x, self.frame.origin.y, viewSize, viewSize);
    UIImageView *glyphImageView = [[UIImageView alloc] initWithFrame:glyphViewFrame];
    glyphImageView.center = [self ringCenter];
    return glyphImageView;
}

- (CAShapeLayer *)createShapeLayerWithValue:(double)value {
    CGFloat diameter = [self ringRadius] * 2;
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.lineCap = kCALineCapRound;
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

- (CAShapeLayer *)createActiveGlyphLayer {
    
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
    return self.useSmallRing ? 13.5 : 50.0;
}

- (CGPoint)ringCenter {
    CGFloat radius = [self ringRadius];
    CGFloat OuterMargin = radius / 9;
    return CGPointMake(radius + OuterMargin, radius + OuterMargin);
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    _circleLayer.strokeColor = self.tintColor.CGColor;
    if (_circleLayer.fillColor != [UIColor clearColor].CGColor) {
        _circleLayer.fillColor = self.tintColor.CGColor;
    }
    _backgroundLayer.borderColor = self.tintColor.CGColor;
}

- (void)updateGlyphForValue:(double)value animate:(BOOL)animate {
    _glyphImageView.alpha = 1.0;
    if (value == VALUE_MAX) {
        _glyphImageView.layer.mask = nil;
        _backgroundLayer.strokeColor = self.tintColor.CGColor;
        
        if(![self.superview isKindOfClass:[OCKHeaderView class]]) {
            UIImage *smallImage = [self getCompletionImage];
            _glyphImageView.image = smallImage;
            _backgroundLayer.fillColor = self.tintColor.CGColor;
        } else {
            UIImage *bigImage = [self getCompletionImage];
            if (animate) {
                [UIView transitionWithView:_glyphImageView duration:0.25f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                    [self ringAnimation];
                    _glyphImageView.image = bigImage;
                } completion:nil];
                
            } else {
                    _backgroundLayer.fillColor = self.tintColor.CGColor;
                    _glyphImageView.image = bigImage;
                }
        }
    } else  {
        CAShapeLayer *maskLayer = [self getGlyphMaskLayer];
        _glyphImageView.layer.mask = maskLayer;
        
        _backgroundLayer.strokeColor = [UIColor groupTableViewBackgroundColor].CGColor;
        
        if(![self.superview isKindOfClass:[OCKHeaderView class]]){
            _glyphImageView.image = nil;
            _backgroundLayer.fillColor = [UIColor clearColor].CGColor;
        }else{
            UIImage *glyphImage = [self getGlyphImage];
           
            
            
            _backgroundLayer.fillColor = [UIColor clearColor].CGColor;
            [_filledCircleLayer removeFromSuperlayer];
    
            
            
            _glyphImageView.image = glyphImage;
            _glyphImageView.alpha = 1.0;
        }
    }
}

- (CAShapeLayer *)filledCircleLayer {
    CAShapeLayer *filledCircle = [CAShapeLayer layer];
    CGRect bounds = CGRectMake(5, 5, 2*[self ringRadius], 2*[self ringRadius]);
    UIBezierPath *maskLayerPath = [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:[self ringRadius]];
    filledCircle.path = maskLayerPath.CGPath;
    filledCircle.fillColor = [UIColor whiteColor].CGColor;
    return filledCircle;
}

- (void)ringAnimation {
    [self.layer insertSublayer:_filledCircleLayer above:_backgroundLayer];
    _backgroundLayer.fillColor = self.tintColor.CGColor;
    
    UIBezierPath *endShape = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(55, 55, 0, 0)
                                                        cornerRadius:[self ringRadius]];
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.toValue = (__bridge id _Nullable)(endShape.CGPath);
    animation.duration = 0.5;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    animation.fillMode = kCAFillModeBoth;
    animation.removedOnCompletion = NO;
    
    [_filledCircleLayer addAnimation:animation forKey:animation.keyPath];
}

- (UIImage *)getCompletionImage {
    UIImage *image;
    if (_isCareCard) {
        image = [UIImage imageNamed:@"star" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    }
    else {
        image = [UIImage imageNamed:@"checkmark" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    }
    return image;
}

- (UIImage *)getGlyphImage {
    UIImage *image;
        if (self.glyphType == OCKGlyphTypeCustom) {
        image = [self.glyphImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    } else {
        image = [[OCKGlyph glyphImageForType:self.glyphType] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return image;
}

- (CAShapeLayer *)getGlyphMaskLayer {
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect: _glyphImageView.bounds];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = path.CGPath;
    
    return maskLayer;
}

@end
