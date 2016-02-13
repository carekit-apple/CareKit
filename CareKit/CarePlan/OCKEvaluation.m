//
//  OCKEvaluation.m
//  CareKit
//
//  Created by Yuan Zhu on 1/29/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import "OCKEvaluation.h"
#import "OCKEvaluation_Internal.h"
#import "OCKHelpers.h"

@implementation OCKEvaluation

- (instancetype)initWithCoreDataObject:(OCKCDEvaluation *)cdObject {
    self = [super initWithCoreDataObject:cdObject];
    if (self) {
        _task = cdObject.task;
    }
    return self;
}


- (instancetype)initWithType:(nullable NSString *)type
                       title:(nullable NSString *)title
                        text:(nullable NSString *)text
                       color:(nullable UIColor *)color
                    schedule:(OCKCareSchedule *)schedule
                        task:(nullable id<ORKTask, NSSecureCoding>) task
                    optional:(BOOL)optional
                  retryLimit:(NSUInteger)retryLimit {
    
    self = [super initWithType:type title:title text:text color:color schedule:schedule optional:optional onlyMutableDuringEventDay:YES];
    if (self) {
        _task = task;
        _retryLimit = retryLimit;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        OCK_DECODE_OBJ(coder, task);
        OCK_DECODE_INTEGER(coder, retryLimit);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    OCK_ENCODE_OBJ(coder, task);
    OCK_ENCODE_INTEGER(coder, retryLimit);
}

- (BOOL)isEqual:(id)object {
    BOOL equal = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (equal &&
            OCKEqualObjects(self.task, castObject.task) &&
            (self.retryLimit == castObject.retryLimit));
}

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKEvaluation *evaluation = [super copyWithZone:zone];
    evaluation->_task = self.task;
    evaluation->_retryLimit = self.retryLimit;
    return evaluation;
}

@end


@implementation OCKCDEvaluation

- (instancetype)initWithEntity:(NSEntityDescription *)entity
insertIntoManagedObjectContext:(nullable NSManagedObjectContext *)context
                          item:(OCKEvaluation *)evaluation {
    
    self = [super initWithEntity:entity
  insertIntoManagedObjectContext:context
                            item:evaluation];
    
    if (self) {
        self.task = evaluation.task;
        self.retryLimit = @(evaluation.retryLimit);
    }
    return self;
}

@end


@implementation OCKCDEvaluation (CoreDataProperties)

@dynamic task;
@dynamic retryLimit;
@dynamic events;

@end
