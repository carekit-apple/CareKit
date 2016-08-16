#import <XCTest/XCTest.h>
#import <CareKit/CareKit.h>
#import <CareKit/CareKit_private.h>
#import "OCKDefines_Private.h"

@interface CareKitContactTests : XCTestCase

@end

@implementation CareKitContactTests

- (void)testWhenContactIsSerializedAndDeserializedThenTheDeserializedVersionHasTheSameContent {
	UIImage *image = [UIImage imageNamed:@"heart" inBundle:[NSBundle bundleForClass:[OCKContact class]] compatibleWithTraitCollection:nil];
	OCKContact *contact = [[OCKContact alloc] initWithContactType:OCKContactTypePersonal name:@"John Smith" relation:@"Primary Care Physician" tintColor:[UIColor blueColor] monogram:@"JS" image:image];
	OCKContactInfo *contactInfo = [[OCKContactInfo alloc] initWithType:OCKContactInfoTypePhone displayString:@"contact info 1" actionURL:[[NSURL alloc] initWithString:@"type1://data1"] label:@"label 1" icon:image];
	[contact addContactInfoItem:contactInfo];
	
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
