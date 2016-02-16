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
        _allowRetry = cdObject.allowRetry.boolValue;
    }
    return self;
}


- (instancetype)initWithIdentifier:(NSString *)identifier
                              type:(nullable NSString *)type
                             title:(nullable NSString *)title
                              text:(nullable NSString *)text
                             color:(nullable UIColor *)color
                          schedule:(OCKCareSchedule *)schedule
                              task:(nullable id<ORKTask, NSSecureCoding>) task
                          optional:(BOOL)optional
                        allowRetry:(NSUInteger)allowRetry {
    
    OCKDayRange range = {0, 0};
    
    self = [super initWithIdentifier:identifier type:type title:title text:text color:color schedule:schedule optional:optional eventMutableDayRange:range];
    if (self) {
        _task = task;
        _allowRetry = allowRetry;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        OCK_DECODE_OBJ(coder, task);
        OCK_DECODE_BOOL(coder, allowRetry);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    OCK_ENCODE_OBJ(coder, task);
    OCK_ENCODE_BOOL(coder, allowRetry);
}

- (BOOL)isEqual:(id)object {
    BOOL equal = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (equal &&
            OCKEqualObjects(self.task, castObject.task) &&
            (self.allowRetry == castObject.allowRetry));
}

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKEvaluation *evaluation = [super copyWithZone:zone];
    evaluation->_task = self.task;
    evaluation->_allowRetry = self.allowRetry;
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
        self.allowRetry = @(evaluation.allowRetry);
    }
    return self;
}

@end


@implementation OCKCDEvaluation (CoreDataProperties)

@dynamic task;
@dynamic allowRetry;
@dynamic events;

@end
