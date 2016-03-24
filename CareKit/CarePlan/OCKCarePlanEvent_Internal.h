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


#import <CareKit/CareKit.h>
#import <CoreData/CoreData.h>
#import "OCKCarePlanActivity_Internal.h"
#import "OCKCarePlanEventResult_Internal.h"


NS_ASSUME_NONNULL_BEGIN

@interface OCKCarePlanEvent () <OCKCoreDataObjectMirroring, NSCopying>

- (instancetype)initWithNumberOfDaysSinceStart:(NSUInteger)numberOfDaysSinceStart
                          occurrenceIndexOfDay:(NSUInteger)occurrenceIndexOfDay
                                      activity:(OCKCarePlanActivity *)activity;

@property (nonatomic) OCKCarePlanEventState state;

@property (nonatomic, nullable) OCKCarePlanEventResult *result;

@end


@class OCKCDCarePlanEventResult;

@interface OCKCDCarePlanEvent : NSManagedObject

- (instancetype)initWithEntity:(NSEntityDescription *)entity
insertIntoManagedObjectContext:(nullable NSManagedObjectContext *)context
                         event:(OCKCarePlanEvent *)event
                      cdResult:(nullable OCKCDCarePlanEventResult *)cdResult
                    cdActivity:(OCKCDCarePlanActivity *)cdActivity;

- (void)updateWithState:(OCKCarePlanEventState)state result:(nullable OCKCDCarePlanEventResult *)result;

@end


@class OCKCDCarePlanEventResult;

@interface OCKCDCarePlanEvent (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *occurrenceIndexOfDay;
@property (nullable, nonatomic, retain) NSNumber *numberOfDaysSinceStart;
@property (nullable, nonatomic, retain) NSNumber *state;
@property (nullable, nonatomic, retain) OCKCDCarePlanEventResult *result;
@property (nullable, nonatomic, retain) OCKCDCarePlanActivity *activity;

@end

NS_ASSUME_NONNULL_END
