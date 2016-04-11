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


#import "OCKHeartView.h"


@implementation OCKHeartView {
    UIView *_maskView;
    UIView *_fillView;
    UIImageView *_imageView;
    UIImageView *_maskImageView;
    UIImage *_maskImage;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _animationEnabled = YES;
        _value = 0;
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
    _fillView.backgroundColor = self.tintColor;
    [self addSubview:_fillView];
}

- (void)animateFill {
    if (self.animationEnabled) {
        [UIView animateWithDuration:1.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            _fillView.frame = CGRectMake(CGRectGetMinX(self.bounds), CGRectGetMaxY(self.bounds), CGRectGetMaxX(self.bounds), -_value * CGRectGetMaxY(self.bounds));
        } completion:^(BOOL finished) {
        }];
    } else {
        _fillView.frame = CGRectMake(CGRectGetMinX(self.bounds), CGRectGetMaxY(self.bounds), CGRectGetMaxX(self.bounds), -_value * CGRectGetMaxY(self.bounds));
    }
}

- (void)setValue:(double)value {
    if (_value != value) {
        _value = value;
        [self animateFill];
    }
}

- (void)setMaskImage:(UIImage *)maskImage {
    _maskImage = maskImage;
    [self prepareView];
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    [self prepareView];
}

@end
