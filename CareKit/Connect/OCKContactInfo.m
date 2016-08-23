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


#import "OCKContactInfo.h"
#import "OCKHelpers.h"
#import "OCKDefines_Private.h"


@implementation OCKContactInfo

+ (instancetype)new {
	OCKThrowMethodUnavailableException();
	return nil;
}

- (instancetype)initWithType:(OCKContactInfoType)type displayString:(NSString *)displayString actionURL:(NSURL *)actionURL {
	NSString *defaultLabel;
	
	switch (type) {
		case OCKContactInfoTypePhone:
			defaultLabel = OCKLocalizedString(@"CONTACT_INFO_PHONE_TITLE", nil);
			break;
			
		case OCKContactInfoTypeMessage:
			defaultLabel = OCKLocalizedString(@"CONTACT_INFO_MESSAGE_TITLE", nil);
			break;
			
		case OCKContactInfoTypeEmail:
			defaultLabel = OCKLocalizedString(@"CONTACT_INFO_EMAIL_TITLE", nil);
			break;
			
		case OCKContactInfoTypeVideo:
			defaultLabel = OCKLocalizedString(@"CONTACT_INFO_VIDEO_TITLE", nil);
			break;
	}
	return [self initWithType:type displayString:displayString actionURL:actionURL label:defaultLabel];
}

- (instancetype)initWithType:(OCKContactInfoType)type displayString:(NSString *)displayString actionURL:(NSURL *)actionURL label:(NSString *)label {
	UIImage *defaultIcon;
	
	switch (type) {
		case OCKContactInfoTypePhone:
			defaultIcon = [UIImage imageNamed:@"phone" inBundle:OCKBundle() compatibleWithTraitCollection:nil];
			break;
			
		case OCKContactInfoTypeMessage:
			defaultIcon = [UIImage imageNamed:@"message" inBundle:OCKBundle() compatibleWithTraitCollection:nil];
			break;
			
		case OCKContactInfoTypeEmail:
			defaultIcon = [UIImage imageNamed:@"email" inBundle:OCKBundle() compatibleWithTraitCollection:nil];
			break;
			
		case OCKContactInfoTypeVideo:
			defaultIcon = [UIImage imageNamed:@"video" inBundle:OCKBundle() compatibleWithTraitCollection:nil];
			break;
	}
	return [self initWithType:type displayString:displayString actionURL:actionURL label:label icon:defaultIcon];
}

- (instancetype)initWithType:(OCKContactInfoType)type displayString:(NSString *)displayString actionURL:(NSURL *)actionURL label:(NSString *)label icon:(UIImage *)icon {
	self = [super init];
	if (self) {
		_type = type;
		_displayString = [displayString copy];
		_actionURL = [actionURL copy];
		_label = [label copy];
		_icon = icon.renderingMode == UIImageRenderingModeAlwaysTemplate ? icon : [icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	}
	return self;
}

+ (OCKContactInfo *)sms:(NSString *)smsNumber {
	NSURL *actionURL = [[NSURL alloc] initWithString:[@"sms:" stringByAppendingString:OCKStripNonNumericCharacters(smsNumber)]];
	return [[OCKContactInfo alloc] initWithType:OCKContactInfoTypeMessage displayString:smsNumber actionURL:actionURL];
}

+ (OCKContactInfo *)phone:(NSString *)phoneNumber {
	NSURL *actionURL = [[NSURL alloc] initWithString:[@"tel:" stringByAppendingString:OCKStripNonNumericCharacters(phoneNumber)]];
	return [[OCKContactInfo alloc] initWithType:OCKContactInfoTypePhone displayString:phoneNumber actionURL:actionURL];
}

+ (OCKContactInfo *)email:(NSString *)emailAddress {
	NSURL *actionURL = [[NSURL alloc] initWithString:[@"mailto:" stringByAppendingString:emailAddress]];
	return [[OCKContactInfo alloc] initWithType:OCKContactInfoTypeEmail displayString:emailAddress actionURL:actionURL];
}

+ (OCKContactInfo *)facetimeVideo:(NSString *)emailAddressOrRawPhoneNumber displayString:(NSString *)displayString {
	NSURL *actionURL = [[NSURL alloc] initWithString:[@"facetime://" stringByAppendingString:emailAddressOrRawPhoneNumber]];
	return [[OCKContactInfo alloc] initWithType:OCKContactInfoTypeVideo displayString:displayString ?: emailAddressOrRawPhoneNumber actionURL:actionURL];
}

+ (OCKContactInfo *)facetimeAudio:(NSString *)emailAddressOrRawPhoneNumber displayString:(NSString *)displayString{
	NSURL *actionURL = [[NSURL alloc] initWithString:[@"facetime-audio://" stringByAppendingString:emailAddressOrRawPhoneNumber]];
	return [[OCKContactInfo alloc] initWithType:OCKContactInfoTypePhone displayString:displayString ?: emailAddressOrRawPhoneNumber actionURL:actionURL];
}


#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
	return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super init];
	if (self) {
		OCK_DECODE_ENUM(aDecoder, type);
		OCK_DECODE_OBJ_CLASS(aDecoder, displayString, NSString);
		OCK_DECODE_OBJ_CLASS(aDecoder, actionURL, NSURL);
		OCK_DECODE_OBJ_CLASS(aDecoder, label, NSString);
		OCK_DECODE_IMAGE(aDecoder, icon);
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	OCK_ENCODE_ENUM(aCoder, type);
	OCK_ENCODE_OBJ(aCoder, displayString);
	OCK_ENCODE_OBJ(aCoder, actionURL);
	OCK_ENCODE_OBJ(aCoder, label);
	OCK_ENCODE_IMAGE(aCoder, icon);
}


#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
	OCKContactInfo *contactInfo = [[[self class] allocWithZone:zone] init];
	contactInfo->_type = self.type;
	contactInfo->_displayString = [self.displayString copy];
	contactInfo->_actionURL = [self.actionURL copy];
	contactInfo->_label = [self.label copy];
	contactInfo->_icon = self.icon;
	return contactInfo;
}

@end
