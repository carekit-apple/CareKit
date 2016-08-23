/*
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


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "OCKDefines.h"


NS_ASSUME_NONNULL_BEGIN

/**
 An enumeration of the types of contact info items available.
 */
OCK_ENUM_AVAILABLE
typedef NS_ENUM(NSInteger, OCKContactInfoType) {
	/**
	 An audio phone contact info.
	 */
	OCKContactInfoTypePhone = 0,
	
	/**
	 A text message contact info.
	 */
	OCKContactInfoTypeMessage,
	
	/**
	 An email contact info.
	 */
	OCKContactInfoTypeEmail,
	
	/**
	 A video call contact info.
	 */
	OCKContactInfoTypeVideo
};

/**
 The `OCKContactInfo` class is an object that represents a specific way to contact an `OCKContact`.
 */
OCK_CLASS_AVAILABLE
@interface OCKContactInfo : NSObject <NSSecureCoding, NSCopying>

/**
 The contact info type.
 This determines the default icon displayed, as well as the default label and action, if none are specified.
 
 See the `OCKContactInfoType` enum.
 */
@property (nonatomic, readonly) OCKContactInfoType type;

/**
 The string that will be used as the primary identification for the contact info item.
 */
@property (nonatomic, readonly) NSString *displayString;

/**
 The action URL which will be called when the contact items is selected. If nil, then the type property will be used to determine a default action.
 */
@property (nonatomic, readonly, nullable) NSURL *actionURL;

/**
 The label for the contact info, which is the textual representation of the type of contact info. If this is not set explicitly it will default to a value based on the type.
 */
@property (nonatomic, readonly) NSString *label;

/**
 The label for the contact info, which is the visual representation of the type of contact info. If this is not set explicitly it will default to a value based on the type.
 */
@property (nonatomic, readonly, nullable) UIImage *icon;

- (instancetype)init NS_UNAVAILABLE;

/**
 Creates a new contact information item. The label and icon will be set to the default for the given contact type.
 
 @param type            The type of contact info, which will define the display icon and the default action if no actionURL is specified.
 @param displayString   The string that will be displayed to the user to represent the contact item.
 @param actionURL       The action to take to initiate the connection. For example "sms:1-314-555-1234", "tel:1-314-555-1234", "facetime://user@example.com"
 
 @return An instance of the contact info.
 */
- (instancetype)initWithType:(OCKContactInfoType)type displayString:(NSString *)displayString actionURL:(nullable NSURL *)actionURL;

/**
 Creates a new contact information item. The icon will be set to the default for the given contact type.
 
 @param type            The type of contact info, which will define the display icon and the default action if no actionURL is specified.
 @param displayString   The string that will be displayed to the user to represent the contact item.
 @param actionURL       The action to take to initiate the connection. For example "sms:1-314-555-1234", "tel:1-314-555-1234", "facetime://user@example.com"
 @param label           The label of the contact info.
 
 @return An instance of the contact info.
 */
- (instancetype)initWithType:(OCKContactInfoType)type displayString:(NSString *)displayString actionURL:(nullable NSURL *)actionURL label:(NSString *)label;

/**
 Creates a new contact information item.
 
 @param type            The type of contact info, which will define the display icon and the default action if no actionURL is specified.
 @param displayString   The string that will be displayed to the user to represent the contact item.
 @param actionURL       The action to take to initiate the connection. For example "sms:1-314-555-1234", "tel:1-314-555-1234", "facetime://user@example.com"
 @param label           The label of the contact info.
 @param icon            The icon which represents the contact type. The contact tint color will be applied to this icon, which will be converted if needed to UIImageRenderingModeAlwaysTemplate.
 
 @return An instance of the contact info.
 */
- (instancetype)initWithType:(OCKContactInfoType)type displayString:(NSString *)displayString actionURL:(nullable NSURL *)actionURL label:(NSString *)label icon:(nullable UIImage *)icon;

/**
 Creates a new contact info with an sms: action URL.
 
 @param smsNumber       The mobile phone number.
 */
+ (OCKContactInfo *)sms:(NSString *)smsNumber;

/**
 Creates a new contact info with an tel: action URL.
 
 @param phoneNumber     The phone number.
 */
+ (OCKContactInfo *)phone:(NSString *)phoneNumber;

/**
 Creates a new contact info with a mailto: action URL.
 
 @param emailAddress    The email address.
 */
+ (OCKContactInfo *)email:(NSString *)emailAddress;

/**
 Creates a new contact info with a facetime: action URL.
 
 @param emailAddressOrRawPhoneNumber   The email address or unformatted phone number.
 @param displayString                  The display string to represent the contact info. If nil then defaults to the emailAddressOrRawPhoneNumber.
 */
+ (OCKContactInfo *)facetimeVideo:(NSString *)emailAddressOrRawPhoneNumber displayString:(nullable NSString *)displayString;

/**
 Creates a new contact info with a facetime-audio: action URL.
 
 @param emailAddressOrRawPhoneNumber   The email address or unformatted phone number.
 @param displayString                  The display string to represent the contact info. If nil then defaults to the emailAddressOrRawPhoneNumber.
 */
+ (OCKContactInfo *)facetimeAudio:(NSString *)emailAddressOrRawPhoneNumber displayString:(nullable NSString *)displayString;

@end

NS_ASSUME_NONNULL_END
