//
//  Colors.h
//  CareKit
//
//  Created by Gavi Rawson on 7/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#ifndef Colors_h
#define Colors_h

#define HEXCOLOR(c) [UIColor colorWithRed:((c>>16)&0xFF)/255.0 \
green:((c>>8)&0xFF)/255.0 \
blue:(c&0xFF)/255.0 \
alpha:0xFF/255.0]

// Then define your constants
#define LightTextColor HEXCOLOR(0x95989A)
#define TextColor HEXCOLOR(0x46484E)
#define TintColor HEXCOLOR(0xFA7272)

#endif /* Colors_h */
