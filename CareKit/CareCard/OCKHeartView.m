//
//  OCKHeartView.m
//  CareKit
//
//  Created by Umer Khan on 2/24/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKHeartView.h"
#import "OCKColors.h"
#import <QuartzCore/QuartzCore.h>


@implementation OCKHeartView {
    CATransition *_animation;
    UIView *_maskView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.maskImage = nil;
        [self prepareView];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGRect bottomRect = {CGRectGetMinX(self.bounds), CGRectGetMaxY(self.bounds), CGRectGetMaxX(self.bounds), -_adherence * CGRectGetMaxY(self.bounds)};
    UIColor *redColor = OCKPinkColor();
    [redColor setFill];
    UIRectFill(bottomRect);
    
    [self animateFill];
}

- (void)prepareView {
    if (!_maskView) {
        _maskView = [[UIView alloc] initWithFrame:self.frame];
    }
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:_maskImage];
    imageView.frame = _maskView.frame;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [_maskView addSubview:imageView];
    
    self.maskView = _maskView;
    self.clipsToBounds = YES;
    self.backgroundColor = OCKGrayColor();
}

- (void)animateFill {
     if (!_animation) {
         _animation = [CATransition animation];
         _animation.duration = 1.5;
         _animation.type = @"rippleEffect";
         _animation.startProgress = 0.25;
         _animation.endProgress = 0.99;
     }
    
     if (![self.layer animationForKey:@"ripple"]) {
         [self.layer addAnimation:_animation forKey:@"ripple"];
     }
}

- (void)setAdherence:(CGFloat)adherence {
    _adherence = adherence;
    [self setNeedsDisplay];
}

- (void)setMaskImage:(UIImage *)maskImage {
    _maskImage = maskImage;
    if (!_maskImage) {
        _maskImage = [UIImage imageNamed:@"heart" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    }
    
    [self prepareView];
}

@end
