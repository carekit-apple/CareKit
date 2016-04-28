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


#import "OCKCarePlanEvent.h"
#import "OCKCarePlanEvent_Internal.h"
#import "OCKCarePlanEventResult_Internal.h"
#import "NSDateComponents+CarePlanInternal.h"
#import "OCKHelpers.h"


@implementation OCKCarePlanEvent

- (instancetype)initWithCoreDataObject:(OCKCDCarePlanEvent *)cdObject {
    self = [super init];
    if (self) {
        _occurrenceIndexOfDay = cdObject.occurrenceIndexOfDay.unsignedIntegerValue;
        _numberOfDaysSinceStart = cdObject.numberOfDaysSinceStart.unsignedIntegerValue;
        _state = cdObject.state.integerValue;
        if (cdObject.result) {
             _result = [[OCKCarePlanEventResult alloc] initWithCoreDataObject:cdObject.result];
        }
        _activity = [[OCKCarePlanActivity alloc] initWithCoreDataObject:cdObject.activity];
    }
    return self;
}

- (instancetype)initWithNumberOfDaysSinceStart:(NSUInteger)numberOfDaysSinceStart
                           occurrenceIndexOfDay:(NSUInteger)occurrenceIndexOfDay
                                      activity:(OCKCarePlanActivity *)activity {
    self = [super init];
    if (self) {
        _numberOfDaysSinceStart = numberOfDaysSinceStart;
        _occurrenceIndexOfDay = occurrenceIndexOfDay;
        _activity = activity;
    }
    
    return self;
}

- (NSDateComponents *)date {
    return [self.activity.schedule.startDate dateCompByAddingDays:self.numberOfDaysSinceStart];
}

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKCarePlanEvent* event = [[[self class] allocWithZone:zone] init];
    event->_occurrenceIndexOfDay = _occurrenceIndexOfDay;
    event->_numberOfDaysSinceStart = _numberOfDaysSinceStart;
    event->_state = _state;
    event->_activity = _activity;
    event->_result = _result;
    return event;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    __typeof(self) castObject = object;
    return ((self.occurrenceIndexOfDay == castObject.occurrenceIndexOfDay) &&
            (self.numberOfDaysSinceStart == castObject.numberOfDaysSinceStart) &&
            (self.state == castObject.state) &&
            OCKEqualObjects(self.activity, castObject.activity) &&
            OCKEqualObjects(self.result, castObject.result));
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %@ %@ %@>", super.description,
            self.activity.identifier,
            @(self.numberOfDaysSinceStart),
            @(self.occurrenceIndexOfDay)];
}

@end


@implementation OCKCDCarePlanEvent

- (instancetype)initWithEntity:(NSEntityDescription *)entity
insertIntoManagedObjectContext:(NSManagedObjectContext *)context
                         event:(OCKCarePlanEvent *)event
                      cdResult:(OCKCDCarePlanEventResult *)cdResult
                    cdActivity:(OCKCDCarePlanActivity *)cdActivity {
    
    NSParameterAssert(event);
    NSParameterAssert(cdActivity);
    
    self = [super initWithEntity:entity insertIntoManagedObjectContext:context];
    if (self) {
        self.occurrenceIndexOfDay = @(event.occurrenceIndexOfDay);
        self.numberOfDaysSinceStart = @(event.numberOfDaysSinceStart);
        self.activity = cdActivity;
        [self updateWithState:event.state result:cdResult];
    }
    return self;
}

- (void)updateWithState:(OCKCarePlanEventState)state result:(OCKCDCarePlanEventResult *)result {
    self.state = @(state);
    
    if (result && self.result) {
        [self.result updateWithResult:result];
    } else {
        self.result = result;
    }
}

@end


@implementation OCKCDCarePlanEvent (CoreDataProperties)

@dynamic occurrenceIndexOfDay;
@dynamic numberOfDaysSinceStart;
@dynamic state;
@dynamic result;
@dynamic activity;

@end
