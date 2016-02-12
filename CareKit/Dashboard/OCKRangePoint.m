//
//  OCKRangePoint.m
//  CareKit
//
//  Created by Umer Khan on 1/20/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKRangePoint.h"
#import "OCKHelpers.h"


@implementation OCKRangePoint

+ (instancetype)new {
    OCKThrowMethodUnavailableException();
    return nil;
}

+ (instancetype)rangePointWithMinimumValue:(CGFloat)minimumValue
                              maximumValue:(CGFloat)maximumValue {
    return [[OCKRangePoint alloc] initWithMinimumValue:minimumValue
                                          maximumValue:maximumValue];
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithMinimumValue:(CGFloat)minimumValue
                        maximumValue:(CGFloat)maximumValue {
    self = [super init];
    if (self) {
        _minimumValue = minimumValue;
        _maximumValue = maximumValue;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    __typeof(self) castObject = object;
    return ((self.minimumValue == castObject.minimumValue) &&
            (self.maximumValue == castObject.maximumValue));
}


#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        OCK_DECODE_DOUBLE(aDecoder, minimumValue);
        OCK_DECODE_DOUBLE(aDecoder, maximumValue);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    OCK_ENCODE_DOUBLE(aCoder, minimumValue);
    OCK_ENCODE_DOUBLE(aCoder, maximumValue);
}


#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKRangePoint *point = [[[self class] allocWithZone:zone] init];
    point->_minimumValue = _minimumValue;
    point->_maximumValue = _maximumValue;
    return point;
}

@end
