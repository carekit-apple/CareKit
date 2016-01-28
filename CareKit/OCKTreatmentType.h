//
//  OCKMedicationType.h
//  CareKit
//
//  Created by Yuan Zhu on 1/21/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface OCKTreatmentType : NSObject <NSSecureCoding>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithName:(NSString *)name text:(nullable NSString *)text;

@property (nonatomic, copy, readonly) NSString *identifier;

@property (nonatomic, copy, readonly) NSString *name;

@property (nonatomic, copy, readonly, nullable) NSString *text;

@end

NS_ASSUME_NONNULL_END
