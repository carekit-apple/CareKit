//
//  OCKLinePoint.m
//  CareKit
//
//  Created by Umer Khan on 1/20/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKLinePoint.h"
#import "OCKHelpers.h"


@implementation OCKLinePoint

+ (instancetype)new {
    OCKThrowMethodUnavailableException();
    return nil;
}

+ (instancetype)linePointWithValue:(CGFloat)value {
    return [[OCKLinePoint alloc] initWithValue:value];
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithValue:(CGFloat)value {
    self = [super init];
    if (self) {
        _value = value;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    __typeof(self) castObject = object;
    return ((self.value == castObject.value));
}


#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        OCK_DECODE_DOUBLE(aDecoder, value);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    OCK_ENCODE_DOUBLE(aCoder, value);
}


#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKLinePoint *point = [[[self class] allocWithZone:zone] init];
    point->_value = _value;
    return point;
}

@end
