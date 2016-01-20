//
//  ViewController.m
//  OCKTest
//
//  Created by Yuan Zhu on 1/19/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import "ViewController.h"
#import <CareKit/CareKit.h>

@interface ViewController ()

@end

@implementation ViewController {
    OCKMedication* _med;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _med = [OCKMedication new];
}

@end
