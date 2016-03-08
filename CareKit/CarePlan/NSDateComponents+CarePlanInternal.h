//
//  NSDateComponents+CarePlanInternal.h
//  CareKit
//
//  Created by Yuan Zhu on 3/8/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import "NSDateComponents+CarePlan.h"

@interface NSDateComponents (CarePlanInternal)

- (BOOL)isEarlierThan:(NSDateComponents *)anotherDate;

- (BOOL)isLaterThan:(NSDateComponents *)anotherDate;

- (NSDate *)dateWithCalendar:(NSCalendar *)calendar;

- (NSDateComponents *)nextDay;

- (NSDateComponents *)dateByAddingDays:(NSInteger)days;

- (BOOL)isEqualToDate:(NSDateComponents *)date;

- (void)adjustEra;

@end