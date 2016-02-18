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

#define OCKRedColor() UIColorFromRGB(0xCF000F);
#define OCKGreenColor() UIColorFromRGB(0x2ECC71);
#define OCKBlueColor() UIColorFromRGB(0x4183D7);
#define OCKPurpleColor() UIColorFromRGB(0x9B59B6);
#define OCKPinkColor() UIColorFromRGB(0xDB0A5B);
#define OCKYellowColor() UIColorFromRGB(0xF7CA18);
#define OCKOrangeColor() UIColorFromRGB(0xF89406);
#define OCKGrayColor() UIColorFromRGB(0xBDC3C7);
