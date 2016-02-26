//
//  OCKCircleView.h
//  CareKit
//
//  Created by Yuan Zhu on 2/25/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OCKRingView : UIView

// Default value is NO
@property (nonatomic) BOOL hideLabel;

// Default value is NO
@property (nonatomic) BOOL disableAnimation;

// Initial value is 0
@property (nonatomic) double value;

@end
