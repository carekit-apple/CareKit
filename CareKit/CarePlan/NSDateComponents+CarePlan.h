//
//  NSDateComponents+CarePlan.h
//  CareKit
//
//  Created by Yuan Zhu on 3/8/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDateComponents (CarePlan)

- (instancetype)initWithYear:(NSInteger)year
                       month:(NSInteger)month
                         day:(NSInteger)day;

- (instancetype)initWithDate:(NSDate *)date
                    calendar:(NSCalendar *)calendar;

@end
