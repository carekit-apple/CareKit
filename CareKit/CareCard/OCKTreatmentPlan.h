//
//  OCKTreatmentPlan.h
//  CareKit
//
//  Created by Umer Khan on 1/29/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OCKTreatment, OCKCareCard;

@interface OCKTreatmentPlan : NSObject <NSSecureCoding, NSCopying>

+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)treatmentPlanWithTreatments:(NSArray<OCKTreatment *> *)treatments;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithTreatments:(NSArray<OCKTreatment *> *)treatments;

@property (nonatomic, copy, readonly) NSArray<OCKTreatment *> *treatments;
@property (nonatomic, readonly) OCKCareCard *careCard;

@end

NS_ASSUME_NONNULL_END
