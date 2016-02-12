//
//  OCKCareSchedule_Internal.h
//  CareKit
//
//  Created by Yuan Zhu on 2/4/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import <CareKit/CareKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OCKCareSchedule ()

-(void)setEndDate:(NSDate *)date;

- (NSCalendar *)calendar;

- (NSUInteger)numberOfEventsOnDay:(NSDate *)day;

- (NSUInteger)numberOfDaySinceStart:(NSDate *)day;

- (BOOL)isActiveOnDay:(NSDate *)date;

@end

NS_ASSUME_NONNULL_END