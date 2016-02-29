//
//  OCKColors.h
//  CareKit
//
//  Created by Umer Khan on 2/3/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import <UIKit/UIKit.h>

#define UIColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define OCKRedColor() UIColorFromRGB(0xEF445B);
#define OCKGreenColor() UIColorFromRGB(0x8DC63F);
#define OCKBlueColor() UIColorFromRGB(0x3EA1EE);
#define OCKPurpleColor() UIColorFromRGB(0x9B59B6);
#define OCKPinkColor() UIColorFromRGB(0xF26D7D);
#define OCKYellowColor() UIColorFromRGB(0xF1DF15);
#define OCKOrangeColor() UIColorFromRGB(0xF89406);
#define OCKGrayColor() UIColorFromRGB(0xBDC3C7);
