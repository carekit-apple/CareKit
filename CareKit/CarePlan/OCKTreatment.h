//
//  OCKPrescription.h
//  CareKit
//
//  Created by Yuan Zhu on 1/21/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CareKit/OCKCarePlanActivity.h>

NS_ASSUME_NONNULL_BEGIN
@class OCKCarePlanItem;

@interface OCKTreatment : OCKCarePlanActivity

- (instancetype)initWithIdentifier:(NSString *)identifier
                              type:(nullable NSString *)type
                             title:(nullable NSString *)title
                              text:(nullable NSString *)text
                             color:(nullable UIColor *)color
                          schedule:(OCKCareSchedule *)schedule
                          optional:(BOOL)optional
              eventMutableDayRange:(OCKDayRange)eventMutableDayRange;

@end

NS_ASSUME_NONNULL_END
