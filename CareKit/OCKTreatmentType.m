//
//  OCKMedicationType.m
//  CareKit
//
//  Created by Yuan Zhu on 1/21/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKTreatmentType.h"
#import "OCKHelpers.h"


@implementation OCKTreatmentType

- (instancetype)initWithName:(NSString *)name text:(NSString *)text {
    NSParameterAssert(name);
    self = [super init];
    if (self) {
        _name = name;
        _text = text;
        _identifier = [[NSUUID UUID] UUIDString];
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        OCK_DECODE_OBJ_CLASS(aDecoder, name, NSString);
        OCK_DECODE_OBJ_CLASS(aDecoder, text, NSString);
        OCK_DECODE_OBJ_CLASS(aDecoder, identifier, NSString);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    OCK_ENCODE_OBJ(coder, name);
    OCK_ENCODE_OBJ(coder, text);
    OCK_ENCODE_OBJ(coder, identifier);
}

- (BOOL)isEqual:(id)object {
    BOOL isClassMatch = ([self class] == [object class]);
    
    __typeof(self) castObject = object;
    return (isClassMatch &&
            OCKEqualObjects(self.name, castObject.name) &&
            OCKEqualObjects(self.identifier, castObject.identifier) &&
            OCKEqualObjects(self.text, castObject.text)
            );
}

@end

