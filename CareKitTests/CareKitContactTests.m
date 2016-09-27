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


#import <XCTest/XCTest.h>
#import <CareKit/CareKit.h>
#import <CareKit/CareKit_private.h>
#import "OCKDefines_Private.h"


@interface CareKitContactTests : XCTestCase

@end


@implementation CareKitContactTests

- (void)testWhenContactIsSerializedAndDeserializedThenTheDeserializedVersionHasTheSameContent {
	UIImage *image = [UIImage imageNamed:@"heart" inBundle:[NSBundle bundleForClass:[OCKContact class]] compatibleWithTraitCollection:nil];
	OCKContactInfo *contactInfo = [[OCKContactInfo alloc] initWithType:OCKContactInfoTypePhone displayString:@"contact info 1" actionURL:[[NSURL alloc] initWithString:@"type1://data1"] label:@"label 1" icon:image];
	OCKContact *contact = [[OCKContact alloc] initWithContactType:OCKContactTypePersonal name:@"John Smith" relation:@"Primary Care Physician" contactInfoItems:@[contactInfo] tintColor:[UIColor blueColor] monogram:@"JS" image:image];
	
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:contact];
	OCKContact *other = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	
	XCTAssertEqual(contact.type, other.type);
	XCTAssertEqualObjects(contact.name, other.name);
	XCTAssertEqualObjects(contact.relation, other.relation);
	XCTAssertEqualObjects(contact.tintColor, other.tintColor);
	XCTAssertEqualObjects(contact.monogram, other.monogram);
	XCTAssertEqual(image.size.width, other.image.size.width);
	XCTAssertEqual(image.size.height, other.image.size.height);
	
	XCTAssertEqual(contact.contactInfoItems.count, other.contactInfoItems.count);
	OCKContactInfo *otherContactInfo = other.contactInfoItems.firstObject;
	
	XCTAssertEqual(contactInfo.type, otherContactInfo.type);
	XCTAssertEqualObjects(contactInfo.displayString, otherContactInfo.displayString);
	XCTAssertEqualObjects(contactInfo.actionURL, otherContactInfo.actionURL);
	XCTAssertEqualObjects(contactInfo.label, otherContactInfo.label);
	XCTAssertEqual(image.size.width, otherContactInfo.icon.size.width);
	XCTAssertEqual(image.size.height, otherContactInfo.icon.size.height);
}

- (void)testWhenOCKContactInfoTypePhoneIsCreatedThenLabelAndIconAreCorrect {
	OCKContactInfo *contactInfoPhone = [[OCKContactInfo alloc] initWithType:OCKContactInfoTypePhone displayString:@"contact info phone" actionURL:[[NSURL alloc] initWithString:@"1234567891"]];
	
	XCTAssertEqualObjects(contactInfoPhone.label, OCKLocalizedString(@"CONTACT_INFO_PHONE_TITLE", nil));

	NSData *expectedImage = UIImagePNGRepresentation([UIImage imageNamed:@"phone" inBundle:OCKBundle() compatibleWithTraitCollection:nil]);
	
	XCTAssertEqualObjects(UIImagePNGRepresentation(contactInfoPhone.icon), expectedImage);
}

- (void)testWhenOCKContactInfoTypeMessageIsCreatedThenLabelAndIconAreCorrect {
	OCKContactInfo *contactInfoMessage = [[OCKContactInfo alloc] initWithType:OCKContactInfoTypeMessage displayString:@"contact info message" actionURL:[[NSURL alloc] initWithString:@"1234567891"]];
	
	XCTAssertEqualObjects(contactInfoMessage.label, OCKLocalizedString(@"CONTACT_INFO_MESSAGE_TITLE", nil));
	
	NSData *expectedImage = UIImagePNGRepresentation([UIImage imageNamed:@"message" inBundle:OCKBundle() compatibleWithTraitCollection:nil]);
	
	XCTAssertEqualObjects(UIImagePNGRepresentation(contactInfoMessage.icon), expectedImage);
}

- (void)testWhenOCKContactInfoTypeEmailIsCreatedThenLabelAndIconAreCorrect {
	OCKContactInfo *contactInfoEmail = [[OCKContactInfo alloc] initWithType:OCKContactInfoTypeEmail displayString:@"contact info email" actionURL:[[NSURL alloc] initWithString:@"example@data.com"]];
	
	XCTAssertEqualObjects(contactInfoEmail.label, OCKLocalizedString(@"CONTACT_INFO_EMAIL_TITLE", nil));
	
	NSData *expectedImage = UIImagePNGRepresentation([UIImage imageNamed:@"email" inBundle:OCKBundle() compatibleWithTraitCollection:nil]);
	
	XCTAssertEqualObjects(UIImagePNGRepresentation(contactInfoEmail.icon), expectedImage);
}

- (void)testWhenOCKContactInfoTypeVideoIsCreatedThenLabelAndIconAreCorrect {
	OCKContactInfo *contactInfoVideo = [[OCKContactInfo alloc] initWithType:OCKContactInfoTypeVideo displayString:@"contact info video" actionURL:[[NSURL alloc] initWithString:@"example@data.com"]];
	
	XCTAssertEqualObjects(contactInfoVideo.label, OCKLocalizedString(@"CONTACT_INFO_VIDEO_TITLE", nil));
	
	NSData *expectedImage = UIImagePNGRepresentation([UIImage imageNamed:@"video" inBundle:OCKBundle() compatibleWithTraitCollection:nil]);
	
	XCTAssertEqualObjects(UIImagePNGRepresentation(contactInfoVideo.icon), expectedImage);
}

@end
