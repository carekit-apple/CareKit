/*
 Copyright (c) 2016, Apple Inc. All rights reserved.
 Copyright (c) 2016, WWT Asynchrony Labs. All rights reserved.
 
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


#import "OCKContact.h"
#import "OCKHelpers.h"


@implementation OCKContact

+ (instancetype)new {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithContactType:(OCKContactType)type
                               name:(NSString *)name
                           relation:(NSString *)relation
                          tintColor:(UIColor *)tintColor
                        phoneNumber:(CNPhoneNumber *)phoneNumber
                      messageNumber:(CNPhoneNumber *)messageNumber
                       emailAddress:(NSString *)emailAddress
                           monogram:(NSString *)monogram
                              image:(UIImage *)image {
	NSMutableArray *contactInfoItemsArray = [NSMutableArray array]; 
	if (phoneNumber) {
		[contactInfoItemsArray addObject:[[OCKContactInfo alloc] initWithType:OCKContactInfoTypePhone displayString:phoneNumber.stringValue actionURL:nil]];
	}
	
	if (messageNumber) {
		[contactInfoItemsArray addObject:[[OCKContactInfo alloc] initWithType:OCKContactInfoTypeMessage displayString:messageNumber.stringValue actionURL:nil]];
	}
	
	if (emailAddress.length) {
		[contactInfoItemsArray addObject:[[OCKContactInfo alloc] initWithType:OCKContactInfoTypeEmail displayString:emailAddress actionURL:nil]];
	}
    return [self initWithContactType:type name:name relation:relation contactInfoItems:contactInfoItemsArray tintColor:tintColor monogram:monogram image:image];
}

- (instancetype)initWithContactType:(OCKContactType)type
							   name:(NSString *)name
						   relation:(NSString *)relation
				   contactInfoItems:(NSArray<OCKContactInfo *> *)contactInfoItems
						  tintColor:(nullable UIColor *)tintColor
						   monogram:(null_unspecified NSString *)monogram
							  image:(nullable UIImage *)image {
	self = [super init];
	if (self) {
		_type = type;
		_name = [name copy];
		_relation = [relation copy];
		_contactInfoItems = [contactInfoItems copy];
		_tintColor = tintColor;
		self.monogram = [self clippedMonogramForString:monogram];
		_image = image;
	}
	return self;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            (self.type == castObject.type) &&
            OCKEqualObjects(self.name, castObject.name) &&
            OCKEqualObjects(self.relation, castObject.relation) &&
            OCKEqualObjects(self.tintColor, castObject.tintColor) &&
            OCKEqualObjects(self.contactInfoItems, castObject.contactInfoItems) &&
            OCKEqualObjects(self.monogram, castObject.monogram) &&
            OCKEqualObjects(self.image, castObject.image));
}


#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        OCK_DECODE_ENUM(aDecoder, type);
        OCK_DECODE_OBJ_CLASS(aDecoder, name, NSString);
        OCK_DECODE_OBJ_CLASS(aDecoder, relation, NSString);
        OCK_DECODE_OBJ_CLASS(aDecoder, tintColor, UIColor);
		OCK_DECODE_OBJ_CLASS(aDecoder, contactInfoItems, NSArray);
        OCK_DECODE_OBJ_CLASS(aDecoder, monogram, NSString);
        OCK_DECODE_IMAGE(aDecoder, image);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    OCK_ENCODE_ENUM(aCoder, type);
    OCK_ENCODE_OBJ(aCoder, name);
    OCK_ENCODE_OBJ(aCoder, relation);
    OCK_ENCODE_OBJ(aCoder, tintColor);
    OCK_ENCODE_OBJ(aCoder, contactInfoItems);
    OCK_ENCODE_OBJ(aCoder, monogram);
    OCK_ENCODE_IMAGE(aCoder, image);
}


#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKContact *contact = [[[self class] allocWithZone:zone] init];
    contact->_type = self.type;
    contact->_name = [self.name copy];
    contact->_relation = [self.relation copy];
    contact->_tintColor = self.tintColor;
    contact->_contactInfoItems = [self.contactInfoItems copy];
    contact->_monogram = [self.monogram copy];
    contact->_image = self.image;
    return contact;
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
