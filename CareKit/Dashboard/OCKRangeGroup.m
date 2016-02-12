//
//  OCKRangeGroup.m
//  CareKit
//
//  Created by Umer Khan on 1/20/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKRangeGroup.h"
#import "OCKHelpers.h"


@implementation OCKRangeGroup

+ (instancetype)new {
    OCKThrowMethodUnavailableException();
    return nil;
}

+ (instancetype)rangeGroupWithRangePoints:(NSArray<OCKRangePoint *> *)points
                                    color:(UIColor *)color {
    return [[OCKRangeGroup alloc] initWithRangePoints:points
                                                color:color];
}

+ (instancetype)rangeGroupWithRangePoints:(NSArray<OCKRangePoint *> *)points {
    return [[OCKRangeGroup alloc] initWithRangePoints:points];
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithRangePoints:(NSArray <OCKRangePoint *> *)points
                              color:(UIColor *)color {
    self = [super init];
    if (self) {
        _points = [points copy];
        _color = color;
    }
    return self;
}

- (instancetype)initWithRangePoints:(NSArray <OCKRangePoint *> *)points {
    return [self initWithRangePoints:points
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
    OCKRangeGroup *group = [[[self class] allocWithZone:zone] init];
    group->_points = [_points copy];
    group->_color = _color;
    return group;
}

@end
