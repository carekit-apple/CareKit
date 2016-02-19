//
//  OCKCareEvent.m
//  CareKit
//
//  Created by Yuan Zhu on 2/1/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import "OCKCarePlanEvent.h"
#import "OCKCarePlanEvent_Internal.h"
#import "OCKCarePlanEventResult_Internal.h"


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
                                      activity:(OCKCarePlanActivity *)activity{
    self = [super init];
    if (self) {
        _numberOfDaysSinceStart = numberOfDaysSinceStart;
        _occurrenceIndexOfDay = occurrenceIndexOfDay;
        _activity = activity;
    }
    
    return self;
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

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %@ %@ %@>", super.description,
            self.activity.identifier,
            @(self.numberOfDaysSinceStart),
            @(self.occurrenceIndexOfDay)];
}

@end




@implementation OCKCDCarePlanEvent

- (instancetype)initWithEntity:(NSEntityDescription *)entity
insertIntoManagedObjectContext:(nullable NSManagedObjectContext *)context
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
    if (result) {
        if (self.result) {
            [self.result updateWithResult:result];
        } else {
            self.result = result;
        }
    } else {
        self.result = nil;
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

