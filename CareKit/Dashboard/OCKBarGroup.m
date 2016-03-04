//
//  OCKBarGroup.m
//  CareKit
//
//  Created by Umer Khan on 3/2/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKBarGroup.h"
#import "OCKHelpers.h"


@implementation OCKBarGroup

+ (instancetype)new {
    OCKThrowMethodUnavailableException();
    return nil;
}

+ (instancetype)barGroupWithTitle:(NSString *)title
                           values:(NSArray<NSNumber *> *)values
                      valueLabels:(NSArray<NSString *> *)valueLabels
                        tintColor:(UIColor *)tintColor {
    return [[OCKBarGroup alloc] initWithTitle:title
                                       values:values
                                  valueLabels:valueLabels
                                    tintColor:tintColor];
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithTitle:(NSString *)title
                       values:(NSArray<NSNumber *> *)values
                  valueLabels:(NSArray<NSString *> *)valueLabels
                    tintColor:(UIColor *)tintColor {
    NSAssert((values.count == valueLabels.count), @"The number of values and value labels must be equal.");
    
    self = [super init];
    if (self) {
        _title = [title copy];
        _values = [values copy];
        _valueLabels = [valueLabels copy];
        _tintColor = tintColor;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    __typeof(self) castObject = object;
    return (OCKEqualObjects(self.title, castObject.title) &&
            OCKEqualObjects(self.values, castObject.values) &&
            OCKEqualObjects(self.valueLabels, castObject.valueLabels) &&
            OCKEqualObjects(self.tintColor, castObject.tintColor));
}


#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        OCK_DECODE_OBJ_CLASS(aDecoder, title, NSString);
        OCK_DECODE_OBJ_ARRAY(aDecoder, values, NSArray);
        OCK_DECODE_OBJ_ARRAY(aDecoder, valueLabels, NSArray);
        OCK_DECODE_OBJ_CLASS(aDecoder, tintColor, UIColor);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    OCK_ENCODE_OBJ(aCoder, title);
    OCK_ENCODE_OBJ(aCoder, values);
    OCK_ENCODE_OBJ(aCoder, valueLabels);
    OCK_ENCODE_OBJ(aCoder, tintColor);
}


#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKBarGroup *group = [[[self class] allocWithZone:zone] init];
    group->_title = [_title copy];
    group->_values = [_values copy];
    group->_valueLabels = [_valueLabels copy];
    group->_tintColor = _tintColor;
    return group;
}

@end
