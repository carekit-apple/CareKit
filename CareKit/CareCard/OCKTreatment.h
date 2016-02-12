//
//  OCKTreatment.h
//  CareKit
//
//  Created by Umer Khan on 1/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface OCKTreatment : NSObject <NSSecureCoding, NSCopying>

+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)treatmentWithTitle:(NSString *)title
                              text:(NSString *)text
                         frequency:(NSInteger)frequency;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithTitle:(NSString *)title
                         text:(NSString *)text
                    frequency:(NSInteger)frequency;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *text;
@property (nonatomic) NSInteger frequency;
@property (nonatomic, strong, null_resettable) UIColor *tintColor;
@property (nonatomic, readonly) NSInteger completed;

@end

NS_ASSUME_NONNULL_END
