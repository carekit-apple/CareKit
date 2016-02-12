//
//  OCKCareCard.m
//  CareKit
//
//  Created by Umer Khan on 1/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKCareCard.h"
#import "OCKHelpers.h"


@implementation OCKCareCard {
    NSNumberFormatter *_numberFormatter;
}

+ (instancetype)new {
    OCKThrowMethodUnavailableException();
    return nil;
}

+ (instancetype)careCardWithAdherence:(CGFloat)adherence
                                 date:(NSString *)date {
    return [[OCKCareCard alloc] initWithAdherence:adherence
                                             date:date];
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithAdherence:(CGFloat)adherence
                             date:(NSString *)date {
    self = [super init];
    if (self) {
        _adherence = adherence;
        _date = [date copy];
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    __typeof(self) castObject = object;
    return ((self.adherence == castObject.adherence) &&
            OCKEqualObjects(self.date, castObject.date));
}


#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        OCK_DECODE_DOUBLE(aDecoder, adherence);
        OCK_DECODE_OBJ_CLASS(aDecoder, date, NSString);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    OCK_ENCODE_DOUBLE(aCoder, adherence);
    OCK_ENCODE_OBJ(aCoder, date);
}


#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKCareCard *card = [[[self class] allocWithZone:zone] init];
    card->_adherence = _adherence;
    card->_date = _date;
    return card;
}


#pragma mark - Helpers
- (NSString *)adherencePercentageString {
    if (!_numberFormatter) {
        _numberFormatter = [NSNumberFormatter new];
        _numberFormatter.numberStyle = NSNumberFormatterPercentStyle;
        _numberFormatter.maximumFractionDigits = 0;
    }
    return [_numberFormatter stringFromNumber:@(_adherence)];
}


@end
