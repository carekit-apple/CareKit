//
//  OCKPlot.m
//  CareKit
//
//  Created by Umer Khan on 1/20/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKLine.h"
#import "OCKHelpers.h"


@implementation OCKLine

+ (instancetype)new {
    OCKThrowMethodUnavailableException();
    return nil;
}

+ (instancetype)lineWithLinePoints:(NSArray<OCKLinePoint *> *)points
                             color:(UIColor *)color {
    return [[OCKLine alloc] initWithLinePoints:points
                                         color:color];
}

+ (instancetype)lineWithLinePoints:(NSArray<OCKLinePoint *> *)points {
    return [[OCKLine alloc] initWithLinePoints:points];
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithLinePoints:(NSArray<OCKLinePoint *> *)points
                             color:(UIColor *)color {
    self = [super init];
    if (self) {
        _points = [points copy];
        _color = color;
    }
    return self;
}

- (instancetype)initWithLinePoints:(NSArray<OCKLinePoint *> *)points {
    return [self initWithLinePoints:points
                              color:nil];
}

- (void)setColor:(UIColor *)color {
    if (!color) {
        _color = [[[UIApplication sharedApplication] delegate] window].tintColor;
    }
    _color = color;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    __typeof(self) castObject = object;
    return (OCKEqualObjects(self.points, castObject.points) &&
            OCKEqualObjects(self.color, castObject.color));
}


#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        OCK_DECODE_OBJ_ARRAY(aDecoder, points, NSArray);
        OCK_DECODE_OBJ_CLASS(aDecoder, color, UIColor);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    OCK_ENCODE_OBJ(aCoder, points);
    OCK_ENCODE_OBJ(aCoder, color);
}


#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKLine *line = [[[self class] allocWithZone:zone] init];
    line->_points = [_points copy];
    line->_color = _color;
    return line;
}


@end
