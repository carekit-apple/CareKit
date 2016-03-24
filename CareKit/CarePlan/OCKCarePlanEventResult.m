/*
 Copyright (c) 2016, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "OCKCarePlanEventResult_Internal.h"
#import "OCKHelpers.h"


@implementation OCKCarePlanEventResult

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithValueString:(NSString *)valueString
                         unitString:(nullable NSString *)unitString
                           userInfo:(nullable NSDictionary *)userInfo {
    OCKThrowInvalidArgumentExceptionIfNil(valueString);
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
    self = [self initWithValueString:cdObject.valueString
                          unitString:cdObject.unitString userInfo:cdObject.userInfo];
    if (self) {
        _creationDate = cdObject.creationDate;
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
