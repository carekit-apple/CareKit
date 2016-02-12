//
//  OCKEvaluationPlan.m
//  CareKit
//
//  Created by Umer Khan on 2/2/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKEvaluationPlan.h"
#import "OCKEvaluation.h"
#import "OCKHelpers.h"


@implementation OCKEvaluationPlan

+ (instancetype)new {
    OCKThrowMethodUnavailableException();
    return nil;
}

+ (instancetype)evaluationPlanWithEvaluations:(NSArray<OCKEvaluation *> *)evaluations {
    return [[OCKEvaluationPlan alloc] initWithEvaluations:evaluations];
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithEvaluations:(NSArray<OCKEvaluation *> *)evaluations {
    self = [super init];
    if (self) {
        _evaluations = [evaluations copy];
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    __typeof(self) castObject = object;
    return (OCKEqualObjects(self.evaluations, castObject.evaluations));
}


#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        OCK_DECODE_OBJ_ARRAY(aDecoder, evaluations, NSArray);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    OCK_ENCODE_OBJ(aCoder, evaluations);
}


#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKEvaluationPlan *plan = [[[self class] allocWithZone:zone] init];
    plan->_evaluations = [_evaluations copy];
    return plan;
}

@end
