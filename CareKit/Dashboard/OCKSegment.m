//
//  OCKSegment.m
//  CareKit
//
//  Created by Umer Khan on 1/20/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKSegment.h"
#import "OCKHelpers.h"


@implementation OCKSegment

+ (instancetype)new {
    OCKThrowMethodUnavailableException();
    return nil;
}

+ (instancetype)segmentWithValue:(CGFloat)value
                           color:(UIColor *)color
                           title:(NSString *)title {
    return [[OCKSegment alloc] initWithValue:value
                                       color:color
                                       title:title];
}

+ (instancetype)segmentWithValue:(CGFloat)value {
    return [[OCKSegment alloc] initWithValue:value];
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithValue:(CGFloat)value
                        color:(UIColor *)color
                        title:(NSString *)title {
    self = [super init];
    if (self) {
        _value = value;
        _color = color;
        _title = [title copy];
    }
    return self;
}

- (instancetype)initWithValue:(CGFloat)value {
    return [self initWithValue:value
                         color:nil
                         title:nil];
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
    return ((self.value == castObject.value) &&
            OCKEqualObjects(self.title, castObject.title) &&
            OCKEqualObjects(self.color, castObject.color));
}


#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        OCK_DECODE_DOUBLE(aDecoder, value);
        OCK_DECODE_OBJ_CLASS(aDecoder, title, NSString);
        OCK_DECODE_OBJ_CLASS(aDecoder, color, UIColor);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    OCK_ENCODE_DOUBLE(aCoder, value);
    OCK_ENCODE_OBJ(aCoder, title);
    OCK_ENCODE_OBJ(aCoder, color);
}


#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKSegment *segment = [[[self class] allocWithZone:zone] init];
    segment->_value = _value;
    segment->_title = [_title copy];
    segment->_color = _color;
    return segment;
}

@end
