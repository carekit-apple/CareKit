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
#import "OCKCarePlanItem.h"
#import "OCKCarePlanItem_Internal.h"

@implementation OCKTreatment

- (instancetype)initWithType:(NSString *)type title:(NSString *)title text:(NSString *)text color:(UIColor *)color schedule:(OCKCareSchedule *)schedule optional:(BOOL)optional {
    return [super initWithType:type title:title text:text color:color schedule:schedule optional:optional];
}

@end


@implementation OCKCDTreatment


@end

@implementation OCKCDTreatment (CoreDataProperties)

@dynamic events;

@end



