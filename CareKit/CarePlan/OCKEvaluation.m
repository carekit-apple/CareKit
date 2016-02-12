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
                    optional:(BOOL)optional {
    self = [super initWithType:type title:title text:text color:color schedule:schedule optional:optional];
    if (self) {
        _task = task;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        OCK_DECODE_OBJ(coder, task);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    OCK_DECODE_OBJ(coder, task);
}

- (BOOL)isEqual:(id)object {
    BOOL equal = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (equal &&
            OCKEqualObjects(self.task, castObject.task)
            );
}

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKEvaluation *evaluation = [super copyWithZone:zone];
    evaluation->_task = self.task;
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
    }
    return self;
}

@end


@implementation OCKCDEvaluation (CoreDataProperties)

@dynamic task;
@dynamic events;

@end
