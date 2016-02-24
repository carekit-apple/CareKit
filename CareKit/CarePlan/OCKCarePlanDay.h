//
//  OCKCarePlanDay.h
//  CareKit
//
//  Created by Yuan Zhu on 2/22/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 * OCKCarePlanDay defines a day in gregorian calendar
 */
@interface OCKCarePlanDay : NSObject <NSSecureCoding, NSCopying>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithYear:(NSUInteger)year
                       month:(NSUInteger)month
                         day:(NSUInteger)day;

- (instancetype)initWithDate:(NSDate *)date
                    calendar:(NSCalendar *)calendar;

@property (nonatomic, readonly) NSUInteger year;

@property (nonatomic, readonly) NSUInteger month;

@property (nonatomic, readonly) NSUInteger day;

- (BOOL)isEarlierThan:(OCKCarePlanDay *)anotherDay;

- (BOOL)isLaterThan:(OCKCarePlanDay *)anotherDay;

@end
