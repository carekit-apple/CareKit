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


#import "OCKRingItem.h"
#import "OCKHelpers.h"


@implementation OCKRingItem

- (instancetype)initWithTitle:(NSString *)title
                         text:(NSString *)text
                    tintColor:(UIColor *)tintColor
                        value:(double)value
                    glyphType:(OCKGlyphType)glyphType
                glyphFilename:(NSString *)glyphFilename {
    NSParameterAssert(value >= 0.0 && value <= 1.0);
    
    self = [super init];
    if (self) {
        self.title = [title copy];
        self.text = [text copy];
        self.tintColor = tintColor;
        _value = value;
        _glyphType = glyphType;
        _glyphFilename = [glyphFilename copy];
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            self.value == castObject.value &&
            self.glyphType == castObject.glyphType &&
            OCKEqualObjects(self.glyphFilename, castObject.glyphFilename));
}


#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        OCK_DECODE_DOUBLE(aDecoder, value);
        OCK_DECODE_ENUM(aDecoder, glyphType);
        OCK_DECODE_OBJ_CLASS(aDecoder, glyphFilename, NSString);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    OCK_ENCODE_DOUBLE(aCoder, value);
    OCK_ENCODE_ENUM(aCoder, glyphType);
    OCK_ENCODE_OBJ(aCoder, glyphFilename);
}


#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKRingItem *item = [super copyWithZone:zone];
    item->_value = self.value;
    item->_glyphType = self.glyphType;
    item->_glyphFilename = [self.glyphFilename copy];
    return item;
}

@end
