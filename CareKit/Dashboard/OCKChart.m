//
//  OCKChart.m
//  CareKit
//
//  Created by Umer Khan on 1/20/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKChart.h"
#import "OCKChart_Internal.h"
#import "OCKHelpers.h"
#import "OCKBarChart.h"


static NSMutableArray *OCKChartArray() {
    static dispatch_once_t onceToken;
    static NSMutableArray *chartArray = nil;
    dispatch_once(&onceToken, ^{
        chartArray = [@[[OCKBarChart class]] mutableCopy];
    });
    return chartArray;
}

BOOL OCKIsChartValid(OCKChart *chart) {
    BOOL isValid = [OCKChartArray() containsObject:[chart class]];
    return isValid;
}

static const CGFloat ChartHeight = 175.0;

@implementation OCKChart

- (void)setTintColor:(UIColor *)tintColor {
    if (!tintColor) {
        tintColor = [[[UIApplication sharedApplication] delegate] window].tintColor;
    }
    _tintColor = tintColor;
}

+ (void)animateView:(UIView *)view withDuration:(NSTimeInterval)duration {
}

- (CGFloat)height {
    return (_height > ChartHeight) ? _height : ChartHeight;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    __typeof(self) castObject = object;
    return (OCKEqualObjects(self.title, castObject.title) &&
            OCKEqualObjects(self.text, castObject.text) &&
            OCKEqualObjects(self.tintColor, castObject.tintColor) &&
            (self.height == castObject.height));
}

- (UIView *)chartView {
    OCKThrowMethodUnavailableException();
    return nil;
}


#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        OCK_DECODE_OBJ_CLASS(aDecoder, title, NSString);
        OCK_DECODE_OBJ_CLASS(aDecoder, text, NSString);
        OCK_DECODE_OBJ_CLASS(aDecoder, tintColor, UIColor);
        OCK_DECODE_DOUBLE(aDecoder, height);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    OCK_ENCODE_OBJ(aCoder, title);
    OCK_ENCODE_OBJ(aCoder, text);
    OCK_ENCODE_OBJ(aCoder, tintColor);
    OCK_ENCODE_DOUBLE(aCoder, height);
}


#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKChart *chart = [[[self class] allocWithZone:zone] init];
    chart.title = [_title copy];
    chart.text = [_text copy];
    chart.tintColor = _tintColor;
    chart.height = _height;
    return chart;
}

@end
