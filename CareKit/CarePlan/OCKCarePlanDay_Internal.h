//
//  OCKCarePlanDay_Internal.h
//  CareKit
//
//  Created by Yuan Zhu on 2/22/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import "OCKCarePlanDay.h"

@interface OCKCarePlanDay ()

- (NSDate *)dateWithCalendar:(NSCalendar *)calendar;

- (OCKCarePlanDay *)nextDay;

- (OCKCarePlanDay *)dayByAddingDays:(NSUInteger)days;

@end
