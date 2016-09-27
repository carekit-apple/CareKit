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


#import <XCTest/XCTest.h>
#import <CareKit/CareKit.h>
#import <CareKit/CareKit_Private.h>


@interface OCKTestTests : XCTestCase

@end

@implementation OCKTestTests {
    OCKCarePlanStore *_store;
    OCKCarePlanActivity *_activity;
    OCKCarePlanEvent *_event;
    NSDateComponents *_startDate;
}

- (void)setUp {
    [super setUp];
    
    NSURL *directoryURL = [NSURL fileURLWithPath:[self cleanTestPath]];
    _store = [[OCKCarePlanStore alloc] initWithPersistenceDirectoryURL:directoryURL];
    
    _startDate = [[NSDateComponents alloc] initWithYear:2016 month:01 day:01];
    
    OCKCareSchedule *schedule = [OCKCareSchedule dailyScheduleWithStartDate:_startDate occurrencesPerDay:6];
    
    _activity = [OCKCarePlanActivity interventionWithIdentifier:@"id1"
                                                groupIdentifier:@"gid1"
                                                          title:@"title1"
                                                           text:@"text1"
                                                      tintColor:[UIColor redColor]
                                                   instructions:@"detailText1"
                                                       imageURL:[NSURL fileURLWithPath:@"1.png"]
                                                       schedule:schedule
                                                       userInfo:@{@"key":@"value1"}];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"add1"];
    [_store addActivity:_activity completion:^(BOOL success, NSError * _Nonnull error) {
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    
    expectation = [self expectationWithDescription:@"events"];
    
    __block NSArray<OCKCarePlanEvent *> *myevents = nil;
    [_store eventsForActivity:_activity date:_startDate completion:^(NSArray<OCKCarePlanEvent *> * _Nonnull events, NSError * _Nullable error) {
        [expectation fulfill];
        myevents = events;
    }];
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    _event = myevents.firstObject;
}

- (void)tearDown {
    [self cleanTestPath];
}


- (NSString *)testPath {
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docPath = [searchPaths objectAtIndex:0];
    NSString *storePath = [docPath stringByAppendingPathComponent:@"carePlanStore"];
    [[NSFileManager defaultManager] createDirectoryAtPath:storePath withIntermediateDirectories:YES attributes:nil error:nil];
    
    return storePath;
}

- (NSString *)cleanTestPath {
    NSString *testPath = [self testPath];
    [[NSFileManager defaultManager] removeItemAtPath:testPath error:nil];
    return [self testPath];
}

- (void)verifySample:(HKSample *)sample
           formatter:(NSNumberFormatter *)formatter
                unit:(HKUnit *)unit
    unitStringKeys:(NSDictionary<HKUnit *, NSString *> *)unitStringKeys
      expectedString:(NSString *)expectedString
        expectedUnit:(NSString *)expectedUnit {
    [self verifySample:sample formatter:formatter unit:unit unitStringKeys:unitStringKeys expectedString:expectedString expectedUnit:expectedUnit saveToHK:YES];
}

- (void)verifySample:(HKSample *)sample
           formatter:(NSNumberFormatter *)formatter
                unit:(HKUnit *)unit
      unitStringKeys:(NSDictionary<HKUnit *, NSString *> *)unitStringKeys
      expectedString:(NSString *)expectedString
        expectedUnit:(NSString *)expectedUnit
            saveToHK:(BOOL)saveToHK {
    
    XCTAssertTrue([HKHealthStore isHealthDataAvailable]);
    
    HKHealthStore *hkstore = [HKHealthStore new];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"requestAuthorization"];
    
    if ([sample isKindOfClass:[HKCorrelation class]]) {
        
        HKQuantityType *systolicType =
        [HKObjectType quantityTypeForIdentifier:
         HKQuantityTypeIdentifierBloodPressureSystolic];
        
        HKQuantityType *diastolicType =
        [HKObjectType quantityTypeForIdentifier:
         HKQuantityTypeIdentifierBloodPressureDiastolic];
        
        [hkstore requestAuthorizationToShareTypes:[NSSet setWithObjects:systolicType, diastolicType , nil]
                                        readTypes:[NSSet setWithObjects:systolicType, diastolicType , nil]
                                       completion:^(BOOL success, NSError * _Nullable error) {
                                            [expectation fulfill];
                                        }];
        
        
    } else {
        [hkstore requestAuthorizationToShareTypes:[NSSet setWithObject:sample.sampleType]
                                        readTypes:[NSSet setWithObject:sample.sampleType] completion:^(BOOL success, NSError * _Nullable error) {
                                            [expectation fulfill];
                                        }];
    }
    
    [self waitForExpectationsWithTimeout:2500 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    if (saveToHK) {
        expectation = [self expectationWithDescription:@"save sample"];
        [hkstore saveObject:sample withCompletion:^(BOOL success, NSError * _Nullable error) {
            [expectation fulfill];
            XCTAssertTrue(success);
        }];
        [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
            XCTAssertNil(error);
        }];
    }
    
    OCKCarePlanEvent *sampleEvent = _event;
    
    OCKCarePlanEventResult *result = nil;
    if ([sample isKindOfClass:[HKQuantitySample class]]) {
        
        if (unit) {
            result = [[OCKCarePlanEventResult alloc] initWithQuantitySample:(HKQuantitySample *)sample
                                                    quantityStringFormatter:formatter
                                                                displayUnit:unit
                                                       displayUnitStringKey:unitStringKeys[unit]
                                                                   userInfo:nil];
        } else {
            result = [[OCKCarePlanEventResult alloc] initWithQuantitySample:(HKQuantitySample *)sample
                                                    quantityStringFormatter:formatter
                                                             unitStringKeys:unitStringKeys
                                                                   userInfo:nil];
        }
        XCTAssertNotNil(result.unitString);
    } else if ([sample isKindOfClass:[HKCorrelation class]]) {
        result = [[OCKCarePlanEventResult alloc] initWithCorrelation:(HKCorrelation *)sample
                                             quantityStringFormatter:formatter
                                                         displayUnit:unit
                                                      unitStringKeys:unitStringKeys
                                                            userInfo:nil];
        XCTAssertNotNil(result.unitString);
    } else if ([sample isKindOfClass:[HKCategorySample class]]) {
        result = [[OCKCarePlanEventResult alloc] initWithCategorySample:(HKCategorySample *)sample
                                                categoryValueStringKeys:@{@0:@"0a", @1:@"1b", @2:@"2c", @3:@"3d"}
                                                               userInfo:nil];
    }
    
    XCTAssertNotNil(result.valueString);
    
    expectation = [self expectationWithDescription:@"save result"];
    [_store updateEvent:sampleEvent
            withResult:result
                 state:OCKCarePlanEventStateCompleted
            completion:^(BOOL success, OCKCarePlanEvent * _Nullable event, NSError * _Nullable error) {
                [expectation fulfill];
                XCTAssertTrue(success);
            }];
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    expectation = [self expectationWithDescription:@"read result"];
    __block OCKCarePlanEvent *fetchedEvent;
    [_store enumerateEventsOfActivity:_activity
                            startDate:_startDate
                              endDate:_startDate
                              handler:^(OCKCarePlanEvent * _Nullable event, BOOL * _Nonnull stop) {
                                 if (event.numberOfDaysSinceStart == sampleEvent.numberOfDaysSinceStart &&
                                     event.occurrenceIndexOfDay == sampleEvent.occurrenceIndexOfDay) {
                                     fetchedEvent = event;
                                 }
                             }
                          completion:^(BOOL completed, NSError * _Nullable error) {
                              [expectation fulfill];
                          }];
    
    [self waitForExpectationsWithTimeout:30.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    XCTAssertNotNil(fetchedEvent);
    
    NSLog(@"\n==========\n");
    NSLog(@"expectedString = %@", expectedString);
    NSLog(@"valueString = %@", fetchedEvent.result.valueString);
    NSLog(@"inputUnit = %@", [unit unitString]);
    NSLog(@"expectedUnit = %@", expectedUnit);
    NSLog(@"unitString = %@", fetchedEvent.result.unitString);
    
    XCTAssertEqualObjects(fetchedEvent.result.valueString, expectedString);
    XCTAssertEqualObjects(fetchedEvent.result.unitString, expectedUnit);
}

- (void)testHKResult {
    
    // HKQuantitySample
    {
        HKQuantityType* type = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
        HKUnit *gramUnit = [HKUnit gramUnit];
        HKQuantitySample *sample = [HKQuantitySample quantitySampleWithType:type
                                                                   quantity:[HKQuantity quantityWithUnit:gramUnit doubleValue:160.0]
                                                                  startDate:[NSDate date]
                                                                    endDate:[NSDate date]];
        
        [self verifySample:sample formatter:nil unit:gramUnit unitStringKeys:@{gramUnit: gramUnit.unitString}
            expectedString:@"160" expectedUnit:[[HKUnit gramUnit] unitString]];
        
        [self verifySample:sample
                 formatter:nil
                      unit:nil
            unitStringKeys:@{[HKUnit poundUnit]: @"pound"}
            expectedString:@"0.353"
              expectedUnit: @"pound"];
        
        NSNumberFormatter *formatter = [NSNumberFormatter new];
        formatter.numberStyle = NSNumberFormatterCurrencyStyle;
        
        [self verifySample:sample
                 formatter:formatter
                      unit:nil
            unitStringKeys:@{[HKUnit poundUnit]: [[HKUnit poundUnit] unitString]}
            expectedString:@"$0.35"
              expectedUnit:[[HKUnit poundUnit] unitString]];
    }
    
    // HKCategorySample
    {
        HKCategorySample *sample  = [HKCategorySample categorySampleWithType:[HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis]
                                                                       value:HKCategoryValueSleepAnalysisInBed
                                                                   startDate:[NSDate date]
                                                                     endDate:[NSDate dateWithTimeIntervalSinceNow:60]];
        
        [self verifySample:sample formatter:nil unit:nil unitStringKeys:nil expectedString:@"0a" expectedUnit:nil];
        
        HKCategorySample *sample2  = [HKCategorySample categorySampleWithType:[HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis]
                                                                       value:HKCategoryValueSleepAnalysisAsleep
                                                                   startDate:[NSDate date]
                                                                     endDate:[NSDate dateWithTimeIntervalSinceNow:60]];
        
        [self verifySample:sample2 formatter:nil unit:nil unitStringKeys:nil expectedString:@"1b" expectedUnit:nil];
    }
    
    // HKCorrelation
    {
        HKQuantityType *systolicType =
        [HKObjectType quantityTypeForIdentifier:
         HKQuantityTypeIdentifierBloodPressureSystolic];
        
        HKQuantity *systolicQuantity =
        [HKQuantity quantityWithUnit:[HKUnit millimeterOfMercuryUnit]
                         doubleValue:120.0];
        
        HKQuantitySample *systolicSample =
        [HKQuantitySample quantitySampleWithType:systolicType
                                        quantity:systolicQuantity
                                       startDate:[NSDate date]
                                         endDate:[NSDate date]];
        
        HKQuantityType *diastolicType =
        [HKObjectType quantityTypeForIdentifier:
         HKQuantityTypeIdentifierBloodPressureDiastolic];
        
        HKQuantity *diastolicQuantity =
        [HKQuantity quantityWithUnit:[HKUnit millimeterOfMercuryUnit]
                         doubleValue:75.0];
        
        HKQuantitySample *diastolicSample =
        [HKQuantitySample quantitySampleWithType:diastolicType
                                        quantity:diastolicQuantity
                                       startDate:[NSDate date]
                                         endDate:[NSDate date]];

        
        
        HKCorrelation *correlation  = [HKCorrelation correlationWithType:[HKCorrelationType correlationTypeForIdentifier:HKCorrelationTypeIdentifierBloodPressure]
                                                          startDate:[NSDate date]
                                                            endDate:[NSDate date]
                                                            objects:[NSSet setWithObjects:systolicSample, diastolicSample, nil]];
        
        [self verifySample:correlation formatter:nil unit:nil unitStringKeys:@{[HKUnit millimeterOfMercuryUnit]:[[HKUnit millimeterOfMercuryUnit]  unitString]} expectedString:@"75 - 120" expectedUnit:[[HKUnit millimeterOfMercuryUnit]  unitString]];
        
        NSNumberFormatter *formatter = [NSNumberFormatter new];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
        formatter.minimumSignificantDigits = 4;
        [self verifySample:correlation formatter:formatter unit:nil unitStringKeys:@{[HKUnit millimeterOfMercuryUnit]:[[HKUnit millimeterOfMercuryUnit]  unitString]} expectedString:@"75.00 - 120.0" expectedUnit:[[HKUnit millimeterOfMercuryUnit]  unitString]];
    }
    
    // Test a sample is not in HealthKit
    {
        HKQuantityType* type = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
        HKQuantitySample *sample = [HKQuantitySample quantitySampleWithType:type
                                                                   quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:2120.0]
                                                                  startDate:[NSDate date]
                                                                    endDate:[NSDate date]];
        
        [self verifySample:sample formatter:nil unit:[HKUnit gramUnit] unitStringKeys:@{[HKUnit gramUnit]: [[HKUnit gramUnit] unitString]} expectedString:@"" expectedUnit:nil saveToHK:NO];
    }
}

@end
