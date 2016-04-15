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


#import "OCKCareCardButton.h"
#import <QuartzCore/QuartzCore.h>


static const CGFloat ButtonSize = 30.0;

@implementation OCKCareCardButton {
    CAShapeLayer *_circleLayer;
}

- (void)drawRect:(CGRect)rect {
    if (!_circleLayer) {
        _circleLayer = [CAShapeLayer layer];
        _circleLayer.strokeColor = self.tintColor.CGColor;
        _circleLayer.fillColor = [UIColor clearColor].CGColor;
        [self updateFillColorForSelection:(self.isSelected || self.isHighlighted)];
        _circleLayer.lineWidth = 2.5;
        _circleLayer.path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, ButtonSize, ButtonSize)].CGPath;
        _circleLayer.fillRule = kCAFillRuleNonZero;
        [self.layer addSublayer:_circleLayer];
        
        [[UIColor clearColor] setFill];
        UIRectFill(_circleLayer.frame);
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    [self updateFillColorForSelection:highlighted];
    [super setHighlighted:highlighted];
}

- (void)setSelected:(BOOL)selected {
    [self updateFillColorForSelection:selected];
    [super setSelected:selected];
}

- (void)updateFillColorForSelection:(BOOL)selection {
    _circleLayer.fillColor = (selection) ? self.tintColor.CGColor : [UIColor whiteColor].CGColor;
}

@end
