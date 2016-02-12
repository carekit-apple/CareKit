//
//  OCKTreatment.m
//  CareKit
//
//  Created by Umer Khan on 1/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKTreatment.h"
#import "OCKTreatment_Internal.h"
#import "OCKHelpers.h"


@implementation OCKTreatment

+ (instancetype)new {
    OCKThrowMethodUnavailableException();
    return nil;
}

+ (instancetype)treatmentWithTitle:(NSString *)title
                              text:(NSString *)text
                         frequency:(NSInteger)frequency {
    return [[OCKTreatment alloc] initWithTitle:title
                                          text:text
                                     frequency:frequency];
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithTitle:(NSString *)title
                         text:(NSString *)text
                    frequency:(NSInteger)frequency {
    self = [super init];
    if (self) {
        _title = [title copy];
        _text = [text copy];
        _frequency = frequency;
        _completed = 0;
    }
    return self;
}

- (void)setTintColor:(UIColor *)tintColor {
    if (!tintColor) {
        tintColor = [UIColor grayColor];
    }
    _tintColor = tintColor;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    __typeof(self) castObject = object;
    return (OCKEqualObjects(self.title, castObject.title) &&
            OCKEqualObjects(self.text, castObject.text) &&
            (self.frequency == castObject.frequency) &&
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
        OCK_DECODE_OBJ_CLASS(aDecoder, text, NSString);
        OCK_DECODE_INTEGER(aDecoder, frequency);
        OCK_DECODE_OBJ_CLASS(aDecoder, tintColor, UIColor);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    OCK_ENCODE_OBJ(aCoder, title);
    OCK_ENCODE_OBJ(aCoder, text);
    OCK_ENCODE_INTEGER(aCoder, frequency);
    OCK_ENCODE_OBJ(aCoder, tintColor);
}


#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKTreatment *treatment = [[[self class] allocWithZone:zone] init];
    treatment.title = [_title copy];
    treatment.text = [_text copy];
    treatment.frequency = _frequency;
    treatment.tintColor = _tintColor;
    return treatment;
}

@end
