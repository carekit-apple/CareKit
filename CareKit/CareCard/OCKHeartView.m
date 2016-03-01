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
    UIView *_maskView;
    UIView *_fillView;
    UIImageView *_imageView;
    UIImageView *_maskImageView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _animate = YES;
        _adherence = 0;
        self.maskImage = nil;
    }
    return self;
}

- (void)prepareView {
    [_maskView removeFromSuperview];
    [_fillView removeFromSuperview];
    [_imageView removeFromSuperview];
    [_maskImageView removeFromSuperview];
    
    _maskView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    _maskImageView = [[UIImageView alloc] initWithImage:_maskImage];
    _maskImageView.frame = _maskView.frame;
    _maskImageView.contentMode = UIViewContentModeScaleAspectFit;
    [_maskView addSubview:_maskImageView];
    self.maskView = _maskView;
    self.clipsToBounds = YES;
    
    _imageView = [[UIImageView alloc] initWithImage:_maskImage];
    _imageView.frame = _maskView.frame;
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self insertSubview:_imageView belowSubview:_maskView];
    
    _fillView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.bounds), CGRectGetMaxY(self.bounds), CGRectGetMaxX(self.bounds), CGRectGetMaxY(self.bounds))];
    _fillView.backgroundColor = OCKRedColor();
    [self addSubview:_fillView];
}

- (void)animateFill {
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
    if (_adherence != adherence) {
        _adherence = adherence;
        [self animateFill];
    }
}

- (void)setMaskImage:(UIImage *)maskImage {
    _maskImage = maskImage;
    if (!_maskImage) {
        _maskImage = [UIImage imageNamed:@"heart" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    }

    [self prepareView];
}



@end
