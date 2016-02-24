//
//  OCKCareCardButton.m
//  CareKit
//
//  Created by Umer Khan on 2/22/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKCareCardButton.h"


static const CGFloat ButtonSize = 35.0;

@implementation OCKCareCardButton {
    CAShapeLayer *_circleLayer;
}

- (void)drawRect:(CGRect)rect {
    _circleLayer = [CAShapeLayer layer];
    _circleLayer.strokeColor = self.tintColor.CGColor;
    _circleLayer.fillColor = [UIColor clearColor].CGColor;
    [self updateFillColorForSelection:(self.isSelected || self.isHighlighted)];
    _circleLayer.lineWidth = 2.5;
    _circleLayer.path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, ButtonSize, ButtonSize)].CGPath;
    _circleLayer.fillRule = kCAFillRuleNonZero;
    [self.layer addSublayer:_circleLayer];
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
    if (selection) {
        _circleLayer.fillColor = self.tintColor.CGColor;
    } else {
        _circleLayer.fillColor = [UIColor whiteColor].CGColor;
    }
}

@end
