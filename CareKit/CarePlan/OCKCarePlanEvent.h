//
//  OCKCareEvent.h
//  CareKit
//
//  Created by Yuan Zhu on 2/1/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CareKit/OCKCarePlanActivity.h>
#import <CareKit/OCKCarePlanEventResult.h>

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSInteger, OCKCarePlanEventState) {
    OCKCarePlanEventStateInitial,
    OCKCarePlanEventStateNotCompleted,
    OCKCarePlanEventStateCompleted
};

/**
 Abstract Event Class
 */
@interface OCKCarePlanEvent : NSObject 

/**
 The index of this event for its associated OCKCarePlanItem.
 */
@property (nonatomic, readonly) NSUInteger occurrenceIndexOfDay;

/**
 Which day this event is in. Counting from the start day.
 E.g. If this event is on start day, this value is `0`.
 The combination of `occurrenceIndexOfDay` and `numberOfDaysSinceStart` uniquely identifys an event.
 */
@property (nonatomic, readonly) NSUInteger numberOfDaysSinceStart;



@property (nonatomic, strong, readonly) OCKCarePlanActivity *activity;

/**
 The state of this event (Initial / NotCompleted / Completed).
 All event starts with `Initial`.
 */
@property (nonatomic, readonly) OCKCarePlanEventState state;


@property (nonatomic, readonly, nullable) OCKCarePlanEventResult *result;

@end


NS_ASSUME_NONNULL_END
