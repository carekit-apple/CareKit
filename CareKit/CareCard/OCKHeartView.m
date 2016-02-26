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
    UIView *_fillView;
    
    BOOL _isAnimating;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _animate = YES;
        self.maskImage = nil;
        [self prepareView];
    }
    return self;
}

- (void)prepareView {
    if (!_maskView) {
        _maskView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    }
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:_maskImage];
    imageView.frame = _maskView.frame;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [_maskView addSubview:imageView];
    
    self.maskView = _maskView;
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    if (!_fillView) {
        _fillView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.bounds), CGRectGetMaxY(self.bounds), CGRectGetMaxX(self.bounds), CGRectGetMaxY(self.bounds))];
        _fillView.backgroundColor = OCKPinkColor();
        [self addSubview:_fillView];
    }
}

- (void)animateFill {
    if (!_animation) {
        _animation = [CATransition animation];
        _animation.duration = 1.25;
        _animation.type = @"rippleEffect";
        _animation.delegate = self;
    }
    
//    if (!_isAnimating) {
//        [self.layer addAnimation:_animation forKey:nil];
//    }
    
    if (_animate) {
        [UIView animateWithDuration:1.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            _fillView.frame = CGRectMake(CGRectGetMinX(self.bounds), CGRectGetMaxY(self.bounds), CGRectGetMaxX(self.bounds), -_adherence * CGRectGetMaxY(self.bounds));
        } completion:^(BOOL finished) {
        }];
    } else {
        _fillView.frame = CGRectMake(CGRectGetMinX(self.bounds), CGRectGetMaxY(self.bounds), CGRectGetMaxX(self.bounds), -_adherence * CGRectGetMaxY(self.bounds));
    }
}

- (void)setAdherence:(CGFloat)adherence {
    _adherence = adherence;
    [self animateFill];
}

- (void)setMaskImage:(UIImage *)maskImage {
    _maskImage = maskImage;
    if (!_maskImage) {
        _maskImage = [UIImage imageNamed:@"heart" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    }
    
    [self prepareView];
}


#pragma mark - CAAnimationDelegate

- (void)animationDidStart:(CAAnimation *)anim {
    _isAnimating = YES;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    _isAnimating = NO;
}

@end
