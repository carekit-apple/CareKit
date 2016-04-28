/*
 Copyright (c) 2016, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "OCKBarSeries.h"
#import "OCKHelpers.h"


@implementation OCKBarSeries

+ (instancetype)new {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithTitle:(NSString *)title
                       values:(NSArray<NSNumber *> *)values
                  valueLabels:(NSArray<NSString *> *)valueLabels
                    tintColor:(UIColor *)tintColor {
    NSAssert((values.count == valueLabels.count), @"The number of values and value labels must be equal.");
    
    NSAssert((values.count > 0 && valueLabels.count > 0), @"The number of values and value labels must be greater than 0.");
    
    self = [super init];
    if (self) {
        _title = [title copy];
        _values = OCKArrayCopyObjects(values);
        _valueLabels = OCKArrayCopyObjects(valueLabels);
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
    OCKBarSeries *series = [[[self class] allocWithZone:zone] init];
    series->_title = [_title copy];
    series->_values = OCKArrayCopyObjects(_values);
    series->_valueLabels = OCKArrayCopyObjects(_valueLabels);
    series->_tintColor = _tintColor;
    return series;
}

@end
