//
//  OCKContact.h
//  CareKit
//
//  Created by Umer Khan on 1/30/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, OCKContactType) {
    OCKContactTypeClinician = 0,
    OCKContactTypeEmergencyContact
};

@interface OCKContact : NSObject <NSSecureCoding, NSCopying>

+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)contactWithContactType:(OCKContactType)type;
+ (instancetype)contactWithContactType:(OCKContactType)type
                                  name:(nullable NSString *)name
                              relation:(nullable NSString *)relation
                           phoneNumber:(nullable NSString *)phoneNumber
                         messageNumber:(nullable NSString *)messageNumber
                          emailAddress:(nullable NSString *)emailAddress
                                 image:(nullable UIImage *)image;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithContactType:(OCKContactType)type;
- (instancetype)initWithContactType:(OCKContactType)type
                               name:(nullable NSString *)name
                           relation:(nullable NSString *)relation
                        phoneNumber:(nullable NSString *)phoneNumber
                      messageNumber:(nullable NSString *)messageNumber
                       emailAddress:(nullable NSString *)emailAddress
                              image:(nullable UIImage *)image;

@property (nonatomic, readonly) OCKContactType type;
@property (nonatomic, copy, nullable) NSString *name;
@property (nonatomic, copy, nullable) NSString *relation;
@property (nonatomic, copy, nullable) NSString *phoneNumber;
@property (nonatomic, copy, nullable) NSString *messageNumber;
@property (nonatomic, copy, nullable) NSString *emailAddress;
@property (nonatomic, nullable) UIImage *image;
@property (nonatomic, copy, null_resettable) UIColor *tintColor;

@end

NS_ASSUME_NONNULL_END
