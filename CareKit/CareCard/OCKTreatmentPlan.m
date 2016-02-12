//
//  OCKTreatmentPlan.m
//  CareKit
//
//  Created by Umer Khan on 1/29/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKTreatmentPlan.h"
#import "OCKHelpers.h"


@implementation OCKTreatmentPlan

+ (instancetype)new {
    OCKThrowMethodUnavailableException();
    return nil;
}

+ (instancetype)treatmentPlanWithTreatments:(NSArray<OCKTreatment *> *)treatments {
    return [[OCKTreatmentPlan alloc] initWithTreatments:treatments];
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithTreatments:(NSArray<OCKTreatment *> *)treatments {
    self = [super init];
    if (self) {
        _treatments = [treatments copy];
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    __typeof(self) castObject = object;
    return (OCKEqualObjects(self.treatments, castObject.treatments));
}


#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        OCK_DECODE_OBJ_ARRAY(aDecoder, treatments, NSArray);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    OCK_ENCODE_OBJ(aCoder, treatments);
}


#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKTreatmentPlan *plan = [[[self class] allocWithZone:zone] init];
    plan->_treatments = [_treatments copy];
    return plan;
}

@end
