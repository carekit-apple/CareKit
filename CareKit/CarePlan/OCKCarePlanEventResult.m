//
//  OCKCarePlanEventResult.m
//  CareKit
//
//  Created by Yuan Zhu on 2/17/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import "OCKCarePlanEventResult_Internal.h"
#import "OCKHelpers.h"

@implementation OCKCarePlanEventResult

- (instancetype)initWithValueString:(NSString *)valueString
                         unitString:(nullable NSString *)unitString
                           userInfo:(nullable NSDictionary *)userInfo {
    NSParameterAssert(valueString);
    self = [super init];
    if (self) {
        _valueString = valueString;
        _unitString = unitString;
        _userInfo = userInfo;
        _creationDate = [NSDate date];
    }
    return self;
}

- (instancetype)initWithCoreDataObject:(OCKCDCarePlanEventResult *)cdObject {
    NSParameterAssert(cdObject);
    self = [super init];
    if (self) {
        _creationDate = cdObject.creationDate;
        _valueString = cdObject.valueString;
        _unitString = cdObject.unitString;
        _userInfo = cdObject.userInfo;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    BOOL isClassMatch = ([self class] == [object class]);
    
    __typeof(self) castObject = object;
    return (isClassMatch &&
            OCKEqualObjects(self.creationDate, castObject.creationDate) &&
            OCKEqualObjects(self.valueString, castObject.valueString) &&
            OCKEqualObjects(self.unitString, castObject.unitString) &&
            OCKEqualObjects(self.userInfo, castObject.userInfo)
            );
}

@end


@implementation OCKCDCarePlanEventResult

- (instancetype)initWithEntity:(NSEntityDescription *)entity
insertIntoManagedObjectContext:(nullable NSManagedObjectContext *)context
                        result:(OCKCarePlanEventResult *)result
                         event:(OCKCDCarePlanEvent *)cdEvent {
    NSParameterAssert(result);
    NSParameterAssert(cdEvent);
    self = [super initWithEntity:entity insertIntoManagedObjectContext:context];
    if (self) {
        self.creationDate = result.creationDate;
        self.valueString = result.valueString;
        self.unitString = result.unitString;
        self.userInfo = result.userInfo;
        self.event = cdEvent;
    }
    return self;
}

- (void)updateWithResult:(OCKCDCarePlanEventResult *)result {
    self.creationDate = result.creationDate;
    self.valueString = result.valueString;
    self.unitString = result.unitString;
    self.userInfo = result.userInfo;
}

@end

@implementation OCKCDCarePlanEventResult (CoreDataProperties)

@dynamic creationDate;
@dynamic valueString;
@dynamic unitString;
@dynamic userInfo;
@dynamic event;

@end