//
//  OCKHeartView.h
//  CareKit
//
//  Created by Umer Khan on 2/24/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


@interface OCKHeartView : UIView

@property (nonatomic) BOOL animate;
@property (nonatomic, null_resettable) UIImage *maskImage;
@property (nonatomic) CGFloat adherence;

@end
