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


#import <CareKit/CareKit.h>


NS_ASSUME_NONNULL_BEGIN

@class OCKContact, OCKCarePlanStore;

/**
 The `OCKPatient` class is an object that represents a patient.
 */
OCK_CLASS_AVAILABLE
@interface OCKPatient : NSObject <NSSecureCoding, NSCopying>

- (instancetype)init NS_UNAVAILABLE;

/**
 Returns an initialized patient using the specified values.
 
 @param identifier          The identifier for the patient.
 @param store               The care plan store for the patient.
 @param name                The name for the patient.
 @param detailInfo          Additional information for the patient.
 @param careTeamContacts    The contacts in charge of the patients.
 @param tintColor           The tint color for the patient.
 @param monogram            A monogram for the patient.
 @param image               An image for the patient.
 @param categories          An array of categories of the patient.
 
 @return An initialized patient object.
 */
- (instancetype)initWithIdentifier:(NSString *)identifier
                     carePlanStore:(OCKCarePlanStore *)store
                              name:(NSString *)name
                        detailInfo:(nullable NSString *)detailInfo
                  careTeamContacts:(nullable NSArray<OCKContact *> *)careTeamContacts
                         tintColor:(nullable UIColor *)tintColor
                          monogram:(null_unspecified NSString *)monogram
                             image:(nullable UIImage *)image
                        categories:(nullable NSArray<NSString *> *)categories
                          userInfo:(nullable NSDictionary *)userInfo;


/**
 The identifier for the patient.
 */
@property (nonatomic, copy, readonly) NSString *identifier;

/**
 The care plan store for the patient.
 */
@property (nonatomic, readonly) OCKCarePlanStore *store;

/**
 A string indicating the name for a patient.
 */
@property (nonatomic, copy, readonly) NSString *name;

/**
 A string indicating additional details for a patient.
 
 This can include date of birth, gender, etc.
 */
@property (nonatomic, copy, readonly, nullable) NSString *detailInfo;

/**
 The care team contacts that are repsonsible for this patient.
 
 Must be OCKContact objects of type OCKContactTypeCareTeam.
 */
@property (nonatomic, copy, readonly, nullable) NSArray<OCKContact *> *careTeamContacts;

/**
 The tint color for a patient.
 
 If the value is not specified, the app's tint color is used.
 */
@property (nonatomic, readonly, nullable) UIColor *tintColor;

/**
 A string indicating the monogram for a contact.
 
 If a monogram is not provided, it will be generated automatically.
 If a monogram is available, it will be clipped to two glyphs.
 */
@property (nonatomic, readonly, null_resettable) NSString *monogram;

/**
 An image for a contact.
 
 If an image is not provided, a monogram will be used for the contact.
 An image can be set after a contact object has been created. If an image
 is available, it will be displayed instead of the monogram.
 */
@property (nonatomic, nullable) UIImage *image;

/**
 An array of strings indicating the categories of the patient (e.g. pediatric, cardiology).
 */
@property (nonatomic, copy, readonly, nullable) NSArray<NSString *> *categories;

/**
 Save any additional objects that comply with the NSCoding protocol.
 */
@property (nonatomic, copy, readonly, nullable) NSDictionary<NSString *, id<NSCoding>> *userInfo;

@end

NS_ASSUME_NONNULL_END
