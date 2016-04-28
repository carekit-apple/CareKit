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
#import "OCKCarePlanEvent_Internal.h"


NS_ASSUME_NONNULL_BEGIN

@interface OCKCarePlanEventResult () <OCKCoreDataObjectMirroring>

- (void)setSample:(HKSample *)sample;

@end

@class OCKCDCarePlanEvent;
@interface OCKCDCarePlanEventResult : NSManagedObject

- (instancetype)initWithEntity:(NSEntityDescription *)entity
insertIntoManagedObjectContext:(nullable NSManagedObjectContext *)context
                        result:(OCKCarePlanEventResult *)result
                         event:(OCKCDCarePlanEvent *)cdEvent;

- (void)updateWithResult:(OCKCDCarePlanEventResult *)result;

@end


@interface OCKCDCarePlanEventResult (CoreDataProperties)

@property (nullable, nonatomic, retain) NSDate *creationDate;
@property (nullable, nonatomic, retain) NSString *valueString;
@property (nullable, nonatomic, retain) NSString *unitString;
@property (nullable, nonatomic, retain) id userInfo;

@property (nullable, nonatomic, retain) id quantityStringFormatter;
@property (nullable, nonatomic, retain) id sampleUUID;
@property (nullable, nonatomic, retain) id sampleType;
@property (nullable, nonatomic, retain) id displayUnit;
@property (nullable, nonatomic, retain) id unitStringKeys;
@property (nullable, nonatomic, retain) id categoryValueStringKeys;

@property (nullable, nonatomic, retain) OCKCDCarePlanEvent *event;

@end

NS_ASSUME_NONNULL_END
