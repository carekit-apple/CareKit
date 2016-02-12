//
//  OCKCareCard.h
//  CareKit
//
//  Created by Umer Khan on 1/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface OCKCareCard : NSObject <NSSecureCoding, NSCopying>

+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)careCardWithAdherence:(CGFloat)adherence
                                 date:(NSString *)date;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithAdherence:(CGFloat)adherence
                             date:(NSString *)date;

@property (nonatomic) CGFloat adherence;
@property (nonatomic, copy, readonly) NSString *date;

- (NSString *)adherencePercentageString;

@end

NS_ASSUME_NONNULL_END
