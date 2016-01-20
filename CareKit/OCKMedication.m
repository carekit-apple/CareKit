//
//  OCKMedication.m
//  CareKit
//
//  Created by Yuan Zhu on 1/19/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import "OCKMedication.h"

@implementation OCKMedication {
    ORKResult *_result;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _result = [ORKResult new];
    }
    return self;
}

@end
