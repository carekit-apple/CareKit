/*
 Copyright (c) 2017, Apple Inc. All rights reserved.
 
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


#import "OCKPatient.h"
#import "OCKHelpers.h"


@implementation OCKPatient

+ (instancetype)new {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithIdentifier:(NSString *)identifier
                     carePlanStore:(OCKCarePlanStore *)store
                              name:(NSString *)name
                        detailInfo:(NSString *)detailInfo
                  careTeamContacts:(NSArray<OCKContact *> *)careTeamContacts
                         tintColor:(UIColor *)tintColor
                          monogram:(NSString *)monogram
                             image:(UIImage *)image
                        categories:(NSArray<NSString *> *)categories
                          userInfo:(NSDictionary *)userInfo {
    self = [super init];
    if (self) {
        _identifier = [identifier copy];
        _store = store;
        _name = [name copy];
        _detailInfo = [detailInfo copy];
        _careTeamContacts = OCKArrayCopyObjects(careTeamContacts);
        _tintColor = tintColor;
        self.monogram = [self clippedMonogramForString:monogram];
        _image = image;
        _categories = OCKArrayCopyObjects(categories);
        _userInfo = userInfo;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            OCKEqualObjects(self.identifier, castObject.identifier) &&
            OCKEqualObjects(self.store, castObject.store) &&
            OCKEqualObjects(self.name, castObject.name) &&
            OCKEqualObjects(self.detailInfo, castObject.detailInfo) &&
            OCKEqualObjects(self.careTeamContacts, castObject.careTeamContacts) &&
            OCKEqualObjects(self.tintColor, castObject.tintColor) &&
            OCKEqualObjects(self.monogram, castObject.monogram) &&
            OCKEqualObjects(self.image, castObject.image) &&
            OCKEqualObjects(self.categories, castObject.categories) &&
            OCKEqualObjects(self.userInfo, castObject.userInfo));
}


#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        OCK_DECODE_OBJ_CLASS(aDecoder, identifier, NSString);
        OCK_DECODE_OBJ_CLASS(aDecoder, store, OCKCarePlanStore);
        OCK_DECODE_OBJ_CLASS(aDecoder, name, NSString);
        OCK_DECODE_OBJ_CLASS(aDecoder, detailInfo, NSString);
        OCK_DECODE_OBJ_ARRAY(aDecoder, careTeamContacts, NSArray);
        OCK_DECODE_OBJ_CLASS(aDecoder, tintColor, UIColor);
        OCK_DECODE_OBJ_CLASS(aDecoder, monogram, NSString);
        OCK_DECODE_IMAGE(aDecoder, image);
        OCK_DECODE_OBJ_CLASS(aDecoder, categories, NSArray);
        OCK_DECODE_OBJ_CLASS(aDecoder, userInfo, NSDictionary);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    OCK_ENCODE_OBJ(aCoder, identifier);
    OCK_ENCODE_OBJ(aCoder, store);
    OCK_ENCODE_OBJ(aCoder, name);
    OCK_ENCODE_OBJ(aCoder, detailInfo);
    OCK_ENCODE_OBJ(aCoder, careTeamContacts);
    OCK_ENCODE_OBJ(aCoder, tintColor);
    OCK_ENCODE_OBJ(aCoder, monogram);
    OCK_ENCODE_IMAGE(aCoder, image);
    OCK_ENCODE_OBJ(aCoder, categories);
    OCK_ENCODE_OBJ(aCoder, userInfo);
}


#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKPatient *patient = [[[self class] allocWithZone:zone] init];
    patient->_identifier = [self.identifier copy];
    patient->_store = self.store;
    patient->_name = [self.name copy];
    patient->_detailInfo = [self.detailInfo copy];
    patient->_careTeamContacts = [self.careTeamContacts copy];
    patient->_tintColor = self.tintColor;
    patient->_monogram = [self.monogram copy];
    patient->_image = self.image;
    patient->_categories = [self.categories copy];
    patient->_userInfo = self.userInfo;
    return patient;
}


#pragma mark - Monogram

- (NSString *)clippedMonogramForString:(NSString *)string {
    NSRange stringRange = {0, MIN([string length], 2)};
    stringRange = [string rangeOfComposedCharacterSequencesForRange:stringRange];
    return [string substringWithRange:stringRange];
}

- (void)setMonogram:(NSString *)monogram {
    if (!monogram) {
        monogram = [self generateMonogram:_name];
    }
    _monogram = [monogram copy];
}

- (NSString *)generateMonogram:(NSString *)name {
    NSAssert((name != nil), @"A name must be supplied");
    NSAssert((name.length > 0), @"A name must have > 0 chars");
    
    NSMutableArray *candidateWords = [NSMutableArray arrayWithArray:[name componentsSeparatedByString:@" "]];
    
    NSString *first = @"";
    NSString *last = @"";
    
    if (candidateWords.count > 0) {
        first = [NSString stringWithFormat:@"%c", [candidateWords[0] characterAtIndex:0]];
        if (candidateWords.count > 1) {
            last = [NSString stringWithFormat:@"%c", [candidateWords[candidateWords.count-1] characterAtIndex:0]];
        }
        
    } else {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"name %@ has no candidates to generate a monogram", name] userInfo:nil];
    }
    
    candidateWords = nil;
    
    return [NSString stringWithFormat:@"%@%@",[first uppercaseString],[last uppercaseString]];
}

@end
