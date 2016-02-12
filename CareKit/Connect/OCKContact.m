//
//  OCKContact.m
//  CareKit
//
//  Created by Umer Khan on 1/30/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKContact.h"
#import "OCKHelpers.h"


@implementation OCKContact

+ (instancetype)new {
    OCKThrowMethodUnavailableException();
    return nil;
}

+ (instancetype)contactWithContactType:(OCKContactType)type
                                  name:(NSString *)name
                              relation:(NSString *)relation
                           phoneNumber:(NSString *)phoneNumber
                         messageNumber:(NSString *)messageNumber
                          emailAddress:(NSString *)emailAddress {
    return [[OCKContact alloc] initWithContactType:type
                                              name:name
                                          relation:relation
                                       phoneNumber:phoneNumber
                                     messageNumber:messageNumber
                                      emailAddress:emailAddress];
}

+ (instancetype)contactWithContactType:(OCKContactType)type {
    return [OCKContact contactWithContactType:type
                                         name:nil
                                     relation:nil
                                  phoneNumber:nil
                                messageNumber:nil
                                 emailAddress:nil];
}

- (instancetype)initWithContactType:(OCKContactType)type {
    return [self initWithContactType:type
                                name:nil
                            relation:nil
                         phoneNumber:nil
                       messageNumber:nil
                        emailAddress:nil];
}

- (instancetype)initWithContactType:(OCKContactType)type
                               name:(NSString *)name
                           relation:(NSString *)relation
                        phoneNumber:(NSString *)phoneNumber
                      messageNumber:(NSString *)messageNumber
                       emailAddress:(NSString *)emailAddress {
    self = [super init];
    if (self) {
        _type = type;
        _name = [name copy];
        _relation = [relation copy];
        _phoneNumber = [phoneNumber copy];
        _messageNumber = [messageNumber copy];
        _emailAddress = [emailAddress copy];
    }
    return self;
}

- (void)setTintColor:(UIColor *)tintColor {
    _tintColor = (tintColor) ? tintColor : [UIColor blueColor];
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            (self.type == castObject.type) &&
            OCKEqualObjects(self.name, castObject.name) &&
            OCKEqualObjects(self.relation, castObject.relation) &&
            OCKEqualObjects(self.phoneNumber, castObject.phoneNumber) &&
            OCKEqualObjects(self.messageNumber, castObject.messageNumber) &&
            OCKEqualObjects(self.emailAddress, castObject.emailAddress));
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
        OCK_DECODE_OBJ_CLASS(aDecoder, phoneNumber, NSString);
        OCK_DECODE_OBJ_CLASS(aDecoder, messageNumber, NSString);
        OCK_DECODE_OBJ_CLASS(aDecoder, emailAddress, NSString);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    OCK_ENCODE_ENUM(aCoder, type);
    OCK_ENCODE_OBJ(aCoder, name);
    OCK_ENCODE_OBJ(aCoder, relation);
    OCK_ENCODE_OBJ(aCoder, phoneNumber);
    OCK_ENCODE_OBJ(aCoder, messageNumber);
    OCK_ENCODE_OBJ(aCoder, emailAddress);
}


#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKContact *contact = [[[self class] allocWithZone:zone] init];
    contact->_type = self.type;
    contact->_name = [self.name copy];
    contact->_relation = [self.relation copy];
    contact->_phoneNumber = [self.phoneNumber copy];
    contact->_messageNumber = [self.messageNumber copy];
    contact->_emailAddress = [self.emailAddress copy];
    return contact;
}

@end
