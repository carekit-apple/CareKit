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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, OCKContactInfoType) {
	OCKContactInfoTypePhone = 0,
	OCKContactInfoTypeMessage,
	OCKContactInfoTypeEmail,
	OCKContactInfoTypeVideo
};

@interface OCKContactInfo : NSObject <NSSecureCoding, NSCopying>

@property (nonatomic, readonly) OCKContactInfoType type;
@property (nonatomic, readonly) NSString *displayString;
@property (nonatomic, readonly) NSURL *actionURL;

- (instancetype)init NS_UNAVAILABLE;

/**
 Creates a new contact information item.
 
 @param type The type of contact info, which will define the display icon and the default action if no actionURL is specified.
 @param displayString The string that will be displayed to the user to represent the contact item.
 @param actionURL The action to take to initiate the connection. For example "sms:1-314-555-1234", "tel:1-314-555-1234", "facetime:user@example.com"
 
 @return An instance of the contact info.
 */
- (instancetype)initWithType:(OCKContactInfoType)type displayString:(NSString *)displayString actionURL:(NSURL * _Nullable)actionURL;

+ (OCKContactInfo *)smsContactInfo:(NSString *)smsNumber;
+ (OCKContactInfo *)phoneContactInfo:(NSString *)phoneNumber;
+ (OCKContactInfo *)emailContactInfo:(NSString *)emailAddress;
+ (OCKContactInfo *)facetimeVideoContactInfo:(NSString *)emailAddressOrRawPhoneNumber displayString:(NSString * _Nullable)displayString;
+ (OCKContactInfo *)facetimeAudioContactInfo:(NSString *)emailAddressOrRawPhoneNumber displayString:(NSString * _Nullable)displayString;

@end

NS_ASSUME_NONNULL_END