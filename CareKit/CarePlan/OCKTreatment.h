//
//  OCKPrescription.h
//  CareKit
//
//  Created by Yuan Zhu on 1/21/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CareKit/OCKCarePlanItem.h>

NS_ASSUME_NONNULL_BEGIN
@class OCKCarePlanItem;

@interface OCKTreatment : OCKCarePlanItem

- (instancetype)initWithType:(nullable NSString *)type
                       title:(nullable NSString *)title
                        text:(nullable NSString *)text
                       color:(nullable UIColor *)color
                    schedule:(OCKCareSchedule *)schedule
                    optional:(BOOL)optional
   onlyMutableDuringEventDay:(BOOL)onlyMutableDuringEventDay;

@end

NS_ASSUME_NONNULL_END
