//
//  OCKHeartView.m
//  CareKit
//
//  Created by Umer Khan on 2/22/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKHeartView.h"


@implementation OCKHeartView

- (id)init {
    self = [super init];
    if (self) {
        self.layer.backgroundColor = [UIColor whiteColor].CGColor;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    self.layer.backgroundColor = [UIColor whiteColor].CGColor;
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    self.layer.backgroundColor = [UIColor whiteColor].CGColor;
    CGContextClearRect(contextRef, self.bounds);
    self.layer.backgroundColor = [UIColor whiteColor].CGColor;
    
    _heartLayer = [CAShapeLayer layer];
    [self.layer addSublayer:_heartLayer];
    self.layer.backgroundColor = [UIColor whiteColor].CGColor;

    _heartLayer.path = [self heartPathWithWidth:_width].CGPath;
    self.layer.backgroundColor = [UIColor whiteColor].CGColor;
    _heartLayer.fillColor = [UIColor clearColor].CGColor;
    self.layer.backgroundColor = [UIColor whiteColor].CGColor;
    _heartLayer.strokeColor = [UIColor redColor].CGColor;
    self.layer.backgroundColor = [UIColor whiteColor].CGColor;
    _heartLayer.lineWidth = 2.0;
    self.layer.backgroundColor = [UIColor whiteColor].CGColor;
}

- (UIBezierPath *)heartPathWithWidth:(CGFloat)width {
    CGFloat w = 160.0 / 2.5f;
    CGPoint center = CGPointMake(self.frame.size.width/2.f, self.frame.size.height/2.f);

    UIBezierPath *path = [UIBezierPath new];
    [path addArcWithCenter:CGPointMake(center.x - w/2.f, center.y - w/2.f)
                    radius:(w*sqrt(2.f)/2.f)
                startAngle:((M_PI * 135.f)/180)
                  endAngle:((M_PI * -45.f)/180)
                 clockwise:YES];
    [path addArcWithCenter:CGPointMake(center.x + w/2.f, center.y - w/2.f)
                    radius:(w*sqrt(2.f)/2.f)
                startAngle:((M_PI * -135.f)/180)
                  endAngle:((M_PI * 45.f)/180)
                 clockwise:YES];
    
    [path addLineToPoint:CGPointMake(center.x, center.y + w)];
    [path addLineToPoint:CGPointMake(center.x - w, center.y)];
    
    [path closePath];
    return path;
}

@end
