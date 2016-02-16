//
//  OCKPrescription.m
//  CareKit
//
//  Created by Yuan Zhu on 1/21/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import "OCKTreatment.h"
#import "OCKTreatment_Internal.h"
#import "OCKHelpers.h"
#import "OCKCarePlanActivity.h"
#import "OCKCarePlanActivity_Internal.h"

@implementation OCKTreatment

- (instancetype)initWithIdentifier:(NSString *)identifier
                              type:(NSString *)type
                             title:(NSString *)title
                              text:(NSString *)text
                             color:(UIColor *)color
                          schedule:(OCKCareSchedule *)schedule
                          optional:(BOOL)optional
              eventMutableDayRange:(OCKDayRange)eventMutableDayRange {
    return [super initWithIdentifier:identifier type:type title:title text:text color:color schedule:schedule optional:optional eventMutableDayRange:eventMutableDayRange];
}

@end


@implementation OCKCDTreatment


@end

@implementation OCKCDTreatment (CoreDataProperties)

@dynamic events;

@end



