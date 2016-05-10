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


#import <CareKit/CareKit.h>
#import <ContactsUI/ContactsUI.h>


NS_ASSUME_NONNULL_BEGIN

/**
 An enumeration of the types of contacts available.
 */
OCK_ENUM_AVAILABLE
typedef NS_ENUM(NSInteger, OCKContactType) {
    /**
     A care team contact such as a physician or nurse.
     */
    OCKContactTypeCareTeam = 0,
    
    /**
     A personal contact such as a friend or family member.
     */
    OCKContactTypePersonal
};


/**
 The `OCKContact` class is an object that represents a care contact for the `OCKConnectViewController`.
 */
OCK_CLASS_AVAILABLE
@interface OCKContact : NSObject <NSSecureCoding, NSCopying>

- (instancetype)init NS_UNAVAILABLE;

/**
 Returns an initialized contact using the specified values.
 
 @param type                The contact type.
 @param name                The contact name.
 @param relation            The relationship to the contact.
 @param tintColor           The contact tint color.
 @param phoneNumber         The contact phone number.
 @param messageNumber       The contact message number.
 @param emailAddress        The contact email address.
 @param monogram            The contact monogram.
 @param image               The contact image.
 
 @return An initialized contact object.
 */
- (instancetype)initWithContactType:(OCKContactType)type
                               name:(NSString *)name
                           relation:(NSString *)relation
                          tintColor:(nullable UIColor *)tintColor
                        phoneNumber:(nullable CNPhoneNumber *)phoneNumber
                      messageNumber:(nullable CNPhoneNumber *)messageNumber
                       emailAddress:(nullable NSString *)emailAddress
                           monogram:(NSString *)monogram
                              image:(nullable UIImage *)image;

/**
 The contact type.
 This also determines the grouping of the contact in the table view.
 
 See the `OCKContactType` enum.
 */
@property (nonatomic, readonly) OCKContactType type;

/**
 A string indicating the name for a contact.
 */
@property (nonatomic, readonly) NSString *name;

/**
 A string indicating the relationship to a contact.
 */
@property (nonatomic, readonly) NSString *relation;

/**
 The tint color for a contact.
 
 If the value is not specified, the app's tint color is used.
 */
@property (nonatomic, readonly, nullable) UIColor *tintColor;

/**
 A CNPhoneNumber indicating the phone number for a contact.
 
 If a phone number is not specified, the phone table view row will
 not be visible for the contact.
 */
@property (nonatomic, readonly, nullable) CNPhoneNumber *phoneNumber;

/**
 A CNPhoneNumber indicating the message number for a contact.
 
 If a message number is not specified, the message table view row will
 not be visible for the contact.
 */
@property (nonatomic, readonly, nullable) CNPhoneNumber *messageNumber;

/**
 A string indicating the email address for a contact.
 
 If an email address is not specified, the email table view row will
 not be visible for the contact.
 */
@property (nonatomic, readonly, nullable) NSString *emailAddress;

/**
 A string indicating the monogram for a contact.
 
 The monogram will be clipped to two glyphs.
 */
@property (nonatomic, readonly) NSString *monogram;

/**
 An image for a contact.
 
 If an image is not provided, a monogram will be used for the contact.
 An image can be set after a contact object has been created. If an image
 is available, it will be displayed instead of the monogram.
 */
@property (nonatomic, nullable) UIImage *image;

@end

NS_ASSUME_NONNULL_END
