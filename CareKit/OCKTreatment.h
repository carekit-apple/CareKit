//
//  OCKPrescription.h
//  CareKit
//
//  Created by Yuan Zhu on 1/21/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CareKit/CareKit.h>

NS_ASSUME_NONNULL_BEGIN

@class OCKTreatmentSchedule;
@interface OCKTreatment : NSObject <NSSecureCoding>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithType:(OCKTreatmentType *)type
                       title:(nullable NSString *)title
                        text:(nullable NSString *)text
                       color:(nullable UIColor *)color
                    schedule:(OCKTreatmentSchedule *)schedule
                    inActive:(BOOL)inActive;

- (instancetype)initWithType:(OCKTreatmentType *)type
                       color:(nullable UIColor *)color
                    schedule:(OCKTreatmentSchedule *)schedule
                    inActive:(BOOL)inActive;

@property (nonatomic, readonly) NSString *identifier;

@property (nonatomic, readonly) OCKTreatmentType *treatmentType;

@property (nonatomic, readonly, nullable) NSString *title;

@property (nonatomic, readonly, nullable) NSString *text;

@property (nonatomic, readonly, nullable) UIColor *color;

@property (nonatomic, readonly) OCKTreatmentSchedule *schedule;

@property (nonatomic, readonly) BOOL inActive;

@end


@interface OCKTreatmentSchedule : NSObject  <NSSecureCoding>

- (instancetype)initWithStartDate:(NSDate *)startDate
                          endDate:(nullable NSDate *)endDate
                         timeZone:(nullable NSTimeZone *)timeZone;

@property (nonatomic, readonly) NSDate *startDate;

@property (nonatomic, readonly, nullable) NSDate *endDate;

@property (nonatomic, readonly, nullable) NSTimeZone *timeZone;

- (NSUInteger)numberOfOccurencesOnDay:(NSDate *)day;

@end

NS_ASSUME_NONNULL_END
