//
//  OCKHeartView.m
//  CareKit
//
//  Created by Umer Khan on 2/22/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKHeartView.h"


@implementation OCKHeartView

- (void)setMaskImage:(UIImage *)maskImage {
    _maskImage = maskImage;
    self.maskView = [[UIImageView alloc] initWithImage:_maskImage];
}

@end
