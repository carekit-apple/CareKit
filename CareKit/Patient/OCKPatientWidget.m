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


#import "OCKPatientWidget.h"
#import "OCKPatientWidget_Internal.h"
#import "OCKHelpers.h"


@implementation OCKPatientWidget

+ (instancetype)new {
    OCKThrowMethodUnavailableException();
    return nil;
}

+ (OCKPatientWidget *)defaultWidgetWithActivityIdentifier:(NSString *)activityIdentifier
                                                tintColor:(UIColor *)tintColor {
    return [[OCKPatientWidget alloc] initWithWidgetType:OCKPatientWidgetTypeDefault
                              primaryActivityIdentifier:activityIdentifier
                            secondaryActivityIdentifier:nil
                                            primaryText:nil
                                          secondaryText:nil
                                           primaryImage:nil
                                         secondaryImage:nil
                                                  value:nil
                                              tintColor:tintColor];
    
}

+ (OCKPatientWidget *)defaultWidgetWithTitle:(NSString *)title
                                        text:(NSString *)text
                                   tintColor:(UIColor *)tintColor {
    return [[OCKPatientWidget alloc] initWithWidgetType:OCKPatientWidgetTypeDefault
                              primaryActivityIdentifier:nil
                            secondaryActivityIdentifier:nil
                                            primaryText:title
                                          secondaryText:text
                                           primaryImage:nil
                                         secondaryImage:nil
                                                  value:nil
                                              tintColor:tintColor];
}

+ (OCKPatientWidget *)stackedWidgetWithPrimaryText:(NSString *)primaryText
                                       primaryIcon:(UIImage *)primaryIcon
                                     secondaryText:(NSString *)secondaryText
                                     secondaryIcon:(UIImage *)secondaryIcon
                                         tintColor:(UIColor *)tintColor {
    return [[OCKPatientWidget alloc] initWithWidgetType:OCKPatientWidgetTypeStacked
                              primaryActivityIdentifier:nil
                            secondaryActivityIdentifier:nil
                                            primaryText:primaryText
                                          secondaryText:secondaryText
                                           primaryImage:primaryIcon
                                         secondaryImage:secondaryIcon
                                                  value:nil
                                              tintColor:tintColor];
}

+ (OCKPatientWidget *)imageWidgetWithTitle:(NSString *)title
                                     image:(UIImage *)image
                                 tintColor:(UIColor *)tintColor {
    return [[OCKPatientWidget alloc] initWithWidgetType:OCKPatientWidgetTypeImage
                              primaryActivityIdentifier:nil
                            secondaryActivityIdentifier:nil
                                            primaryText:title
                                          secondaryText:nil
                                           primaryImage:image
                                         secondaryImage:nil
                                                  value:nil
                                              tintColor:tintColor];
}

+ (OCKPatientWidget *)badgeWidgetWithTitle:(NSString *)title
                                     value:(NSNumber *)value
                                 tintColor:(UIColor *)tintColor {
    return [[OCKPatientWidget alloc] initWithWidgetType:OCKPatientWidgetTypeBadge
                              primaryActivityIdentifier:nil
                            secondaryActivityIdentifier:nil
                                            primaryText:title
                                          secondaryText:nil
                                           primaryImage:nil
                                         secondaryImage:nil
                                                  value:value
                                              tintColor:tintColor];
}

- (instancetype)initWithWidgetType:(OCKPatientWidgetType)type
         primaryActivityIdentifier:(NSString *)primaryIdentifier
       secondaryActivityIdentifier:(NSString *)secondaryIdentifier
                       primaryText:(NSString *)primaryText
                     secondaryText:(NSString *)secondaryText
                      primaryImage:(UIImage *)primaryImage
                    secondaryImage:(UIImage *)secondaryImage
                             value:(NSNumber *)value
                         tintColor:(UIColor *)tintColor {
    self = [super init];
    if (self) {
        _type = type;
        _primaryIdentifier = [primaryIdentifier copy];
        _secondaryIdentifier = [secondaryIdentifier copy];
        _primaryText = [primaryText copy];
        _secondaryText = [secondaryText copy];
        _primaryImage = primaryImage;
        _secondaryImage = secondaryImage;
        _value = value;
        _tintColor = tintColor;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            self.type == castObject.type &&
            OCKEqualObjects(self.primaryIdentifier, castObject.primaryIdentifier) &&
            OCKEqualObjects(self.secondaryIdentifier, castObject.secondaryIdentifier) &&
            OCKEqualObjects(self.primaryText, castObject.primaryText) &&
            OCKEqualObjects(self.secondaryText, castObject.secondaryText) &&
            OCKEqualObjects(self.primaryImage, castObject.primaryImage) &&
            OCKEqualObjects(self.secondaryImage, castObject.secondaryImage) &&
            OCKEqualObjects(self.value, castObject.value) &&
            OCKEqualObjects(self.tintColor, castObject.tintColor));
}


#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        OCK_DECODE_ENUM(aDecoder, type);
        OCK_DECODE_OBJ_CLASS(aDecoder, primaryIdentifier, NSString);
        OCK_DECODE_OBJ_CLASS(aDecoder, secondaryIdentifier, NSString);
        OCK_DECODE_OBJ_CLASS(aDecoder, primaryText, NSString);
        OCK_DECODE_OBJ_CLASS(aDecoder, secondaryText, NSString);
        OCK_DECODE_IMAGE(aDecoder, primaryImage);
        OCK_DECODE_IMAGE(aDecoder, secondaryImage);
        OCK_DECODE_OBJ_CLASS(aDecoder, value, NSNumber);
        OCK_DECODE_OBJ_CLASS(aDecoder, tintColor, UIColor);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    OCK_ENCODE_ENUM(aCoder, type);
    OCK_ENCODE_OBJ(aCoder, primaryIdentifier);
    OCK_ENCODE_OBJ(aCoder, secondaryIdentifier);
    OCK_ENCODE_OBJ(aCoder, primaryText);
    OCK_ENCODE_OBJ(aCoder, secondaryText);
    OCK_ENCODE_IMAGE(aCoder, primaryImage);
    OCK_ENCODE_IMAGE(aCoder, secondaryImage);
    OCK_ENCODE_OBJ(aCoder, value);
    OCK_ENCODE_OBJ(aCoder, tintColor);
}


#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKPatientWidget *widget = [[[self class] allocWithZone:zone] init];
    widget->_type = self.type;
    widget->_primaryIdentifier = [self.primaryIdentifier copy];
    widget->_secondaryIdentifier = [self.secondaryIdentifier copy];
    widget->_primaryText = [self.primaryText copy];
    widget->_secondaryText = [self.secondaryText copy];
    widget->_primaryImage = self.primaryImage;
    widget->_secondaryImage = self.secondaryImage;
    widget->_value = self.value;
    widget->_tintColor = self.tintColor;
    return widget;
}

@end
