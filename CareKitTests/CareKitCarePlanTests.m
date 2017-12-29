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
#import "NSDateComponents+CarePlanInternal.h"


@interface CareKitTests : XCTestCase <OCKCarePlanStoreDelegate>

@end

@implementation CareKitTests {
    BOOL _listChanged;
    OCKCarePlanEvent *_event;
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

- (BOOL)isListChangeDelegateCalled {
    BOOL called = _listChanged;
    _listChanged = NO;
    return called;
}

- (BOOL)isEventChangeDelegateCalled {
    BOOL called = _event ? YES : NO;
    _event = nil;
    return called;
}

- (void)tearDown {
    _listChanged = NO;
    _event = nil;
}

- (void)testActivitys {
    
    NSURL *directoryURL = [NSURL fileURLWithPath:[self cleanTestPath]];
    OCKCarePlanStore *store = [[OCKCarePlanStore alloc] initWithPersistenceDirectoryURL:directoryURL];
    store.delegate = self;
    
    NSDateComponents *startDate = [[NSDateComponents alloc] initWithYear:2016 month:01 day:01];
    
    OCKCareSchedule *schedule = [OCKCareSchedule dailyScheduleWithStartDate:startDate occurrencesPerDay:3];
    
    NSURL *url1 = [NSURL fileURLWithPath:[directoryURL.path stringByAppendingPathComponent:@"1.png"]];
    [[NSDictionary new] writeToURL:url1 atomically:YES];
    NSURL *url2 = [NSURL fileURLWithPath:[directoryURL.path stringByAppendingPathComponent:@"2.png"]];
    [[NSDictionary new] writeToURL:url2 atomically:YES];
    NSURL *url4 = [NSURL fileURLWithPath:[directoryURL.path stringByAppendingPathComponent:@"4.png"]];
    [[NSDictionary new] writeToURL:url4 atomically:YES];
    
    OCKCarePlanActivity *item1 = [OCKCarePlanActivity interventionWithIdentifier:@"id1"
                                                                 groupIdentifier:@"gid1"
                                                                           title:@"title1"
                                                                            text:@"text1"
                                                                       tintColor:[UIColor redColor]
                                                                    instructions:@"detailText1"
                                                                        imageURL:url1
                                                                        schedule:schedule
                                                                        userInfo:@{@"key":@"value1"}
                                                                        optional:false];
    
    OCKCareSchedule *weeklySchedule = [OCKCareSchedule weeklyScheduleWithStartDate:startDate
                                                             occurrencesOnEachDay:@[@3, @3, @3, @3, @3, @3, @3]];
    
    OCKCarePlanActivity *item2 = [OCKCarePlanActivity interventionWithIdentifier:@"id2"
                                                                 groupIdentifier:@"gid2"
                                                                           title:@"title2"
                                                                            text:@"text2"
                                                                       tintColor:[UIColor redColor]
                                                                    instructions:@"detailText2"
                                                                        imageURL:url2
                                                                        schedule:weeklySchedule
                                                                        userInfo:@{@"key":@"value2"}
                                                                        optional:false];
    
    OCKCarePlanActivity *item3 = [OCKCarePlanActivity assessmentWithIdentifier:@"id3"
                                                               groupIdentifier:@"gid3"
                                                                         title:@"title3"
                                                                          text:@"text3"
                                                                     tintColor:[UIColor greenColor]
                                                              resultResettable:YES
                                                                      schedule:schedule
                                                                      userInfo:@{@"key":@"value3"}
                                                                      optional:false];
    
    OCKCarePlanActivity *item4 = [OCKCarePlanActivity interventionWithIdentifier:@"id4"
                                                                 groupIdentifier:@"gid4"
                                                                           title:@"title4"
                                                                            text:@"text4"
                                                                       tintColor:[UIColor redColor]
                                                                    instructions:@"detailText4"
                                                                        imageURL:url4
                                                                        schedule:schedule
                                                                        userInfo:@{@"key":@"value4"}
                                                                        optional:false];
    
    
    __block NSError *error;
    __block BOOL result;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"add1"];
    [store addActivity:item1 completion:^(BOOL success, NSError * _Nonnull error) {
        result = success;
        error = error;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        error = error;
    }];
    XCTAssertTrue(result);
    XCTAssertNil(error);
    XCTAssertTrue([self isListChangeDelegateCalled]);
    
    // Test making call synced.
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    [store activitiesWithCompletion:^(BOOL success, NSArray<OCKCarePlanActivity *> * _Nonnull activities, NSError * _Nullable error) {
        dispatch_semaphore_signal(sem);
    }];
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    expectation = [self expectationWithDescription:@"add2"];
    [store addActivity:item2 completion:^(BOOL success, NSError * _Nonnull error) {
        XCTAssertFalse([NSThread isMainThread]);
        result = success;
        error = error;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        error = error;
    }];
    XCTAssertTrue(result);
    XCTAssertNil(error);
    XCTAssertTrue([self isListChangeDelegateCalled]);
    
    expectation = [self expectationWithDescription:@"add3"];
    [store addActivity:item3 completion:^(BOOL success, NSError * _Nonnull error) {
        XCTAssertFalse([NSThread isMainThread]);
        result = success;
        error = error;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        error = error;
    }];
    XCTAssertTrue(result);
    XCTAssertNil(error);
    XCTAssertTrue([self isListChangeDelegateCalled]);
    
    expectation = [self expectationWithDescription:@"add4"];
    [store addActivity:item4 completion:^(BOOL success, NSError * _Nonnull error) {
        XCTAssertFalse([NSThread isMainThread]);
        result = success;
        error = error;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        error = error;
    }];
    XCTAssertTrue(result);
    XCTAssertNil(error);
    XCTAssertTrue([self isListChangeDelegateCalled]);
    
    expectation = [self expectationWithDescription:@"activitiesWithType"];
    [store activitiesWithType:OCKCarePlanActivityTypeIntervention
                   completion:^(BOOL success, NSArray<OCKCarePlanActivity *> * _Nonnull activities, NSError * _Nonnull error) {
                       XCTAssertFalse([NSThread isMainThread]);
                       XCTAssertTrue(success);
                       XCTAssertNil(error);
                       XCTAssertEqual(activities.count, 3);
                       [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    expectation = [self expectationWithDescription:@"activitiesWithType"];
    [store activitiesWithType:OCKCarePlanActivityTypeAssessment
                   completion:^(BOOL success, NSArray<OCKCarePlanActivity *> * _Nonnull activities, NSError * _Nonnull error) {
                       XCTAssertTrue(success);
                       XCTAssertNil(error);
                       XCTAssertEqual(activities.count, 1);
                       [expectation fulfill];
                   }];
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    
    //////////////////
    // Rebuild store
    //////////////////
    
    store = [[OCKCarePlanStore alloc] initWithPersistenceDirectoryURL:directoryURL];
    store.delegate = self;
    
    expectation = [self expectationWithDescription:@"activityForIdentifier"];
    [store activityForIdentifier:item1.identifier
                      completion:^(BOOL success, OCKCarePlanActivity * _Nonnull activity, NSError * _Nonnull error) {
                          XCTAssertFalse([NSThread isMainThread]);
                          XCTAssertTrue(success);
                          XCTAssertEqualObjects(activity, item1);
                          XCTAssertNil(error);
                          [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    expectation = [self expectationWithDescription:@"activityForIdentifier"];
    // test calling API from background thread.
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [store activityForIdentifier:item2.identifier
                          completion:^(BOOL success, OCKCarePlanActivity * _Nonnull activity, NSError * _Nonnull error) {
                              XCTAssertFalse([NSThread isMainThread]);
                              XCTAssertTrue(success);
                              XCTAssertEqualObjects(activity, item2);
                              XCTAssertNil(error);
                              [expectation fulfill];
                          }];
    });
   
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    expectation = [self expectationWithDescription:@"activityForIdentifier"];
    [store activityForIdentifier:item3.identifier
                      completion:^(BOOL success, OCKCarePlanActivity * _Nonnull activity, NSError * _Nonnull error) {
                          XCTAssertFalse([NSThread isMainThread]);
                          XCTAssertTrue(success);
                          XCTAssertEqualObjects(activity, item3);
                          XCTAssertNil(error);
                          [expectation fulfill];
                      }];
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    expectation = [self expectationWithDescription:@"activitiesWithType"];
    [store activitiesWithType:OCKCarePlanActivityTypeIntervention
                   completion:^(BOOL success, NSArray<OCKCarePlanActivity *> * _Nonnull activities, NSError * _Nonnull error) {
                       XCTAssertFalse([NSThread isMainThread]);
                       XCTAssertTrue(success);
                       XCTAssertNil(error);
                       XCTAssertEqual(activities.count, 3);
                       [expectation fulfill];
                   }];
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    expectation = [self expectationWithDescription:@"activitiesWithType"];
    [store activitiesWithType:OCKCarePlanActivityTypeAssessment
                   completion:^(BOOL success, NSArray<OCKCarePlanActivity *> * _Nonnull activities, NSError * _Nonnull error) {
                       XCTAssertFalse([NSThread isMainThread]);
                       XCTAssertTrue(success);
                       XCTAssertNil(error);
                       XCTAssertEqual(activities.count, 1);
                       [expectation fulfill];
                   }];
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    __block NSArray<OCKCarePlanActivity *> *activities;
    
    expectation = [self expectationWithDescription:@"activities"];
    [store activitiesWithCompletion:^(BOOL success, NSArray<OCKCarePlanActivity *> * _Nonnull activityArray, NSError * _Nonnull error) {
                        XCTAssertFalse([NSThread isMainThread]);
                       XCTAssertTrue(success);
                       XCTAssertNil(error);
                       XCTAssertEqual(activityArray.count, 4);
                        activities = activityArray;
                       [expectation fulfill];
                   }];
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    XCTAssertEqualObjects(activities[0], item1);
    XCTAssertNotNil(activities[0].imageURL);
    XCTAssertEqualObjects(activities[0].imageURL, url1);
    
    XCTAssertNotNil(activities[1].imageURL);
    XCTAssertNotNil(activities[3].imageURL);
    XCTAssertEqualObjects(activities[1], item2);
    XCTAssertEqualObjects(activities[2], item3);
    
    NSDate *endDate = [NSDate dateWithTimeIntervalSinceNow:8*24*60*60];
    NSDateComponents *endDateComp = [[NSDateComponents alloc] initWithDate:endDate calendar:[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian]];
    expectation = [self expectationWithDescription:@"setEndDate"];
    [store setEndDate:endDateComp
         forActivity:activities[2]
          completion:^(BOOL success, OCKCarePlanActivity * _Nonnull activity, NSError * _Nonnull error) {
              XCTAssertFalse([NSThread isMainThread]);
               XCTAssertTrue(success);
               XCTAssertNil(error);
               XCTAssertEqualObjects(activity.schedule.endDate, endDateComp);
               [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];

    activities = nil;
    expectation = [self expectationWithDescription:@"activities2"];
    [store activitiesWithCompletion:^(BOOL success, NSArray<OCKCarePlanActivity *> * _Nonnull activityArray, NSError * _Nonnull error) {
        XCTAssertFalse([NSThread isMainThread]);
        XCTAssertTrue(success);
        XCTAssertNil(error);
        XCTAssertEqual(activityArray.count, 4);
        activities = activityArray;
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    XCTAssertEqualObjects(activities[2].schedule.endDate, endDateComp, @"%@", activities[2].identifier);
    XCTAssertTrue([self isListChangeDelegateCalled]);
    
    expectation = [self expectationWithDescription:@"removeActivity"];
    [store removeActivity:activities[2] completion:^(BOOL success, NSError * _Nonnull error) {
        XCTAssertFalse([NSThread isMainThread]);
        XCTAssertTrue(success);
        XCTAssertNil(error);
       [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    expectation = [self expectationWithDescription:@"removeActivity again"];
    [store removeActivity:activities[2] completion:^(BOOL success, NSError * _Nonnull error) {
        XCTAssertFalse([NSThread isMainThread]);
        XCTAssertFalse(success);
        XCTAssertNotNil(error);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];

    XCTAssertTrue([self isListChangeDelegateCalled]);
    
    expectation = [self expectationWithDescription:@"activities"];
    [store activitiesWithCompletion:^(BOOL success, NSArray<OCKCarePlanActivity *> * _Nonnull activityArray, NSError * _Nonnull error) {
        XCTAssertFalse([NSThread isMainThread]);
        XCTAssertTrue(success);
        XCTAssertNil(error);
        XCTAssertEqual(activityArray.count, 3);
        activities = activityArray;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    XCTAssertEqual(activities.count, 3);
    XCTAssertEqualObjects(activities[0], item1);
    XCTAssertEqualObjects(activities[1], item2);
    
    __block NSArray<NSArray<OCKCarePlanEvent *> *> *eventGroups = nil;
    
    expectation = [self expectationWithDescription:@"fetchTreatmentEvents"];
    [store eventsOnDate:startDate
                  type:OCKCarePlanActivityTypeIntervention
            completion:^(NSArray<NSArray<OCKCarePlanEvent *> *> * _Nonnull eventsGroupedByActivity, NSError * _Nonnull error) {
                XCTAssertFalse([NSThread isMainThread]);
                eventGroups = eventsGroupedByActivity;
                XCTAssertNil(error);
                [expectation fulfill];
            }];
    
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
   
    XCTAssertEqual(eventGroups.count, 3);
    XCTAssertEqual(eventGroups[0].count, 3);
    XCTAssertEqual(eventGroups[1].count, 3);
    XCTAssertEqual(eventGroups[0][0].state, OCKCarePlanEventStateInitial);
    XCTAssertEqual(eventGroups[0][1].state, OCKCarePlanEventStateInitial);
    XCTAssertEqual(eventGroups[0][2].state, OCKCarePlanEventStateInitial);
    XCTAssertEqual(eventGroups[1][0].state, OCKCarePlanEventStateInitial);
    XCTAssertEqual(eventGroups[1][1].state, OCKCarePlanEventStateInitial);
    XCTAssertEqual(eventGroups[1][2].state, OCKCarePlanEventStateInitial);
    
    expectation = [self expectationWithDescription:@"updateEvent00"];
    
    NSDictionary *userInfo1 = @{@"a":@"a1", @"b":@"b1"};
    OCKCarePlanEventResult *eventResult1 = [[OCKCarePlanEventResult alloc] initWithValueString:@"value1"
                                                                                    unitString:@"unit1"
                                                                                      userInfo:userInfo1];
   
    [store updateEvent:eventGroups[0][0]
            withResult:eventResult1
                 state:OCKCarePlanEventStateCompleted
            completion:^(BOOL success, OCKCarePlanEvent * _Nonnull event, NSError * _Nonnull error) {
                XCTAssertFalse([NSThread isMainThread]);
                XCTAssertNil(error);
                XCTAssertTrue(success);
                [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    XCTAssertTrue([self isEventChangeDelegateCalled]);
    
    expectation = [self expectationWithDescription:@"updateEvent10"];
    
    NSDictionary *userInfo2 = @{@"a":@"a2", @"b":@"b2"};
    OCKCarePlanEventResult *eventResult2 = [[OCKCarePlanEventResult alloc] initWithValueString:@"value2"
                                                                                    unitString:@"unit2"
                                                                                      userInfo:userInfo2];
    
    [store updateEvent:eventGroups[1][0]
            withResult:eventResult2
                 state:OCKCarePlanEventStateCompleted
            completion:^(BOOL success, OCKCarePlanEvent * _Nonnull event, NSError * _Nonnull error) {
                        XCTAssertFalse([NSThread isMainThread]);
                         XCTAssertNil(error);
                         XCTAssertTrue(success);
                         [expectation fulfill];
                     }];
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    XCTAssertTrue([self isEventChangeDelegateCalled]);
    
    expectation = [self expectationWithDescription:@"fetchTreatmentEvents"];
    [store eventsOnDate:startDate
                  type:OCKCarePlanActivityTypeIntervention
            completion:^(NSArray<NSArray<OCKCarePlanEvent *> *> * _Nonnull eventsGroupedByActivity, NSError * _Nonnull error) {
                XCTAssertFalse([NSThread isMainThread]);
                eventGroups = eventsGroupedByActivity;
                XCTAssertNil(error);
                [expectation fulfill];
            }];
    
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    XCTAssertNil(error);
    XCTAssertEqual(eventGroups.count, 3);
    XCTAssertEqual(eventGroups[0].count, 3);
    XCTAssertEqual(eventGroups[1].count, 3);
    XCTAssertEqual(eventGroups[0][0].state, OCKCarePlanEventStateCompleted);
    XCTAssertEqual(eventGroups[0][1].state, OCKCarePlanEventStateInitial);
    XCTAssertEqual(eventGroups[0][2].state, OCKCarePlanEventStateInitial);
    
    XCTAssertEqual(eventGroups[1][0].state, OCKCarePlanEventStateCompleted);
    XCTAssertEqual(eventGroups[1][1].state, OCKCarePlanEventStateInitial);
    XCTAssertEqual(eventGroups[1][2].state, OCKCarePlanEventStateInitial);
    
    OCKCarePlanEventResult *fetchResult1 = eventGroups[0][0].result;
    OCKCarePlanEventResult *fetchResult2 = eventGroups[1][0].result;
    XCTAssertEqualObjects(fetchResult1, eventResult1);
    XCTAssertEqualObjects(fetchResult2, eventResult2);
    
    expectation = [self expectationWithDescription:@"updateEvent00again"];
    
    NSDictionary *userInfo3 = @{@"a":@"a3", @"b":@"b3"};
    OCKCarePlanEventResult *eventResult3 = [[OCKCarePlanEventResult alloc] initWithValueString:@"value3"
                                                                                    unitString:@"unit3"
                                                                                      userInfo:userInfo3];
    
    [store updateEvent:eventGroups[0][0]
            withResult:eventResult3
                 state:OCKCarePlanEventStateCompleted
            completion:^(BOOL success, OCKCarePlanEvent * _Nonnull event, NSError * _Nonnull error) {
                XCTAssertFalse([NSThread isMainThread]);
                XCTAssertNil(error);
                XCTAssertTrue(success);
                [expectation fulfill];
            }];
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    XCTAssertTrue([self isEventChangeDelegateCalled]);
    
    expectation = [self expectationWithDescription:@"fetchTreatmentEvents"];
    [store eventsOnDate:startDate
                  type:OCKCarePlanActivityTypeIntervention
            completion:^(NSArray<NSArray<OCKCarePlanEvent *> *> * _Nonnull eventsGroupedByActivity, NSError * _Nonnull error) {
                XCTAssertFalse([NSThread isMainThread]);
                eventGroups = eventsGroupedByActivity;
                XCTAssertNil(error);
                [expectation fulfill];
            }];
    
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    fetchResult1 = eventGroups[0][0].result;
    XCTAssertEqualObjects(fetchResult1, eventResult3);
    
    expectation = [self expectationWithDescription:@"enumerateEvents"];
    NSMutableArray<OCKCarePlanEvent *> *eventsOfActivity = [NSMutableArray new];
    NSDateComponents *futureDay = [startDate dateCompByAddingDays:100];
    [store enumerateEventsOfActivity:activities[0]
                           startDate:startDate
                             endDate:futureDay
                             handler:^(OCKCarePlanEvent * _Nullable event, BOOL * _Nonnull stop) {
                                 XCTAssertFalse([NSThread isMainThread]);
                                 [eventsOfActivity addObject:event];
                             }
                          completion:^(BOOL completed, NSError * _Nullable error) {
                              XCTAssertFalse([NSThread isMainThread]);
                              XCTAssertNil(error);
                              [expectation fulfill];
                          }];
    
    [self waitForExpectationsWithTimeout:10.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    XCTAssertEqual(eventsOfActivity.count, 3*101);
    XCTAssertEqual(eventsOfActivity[0].numberOfDaysSinceStart, 0);
    XCTAssertEqual(eventsOfActivity[1].numberOfDaysSinceStart, 0);
    XCTAssertEqual(eventsOfActivity[2].numberOfDaysSinceStart, 0);
    
    XCTAssertEqual(eventsOfActivity[3*3].numberOfDaysSinceStart, 3);
    XCTAssertEqual(eventsOfActivity[5*3].numberOfDaysSinceStart, 5);
    
    store.delegate = nil;
    [self measureBlock:^{
        
        for (OCKCarePlanEvent* event in eventsOfActivity) {
            XCTestExpectation *expectation = [self expectationWithDescription:@"updateEvent"];
            [store updateEvent:event
                    withResult:nil
                         state:OCKCarePlanEventStateCompleted
                    completion:^(BOOL success, OCKCarePlanEvent * _Nonnull event, NSError * _Nonnull error) {
                        XCTAssertFalse([NSThread isMainThread]);
                          XCTAssertNil(error);
                          XCTAssertTrue(success, @"%@: %@", event, error);
                          [expectation fulfill];
            }];
        }
        
        [self waitForExpectationsWithTimeout:10.0 handler:^(NSError * _Nullable error) {
            XCTAssertNil(error);
        }];
    }];
    
    expectation = [self expectationWithDescription:@"completionStatus"];
    
    __block NSInteger count = 0;
    [store dailyCompletionStatusWithType:OCKCarePlanActivityTypeIntervention
                                startDate:[startDate nextDay]
                                  endDate:futureDay
                                 handler:^(NSDateComponents * _Nonnull date, NSUInteger completed, NSUInteger total) {
                                     XCTAssertFalse([NSThread isMainThread]);
                                     XCTAssertNotNil(date);
                                     XCTAssertEqual(completed, 3, @"on %@", date);
                                     XCTAssertEqual(total, 9);
                                     count ++;
                                 }
                              completion:^(BOOL completed, NSError * _Nullable error) {
                                  XCTAssertFalse([NSThread isMainThread]);
                                  XCTAssertNil(error);
                                  [expectation fulfill];
                                  
                              }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    XCTAssertEqual(count, 100);
    
}


- (void)testThresholdFlagging {
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSDate *now = [NSDate date];
    NSDateComponents *today = [[NSDateComponents alloc] initWithDate:now calendar:calendar];
    
    OCKCareSchedule *dailySchedule = [OCKCareSchedule dailyScheduleWithStartDate:today occurrencesPerDay:1 daysToSkip:1 endDate:nil dailyThreshold:[OCKCarePlanThreshold adheranceThresholdWithValue:@(1) title:@"Did not do activity"]];
    
    NSArray<NSArray<OCKCarePlanThreshold *> *> *thresholds = [NSArray arrayWithObject:[NSArray arrayWithObject:[OCKCarePlanThreshold numericThresholdWithValue:@(80) type:OCKCarePlanThresholdTypeNumericGreaterThan upperValue:nil title:@"Heart Rate Above 80"]]];
    
    OCKCarePlanActivity *assessmentActivity = [OCKCarePlanActivity assessmentWithIdentifier:@"assessment1" groupIdentifier:nil title:@"First Assessment" text:nil tintColor:nil resultResettable:YES schedule:dailySchedule userInfo:nil thresholds:thresholds optional:false];
    
    OCKCarePlanEventResult *result1 = [[OCKCarePlanEventResult alloc] initWithValueString:@"75" unitString:@"beats/minute" userInfo:nil values:@[@(75)]];
    OCKCarePlanEventResult *result2 = [[OCKCarePlanEventResult alloc] initWithValueString:@"85" unitString:@"beats/minute" userInfo:nil values:@[@(85)]];
    
    XCTAssertFalse([assessmentActivity.thresholds[0][0] evaluateThresholdForValue:result1.values[0]]);
    XCTAssertTrue([assessmentActivity.thresholds[0][0] evaluateThresholdForValue:result2.values[0]]);
}


- (void)testDailySchedules {
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSDate *now = [NSDate date];
    NSDateComponents *today = [[NSDateComponents alloc] initWithDate:now calendar:calendar];
    
    // Every Day
    OCKCareSchedule *dailySchedule = [OCKCareSchedule dailyScheduleWithStartDate:today occurrencesPerDay:2];
    XCTAssertEqual([dailySchedule numberOfEventsOnDate:[today nextDay]], 2);
    XCTAssertEqual([dailySchedule numberOfEventsOnDate:[today dateCompByAddingDays:2]], 2);
    
    // Skip days
    dailySchedule = [OCKCareSchedule dailyScheduleWithStartDate:today
                                              occurrencesPerDay:3
                                                     daysToSkip:3
                                                        endDate:nil];
                     
    XCTAssertEqual([dailySchedule numberOfEventsOnDate:today], 3);
    XCTAssertEqual([dailySchedule numberOfEventsOnDate:[today dateCompByAddingDays:1]], 0);
    XCTAssertEqual([dailySchedule numberOfEventsOnDate:[today dateCompByAddingDays:4]], 3);
    
    // With end day
    dailySchedule = [OCKCareSchedule dailyScheduleWithStartDate:today
                                              occurrencesPerDay:4
                                                     daysToSkip:0
                                                         endDate:[today dateCompByAddingDays:3]];
    

    XCTAssertEqual([dailySchedule numberOfEventsOnDate:today], 4);
    XCTAssertEqual([dailySchedule numberOfEventsOnDate:[today dateCompByAddingDays:1]], 4);
    XCTAssertEqual([dailySchedule numberOfEventsOnDate:[today dateCompByAddingDays:6]], 0);
    
    // Thresholds
    dailySchedule = [OCKCareSchedule dailyScheduleWithStartDate:today
                                              occurrencesPerDay:3
                                                     daysToSkip:3
                                                        endDate:nil
                                                 dailyThreshold:[OCKCarePlanThreshold adheranceThresholdWithValue:@(2) title:@"Did it at least twice today."]];
    
    XCTAssertEqual([dailySchedule thresholdOnDate:today].value, @(2));
    XCTAssertNil([dailySchedule thresholdOnDate:[today dateCompByAddingDays:1]]);
    XCTAssertEqual([dailySchedule thresholdOnDate:[today dateCompByAddingDays:4]].value, @(2));
    XCTAssertTrue([[dailySchedule thresholdOnDate:today] evaluateThresholdForValue:@(1)]);
    XCTAssertFalse([[dailySchedule thresholdOnDate:today] evaluateThresholdForValue:@(3)]);
}

- (void)testWeeklySchedules {
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSDate *now = [NSDate date];
    NSDateComponents *today = [[NSDateComponents alloc] initWithDate:now calendar:calendar];
    
    NSArray<NSNumber *> *occurrences = @[@(1), @(2), @(3), @(4), @(5), @(6), @(7)];
    
    // Every Week
    OCKCareSchedule *weeklySchedule = [OCKCareSchedule weeklyScheduleWithStartDate:today occurrencesOnEachDay:occurrences];

    NSUInteger weekday = [calendar component:NSCalendarUnitWeekday fromDate:now];
    NSUInteger occurrencesOnDay = occurrences[weekday - 1].unsignedIntegerValue;
    XCTAssertEqual([weeklySchedule numberOfEventsOnDate:today], occurrencesOnDay);
    XCTAssertEqual([weeklySchedule numberOfEventsOnDate:[today dateCompByAddingDays:1]], occurrences[(weekday)%7].unsignedIntegerValue);
    
    // Skip weeks
    weeklySchedule = [OCKCareSchedule weeklyScheduleWithStartDate:today
                                             occurrencesOnEachDay:occurrences
                                                      weeksToSkip:3
                                                          endDate:nil];
    

    XCTAssertEqual([weeklySchedule numberOfEventsOnDate:today], occurrencesOnDay);
    XCTAssertEqual([weeklySchedule numberOfEventsOnDate:[today dateCompByAddingDays:7]], 0);
    XCTAssertEqual([weeklySchedule numberOfEventsOnDate:[today dateCompByAddingDays:4*7]], occurrencesOnDay);
    
    
    // With end day
    weeklySchedule = [OCKCareSchedule weeklyScheduleWithStartDate:today
                                             occurrencesOnEachDay:occurrences
                                                        weeksToSkip:0
                                                            endDate:[today dateCompByAddingDays:3*7]];
    

    XCTAssertEqual([weeklySchedule numberOfEventsOnDate:today], occurrencesOnDay);
    XCTAssertEqual([weeklySchedule numberOfEventsOnDate:[today dateCompByAddingDays:1*7]], occurrencesOnDay);
    XCTAssertEqual([weeklySchedule numberOfEventsOnDate:[today dateCompByAddingDays:6*7]], 0);
    
    // Thresholds
    OCKCarePlanThreshold *threshold0 = [OCKCarePlanThreshold adheranceThresholdWithValue:@(0) title:nil];
    OCKCarePlanThreshold *threshold1 = [OCKCarePlanThreshold adheranceThresholdWithValue:@(1) title:nil];
    OCKCarePlanThreshold *threshold2 = [OCKCarePlanThreshold adheranceThresholdWithValue:@(2) title:nil];
    NSDateComponents *sunday = [today dateCompByAddingDays:3*7 + 1 - weekday];
    
    NSArray<OCKCarePlanThreshold *> *thresholds = @[threshold1, threshold1, threshold1, threshold0, threshold2, threshold2, threshold2];
    weeklySchedule = [OCKCareSchedule weeklyScheduleWithStartDate:today
                                             occurrencesOnEachDay:occurrences
                                                      weeksToSkip:2
                                                          endDate:nil
                                              thresholdsOnEachDay:thresholds];
    
    XCTAssertEqual([weeklySchedule thresholdOnDate:sunday].value, @(1));
    XCTAssertEqual([weeklySchedule thresholdOnDate:[sunday dateCompByAddingDays:3]].value, @(0));
    XCTAssertEqual([weeklySchedule thresholdOnDate:[sunday dateCompByAddingDays:5]].value, @(2));
    XCTAssertNil([weeklySchedule thresholdOnDate:[sunday dateCompByAddingDays:9]]);
    XCTAssertTrue([[weeklySchedule thresholdOnDate:sunday] evaluateThresholdForValue:@(0)]);
    XCTAssertFalse([[weeklySchedule thresholdOnDate:[sunday dateCompByAddingDays:6]] evaluateThresholdForValue:@(4)]);

}

- (void)testDateComponents {
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dc = [NSDateComponents ock_componentsWithDate:[NSDate date] calendar:calendar];
    XCTAssertTrue(dc.weekday > 0 && dc.weekday <=7);
    
    NSInteger count = 0;
    
    while (count < 1000) {
        if (dc.weekday == 7) {
            XCTAssertFalse([dc isInSameWeekAsDate:[dc nextDay]]);
        } else {
            XCTAssertTrue([dc isInSameWeekAsDate:[dc nextDay]]);
        }
        
        dc = [dc nextDay];
        dc = [NSDateComponents ock_componentsWithDate:[calendar dateFromComponents:dc] calendar:calendar];
        count++;
    }
}

- (void)testThresholds {
    
    // Logic check on threshold evaulations
    OCKCarePlanThreshold *threshold = [OCKCarePlanThreshold adheranceThresholdWithValue:@(1) title:@"Didn't Do It"];
    XCTAssertTrue([threshold evaluateThresholdForValue:@(0)]);
    XCTAssertFalse([threshold evaluateThresholdForValue:@(1)]);
    
    threshold = [OCKCarePlanThreshold numericThresholdWithValue:@(4) type:OCKCarePlanThresholdTypeNumericGreaterThan upperValue:nil title:nil];
    XCTAssertTrue([threshold evaluateThresholdForValue:@(6)]);
    XCTAssertFalse([threshold evaluateThresholdForValue:@(4)]);
    XCTAssertFalse([threshold evaluateThresholdForValue:@(3)]);
    
    threshold = [OCKCarePlanThreshold numericThresholdWithValue:@(4) type:OCKCarePlanThresholdTypeNumericGreaterThanOrEqual upperValue:nil title:nil];
    XCTAssertTrue([threshold evaluateThresholdForValue:@(6)]);
    XCTAssertTrue([threshold evaluateThresholdForValue:@(4)]);
    XCTAssertFalse([threshold evaluateThresholdForValue:@(3)]);
    
    threshold = [OCKCarePlanThreshold numericThresholdWithValue:@(4) type:OCKCarePlanThresholdTypeNumericLessThan upperValue:nil title:nil];
    XCTAssertFalse([threshold evaluateThresholdForValue:@(6)]);
    XCTAssertFalse([threshold evaluateThresholdForValue:@(4)]);
    XCTAssertTrue([threshold evaluateThresholdForValue:@(3)]);
    
    threshold = [OCKCarePlanThreshold numericThresholdWithValue:@(4) type:OCKCarePlanThresholdTypeNumericLessThanOrEqual upperValue:nil title:nil];
    XCTAssertFalse([threshold evaluateThresholdForValue:@(6)]);
    XCTAssertTrue([threshold evaluateThresholdForValue:@(4)]);
    XCTAssertTrue([threshold evaluateThresholdForValue:@(3)]);
    
    threshold = [OCKCarePlanThreshold numericThresholdWithValue:@(4) type:OCKCarePlanThresholdTypeNumericEqual upperValue:nil title:nil];
    XCTAssertFalse([threshold evaluateThresholdForValue:@(6)]);
    XCTAssertTrue([threshold evaluateThresholdForValue:@(4)]);
    XCTAssertFalse([threshold evaluateThresholdForValue:@(3)]);
    
    threshold = [OCKCarePlanThreshold numericThresholdWithValue:@(4) type:OCKCarePlanThresholdTypeNumericRangeInclusive upperValue:@(7) title:nil];
    XCTAssertFalse([threshold evaluateThresholdForValue:@(9)]);
    XCTAssertTrue([threshold evaluateThresholdForValue:@(7)]);
    XCTAssertTrue([threshold evaluateThresholdForValue:@(5)]);
    XCTAssertTrue([threshold evaluateThresholdForValue:@(4)]);
    XCTAssertFalse([threshold evaluateThresholdForValue:@(3)]);

    threshold = [OCKCarePlanThreshold numericThresholdWithValue:@(4) type:OCKCarePlanThresholdTypeNumericRangeExclusive upperValue:@(7) title:nil];
    XCTAssertFalse([threshold evaluateThresholdForValue:@(9)]);
    XCTAssertFalse([threshold evaluateThresholdForValue:@(7)]);
    XCTAssertTrue([threshold evaluateThresholdForValue:@(5)]);
    XCTAssertFalse([threshold evaluateThresholdForValue:@(4)]);
    XCTAssertFalse([threshold evaluateThresholdForValue:@(3)]);
    
    ///////////////////////
    // Core Data Storage //
    ///////////////////////
    
    NSURL *directoryURL = [NSURL fileURLWithPath:[self cleanTestPath]];
    OCKCarePlanStore *store = [[OCKCarePlanStore alloc] initWithPersistenceDirectoryURL:directoryURL];
    store.delegate = self;
    NSDateComponents *startDate = [[NSDateComponents alloc] initWithYear:2016 month:01 day:01];
    XCTestExpectation *expectation;

    
    // Adherance Thresholds
    
    threshold = [OCKCarePlanThreshold adheranceThresholdWithValue:@(2)
                                                                                  title:@"Did not complete activity"];
    
    OCKCareSchedule *schedule = [OCKCareSchedule dailyScheduleWithStartDate:startDate
                                         occurrencesPerDay:2
                                                daysToSkip:1
                                                   endDate:nil
                                            dailyThreshold:threshold];
    
    
    OCKCarePlanActivity *activity = [OCKCarePlanActivity assessmentWithIdentifier:@"Activity1"
                                                                  groupIdentifier:nil
                                                                            title:@"The First Activity"
                                                                             text:@"To be performed twice every other day."
                                                                        tintColor:nil
                                                                 resultResettable:YES
                                                                         schedule:schedule
                                                                         userInfo:nil
                                                                       thresholds:nil
                                                                         optional:false];
    
    __block NSMutableArray<OCKCarePlanEvent *> *eventsArray;
    
    expectation = [self expectationWithDescription:@"Add activity 1"];
    [store addActivity:activity completion:^(BOOL success, NSError * _Nullable error) {
        XCTAssertTrue(success);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertTrue([self isListChangeDelegateCalled]);
    }];
    
    
    [store activityForIdentifier:activity.identifier completion:^(BOOL success, OCKCarePlanActivity * _Nullable cdActivity, NSError * _Nullable error) {
        XCTAssertTrue(success);
        XCTAssertEqualObjects(cdActivity, activity);
        OCKCarePlanThreshold *cdAdheranceThreshold = [cdActivity.schedule thresholdOnDate:startDate];
        XCTAssertTrue([cdAdheranceThreshold evaluateThresholdForValue:@(1)]);
        XCTAssertFalse([cdAdheranceThreshold evaluateThresholdForValue:@(2)]);
        
        cdAdheranceThreshold = [cdActivity.schedule thresholdOnDate:[startDate dateCompByAddingDays:1]];
        XCTAssertNil(cdAdheranceThreshold);
    }];
    
    expectation = [self expectationWithDescription:@"Get events 1"];
    [store eventsForActivity:activity date:startDate completion:^(NSArray<OCKCarePlanEvent *> * _Nonnull events, NSError * _Nullable error) {
        XCTAssertNotNil(events);
        XCTAssertEqual(events.count, 2);
        XCTAssertEqual(events[0].state, OCKCarePlanEventStateInitial);
        XCTAssertEqual(events[1].state, OCKCarePlanEventStateInitial);
        
        eventsArray = [NSMutableArray arrayWithArray:events];
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    [store evaluateAdheranceThresholdForActivity:activity date:startDate completion:^(BOOL success, OCKCarePlanThreshold * _Nullable cdThreshold, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertEqualObjects(threshold, cdThreshold);
    }];
    
    [store evaluateAdheranceThresholdForActivity:activity date:[startDate dateCompByAddingDays:1] completion:^(BOOL success, OCKCarePlanThreshold * _Nullable cdThreshold, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertNil(cdThreshold);
    }];
    
    expectation = [self expectationWithDescription:@"Update event 1.1"];
    [store updateEvent:eventsArray[0] withResult:nil state:OCKCarePlanEventStateCompleted completion:^(BOOL success, OCKCarePlanEvent * _Nullable event, NSError * _Nullable error) {
        XCTAssertTrue(success);
        XCTAssertEqual(event.state, OCKCarePlanEventStateCompleted);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertTrue([self isEventChangeDelegateCalled]);
    }];
    
    [store evaluateAdheranceThresholdForActivity:activity date:startDate completion:^(BOOL success, OCKCarePlanThreshold * _Nullable cdThreshold, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertEqualObjects(threshold, cdThreshold);
    }];
    
    [store evaluateAdheranceThresholdForActivity:activity date:[startDate dateCompByAddingDays:1] completion:^(BOOL success, OCKCarePlanThreshold * _Nullable cdThreshold, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertNil(cdThreshold);
    }];
    
    expectation = [self expectationWithDescription:@"Update event 1.2"];
    [store updateEvent:eventsArray[1] withResult:nil state:OCKCarePlanEventStateCompleted completion:^(BOOL success, OCKCarePlanEvent * _Nullable event, NSError * _Nullable error) {
        XCTAssertTrue(success);
        XCTAssertEqual(event.state, OCKCarePlanEventStateCompleted);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertTrue([self isEventChangeDelegateCalled]);
    }];
    
    [store evaluateAdheranceThresholdForActivity:activity date:startDate completion:^(BOOL success, OCKCarePlanThreshold * _Nullable cdThreshold, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertEqualObjects(threshold, cdThreshold);
    }];
    
    [store evaluateAdheranceThresholdForActivity:activity date:[startDate dateCompByAddingDays:1] completion:^(BOOL success, OCKCarePlanThreshold * _Nullable cdThreshold, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertNil(cdThreshold);
    }];
    
    [store evaluateAdheranceThresholdForActivity:activity date:[startDate dateCompByAddingDays:2] completion:^(BOOL success, OCKCarePlanThreshold * _Nullable cdThreshold, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertEqualObjects(threshold, cdThreshold);
    }];
    
    
    // Numeric Thresholds
    
    OCKCarePlanThreshold *lowThreshold = [OCKCarePlanThreshold numericThresholdWithValue:@(3) type:OCKCarePlanThresholdTypeNumericLessThanOrEqual upperValue:nil title:@"A score <= 3!"];
    OCKCarePlanThreshold *highThreshold = [OCKCarePlanThreshold numericThresholdWithValue:@(7) type:OCKCarePlanThresholdTypeNumericGreaterThan upperValue:nil title:@"A score > 7!"];
    
    schedule = [OCKCareSchedule dailyScheduleWithStartDate:startDate occurrencesPerDay:1 daysToSkip:1 endDate:nil];
    
    OCKCarePlanActivity *activity2 = [OCKCarePlanActivity assessmentWithIdentifier:@"mood"
                                                                   groupIdentifier:nil
                                                                             title:@"Mood Score"
                                                                              text:@"How would you rate your mood right now?"
                                                                         tintColor:nil
                                                                  resultResettable:YES
                                                                          schedule:schedule
                                                                          userInfo:nil
                                                                        thresholds:@[@[lowThreshold, highThreshold]]
                                                                          optional:false];
    
    expectation = [self expectationWithDescription:@"Add activity 2"];
    [store addActivity:activity2 completion:^(BOOL success, NSError * _Nullable error) {
        XCTAssertTrue(success);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertTrue([self isListChangeDelegateCalled]);
    }];
    
    expectation = [self expectationWithDescription:@"Get events 2.1"];
    [eventsArray removeAllObjects];
    [store enumerateEventsOfActivity:activity2 startDate:startDate endDate:[startDate dateCompByAddingDays:6] handler:^(OCKCarePlanEvent * _Nullable event, BOOL * _Nonnull stop) {
        if (event) {
            [eventsArray addObject:event];
        }
    } completion:^(BOOL completed, NSError * _Nullable error) {
        XCTAssertTrue(completed);
        XCTAssertNil(error);
        XCTAssertEqual(eventsArray.count, 4);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    OCKCarePlanEventResult *middleResult = [[OCKCarePlanEventResult alloc] initWithValueString:@"5" unitString:@"" userInfo:nil values:@[@(5)]];
    OCKCarePlanEventResult *lowResult = [[OCKCarePlanEventResult alloc] initWithValueString:@"2" unitString:@"" userInfo:nil values:@[@(2)]];
    OCKCarePlanEventResult *highResult = [[OCKCarePlanEventResult alloc] initWithValueString:@"9" unitString:@"" userInfo:nil values:@[@(9)]];
    
    expectation = [self expectationWithDescription:@"Update event results 2.1"];
    [store updateEvent:eventsArray[0] withResult:middleResult state:OCKCarePlanEventStateCompleted completion:^(BOOL success, OCKCarePlanEvent * _Nullable event, NSError * _Nullable error) {
        XCTAssertTrue(success);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertTrue([self isEventChangeDelegateCalled]);
    }];
    
    expectation = [self expectationWithDescription:@"Update event results 2.2"];
    [store updateEvent:eventsArray[1] withResult:lowResult state:OCKCarePlanEventStateCompleted completion:^(BOOL success, OCKCarePlanEvent * _Nullable event, NSError * _Nullable error) {
        XCTAssertTrue(success);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertTrue([self isEventChangeDelegateCalled]);
    }];
    
    expectation = [self expectationWithDescription:@"Update event results 2.3"];
    [store updateEvent:eventsArray[2] withResult:highResult state:OCKCarePlanEventStateCompleted completion:^(BOOL success, OCKCarePlanEvent * _Nullable event, NSError * _Nullable error) {
        XCTAssertTrue(success);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertTrue([self isEventChangeDelegateCalled]);
    }];
    
    expectation = [self expectationWithDescription:@"Get events 2.2"];
    [eventsArray removeAllObjects];
    [store enumerateEventsOfActivity:activity2 startDate:startDate endDate:[startDate dateCompByAddingDays:6] handler:^(OCKCarePlanEvent * _Nullable event, BOOL * _Nonnull stop) {
        if (event) {
            [eventsArray addObject:event];
        }
    } completion:^(BOOL completed, NSError * _Nullable error) {
        XCTAssertTrue(completed);
        XCTAssertNil(error);
        XCTAssertEqual(eventsArray.count, 4);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    NSArray<NSArray<OCKCarePlanThreshold *> *> *triggeredThresholds = [eventsArray[0] evaluateNumericThresholds];
    XCTAssertEqual(triggeredThresholds.count, 1);
    XCTAssertEqual(triggeredThresholds[0].count, 0);
    
    triggeredThresholds = [eventsArray[1] evaluateNumericThresholds];
    XCTAssertEqual(triggeredThresholds.count, 1);
    XCTAssertEqual(triggeredThresholds[0].count, 1);
    XCTAssertEqualObjects(triggeredThresholds[0][0], lowThreshold);

    triggeredThresholds = [eventsArray[2] evaluateNumericThresholds];
    XCTAssertEqual(triggeredThresholds.count, 1);
    XCTAssertEqual(triggeredThresholds[0].count, 1);
    XCTAssertEqualObjects(triggeredThresholds[0][0], highThreshold);
    
    triggeredThresholds = [eventsArray[3] evaluateNumericThresholds];
    XCTAssertEqual(triggeredThresholds.count, 0);
    
    // 2-valued numeric thresholds
    
    OCKCarePlanThreshold *lowSystolicThreshold = [OCKCarePlanThreshold numericThresholdWithValue:@(100) type:OCKCarePlanThresholdTypeNumericLessThanOrEqual upperValue:nil title:@"A low systolic blood pressure."];
    OCKCarePlanThreshold *highSystolicThreshold = [OCKCarePlanThreshold numericThresholdWithValue:@(140) type:OCKCarePlanThresholdTypeNumericGreaterThanOrEqual upperValue:nil title:@"A high systolic blood pressure."];
    OCKCarePlanThreshold *veryHighSystolicThreshold = [OCKCarePlanThreshold numericThresholdWithValue:@(180) type:OCKCarePlanThresholdTypeNumericGreaterThanOrEqual upperValue:nil title:@"A crazy high systolic blood pressure!"];
    OCKCarePlanThreshold *middleDiastolicThreshold = [OCKCarePlanThreshold numericThresholdWithValue:@(65) type:OCKCarePlanThresholdTypeNumericRangeInclusive upperValue:@(85) title:@"A good diastolic blood pressure."];
    
    OCKCarePlanActivity *activity3 = [OCKCarePlanActivity assessmentWithIdentifier:@"bloodPressure"
                                                                   groupIdentifier:nil
                                                                             title:@"Blood Pressure"
                                                                              text:@"Systolic-Diastolic blood pressure."
                                                                         tintColor:nil
                                                                  resultResettable:YES
                                                                          schedule:schedule
                                                                          userInfo:nil
                                                                        thresholds:@[@[lowSystolicThreshold, highSystolicThreshold, veryHighSystolicThreshold], @[middleDiastolicThreshold]]
                                                                          optional:false];
    
    expectation = [self expectationWithDescription:@"Add activity 3"];
    [store addActivity:activity3 completion:^(BOOL success, NSError * _Nullable error) {
        XCTAssertTrue(success);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertTrue([self isListChangeDelegateCalled]);
    }];
    
    expectation = [self expectationWithDescription:@"Get events 3.1"];
    [eventsArray removeAllObjects];
    [store enumerateEventsOfActivity:activity3 startDate:startDate endDate:[startDate dateCompByAddingDays:14] handler:^(OCKCarePlanEvent * _Nullable event, BOOL * _Nonnull stop) {
        if (event) {
            [eventsArray addObject:event];
        }
    } completion:^(BOOL completed, NSError * _Nullable error) {
        XCTAssertTrue(completed);
        XCTAssertNil(error);
        XCTAssertEqual(eventsArray.count, 8);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    NSArray<OCKCarePlanEventResult *> *results = @[[[OCKCarePlanEventResult alloc] initWithValueString:@"120-80" unitString:@"" userInfo:nil values:@[@(120), @(80)]],
                                                   [[OCKCarePlanEventResult alloc] initWithValueString:@"160-80" unitString:@"" userInfo:nil values:@[@(160), @(80)]],
                                                   [[OCKCarePlanEventResult alloc] initWithValueString:@"90-80" unitString:@"" userInfo:nil values:@[@(90), @(80)]],
                                                   [[OCKCarePlanEventResult alloc] initWithValueString:@"120-90" unitString:@"" userInfo:nil values:@[@(120), @(90)]],
                                                   [[OCKCarePlanEventResult alloc] initWithValueString:@"160-90" unitString:@"" userInfo:nil values:@[@(160), @(90)]],
                                                   [[OCKCarePlanEventResult alloc] initWithValueString:@"90-90" unitString:@"" userInfo:nil values:@[@(90), @(90)]],
                                                   [[OCKCarePlanEventResult alloc] initWithValueString:@"200-80" unitString:@"" userInfo:nil values:@[@(200), @(80)]]
                                                   ];
    
    for (int index = 0; index < results.count; index++) {
        expectation = [self expectationWithDescription:[NSString stringWithFormat:@"Update event results 3.%d", index + 1]];
        [store updateEvent:eventsArray[index] withResult:results[index] state:OCKCarePlanEventStateCompleted completion:^(BOOL success, OCKCarePlanEvent * _Nullable event, NSError * _Nullable error) {
            XCTAssertTrue(success);
            XCTAssertNil(error);
            [expectation fulfill];
        }];
        [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {
            XCTAssertNil(error);
            XCTAssertTrue([self isEventChangeDelegateCalled]);
        }];
    }
    
    expectation = [self expectationWithDescription:@"Get events 3.2"];
    [eventsArray removeAllObjects];
    [store enumerateEventsOfActivity:activity3 startDate:startDate endDate:[startDate dateCompByAddingDays:14] handler:^(OCKCarePlanEvent * _Nullable event, BOOL * _Nonnull stop) {
        if (event) {
            [eventsArray addObject:event];
        }
    } completion:^(BOOL completed, NSError * _Nullable error) {
        XCTAssertTrue(completed);
        XCTAssertNil(error);
        XCTAssertEqual(eventsArray.count, 8);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    triggeredThresholds = [eventsArray[0] evaluateNumericThresholds];
    XCTAssertEqual(triggeredThresholds.count, 2);
    XCTAssertEqual(triggeredThresholds[0].count, 0);
    XCTAssertEqual(triggeredThresholds[1].count, 1);
    XCTAssertEqualObjects(triggeredThresholds[1][0], middleDiastolicThreshold);
    
    triggeredThresholds = [eventsArray[1] evaluateNumericThresholds];
    XCTAssertEqual(triggeredThresholds.count, 2);
    XCTAssertEqual(triggeredThresholds[0].count, 1);
    XCTAssertEqualObjects(triggeredThresholds[0][0], highSystolicThreshold);
    XCTAssertEqual(triggeredThresholds[1].count, 1);
    XCTAssertEqualObjects(triggeredThresholds[1][0], middleDiastolicThreshold);
    
    triggeredThresholds = [eventsArray[2] evaluateNumericThresholds];
    XCTAssertEqual(triggeredThresholds.count, 2);
    XCTAssertEqual(triggeredThresholds[0].count, 1);
    XCTAssertEqualObjects(triggeredThresholds[0][0], lowSystolicThreshold);
    XCTAssertEqual(triggeredThresholds[1].count, 1);
    XCTAssertEqualObjects(triggeredThresholds[1][0], middleDiastolicThreshold);
    
    triggeredThresholds = [eventsArray[3] evaluateNumericThresholds];
    XCTAssertEqual(triggeredThresholds.count, 2);
    XCTAssertEqual(triggeredThresholds[0].count, 0);
    XCTAssertEqual(triggeredThresholds[1].count, 0);
    
    triggeredThresholds = [eventsArray[4] evaluateNumericThresholds];
    XCTAssertEqual(triggeredThresholds.count, 2);
    XCTAssertEqual(triggeredThresholds[0].count, 1);
    XCTAssertEqualObjects(triggeredThresholds[0][0], highSystolicThreshold);
    XCTAssertEqual(triggeredThresholds[1].count, 0);
    
    triggeredThresholds = [eventsArray[5] evaluateNumericThresholds];
    XCTAssertEqual(triggeredThresholds.count, 2);
    XCTAssertEqual(triggeredThresholds[0].count, 1);
    XCTAssertEqualObjects(triggeredThresholds[0][0], lowSystolicThreshold);
    XCTAssertEqual(triggeredThresholds[1].count, 0);
    
    triggeredThresholds = [eventsArray[6] evaluateNumericThresholds];
    XCTAssertEqual(triggeredThresholds.count, 2);
    XCTAssertEqual(triggeredThresholds[0].count, 2);
    XCTAssertTrue([triggeredThresholds[0] containsObject:highSystolicThreshold]);
    XCTAssertTrue([triggeredThresholds[0] containsObject:veryHighSystolicThreshold]);
    XCTAssertEqual(triggeredThresholds[1].count, 1);
    XCTAssertEqualObjects(triggeredThresholds[1][0], middleDiastolicThreshold);
    
    triggeredThresholds = [eventsArray[7] evaluateNumericThresholds];
    XCTAssertEqual(triggeredThresholds.count, 0);
}

- (void)testResults {
    // Custom created results (no HKSample).
    OCKCarePlanEventResult *customResult = [[OCKCarePlanEventResult alloc] initWithValueString:@"10"
                                                                                    unitString:@"mg"
                                                                                      userInfo:nil];
    XCTAssert([customResult.valueString isEqualToString:@"10"]);
    XCTAssertNil(customResult.values);
    
    customResult = [customResult initWithValueString:@"10"
                                                            unitString:@"mg"
                                                              userInfo:nil
                                                                values:nil];
    XCTAssert([customResult.valueString isEqualToString:@"10"]);
    XCTAssertNil(customResult.values);
    
    customResult = [customResult initWithValueString:@"10"
                                                            unitString:@"mg"
                                                              userInfo:nil
                                                                values:@[@(10)]];
    XCTAssert([customResult.valueString isEqualToString:@"10"]);
    XCTAssertNotNil(customResult.values);
    XCTAssertEqual(customResult.values.count, 1);
    XCTAssertEqual(customResult.values[0], @(10));
    
    // Single HKSample result.
    HKQuantitySample *sample = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight]
                                                       quantity:[HKQuantity quantityWithUnit:[HKUnit meterUnit] doubleValue:1.85]
                                                      startDate:[NSDate date]
                                                        endDate:[NSDate date]];
    
    OCKCarePlanEventResult *sampleResult = [[OCKCarePlanEventResult alloc] initWithQuantitySample:sample
                                                                          quantityStringFormatter:nil
                                                                                      displayUnit:[HKUnit meterUnit]
                                                                             displayUnitStringKey:@"m"
                                                                                         userInfo:nil];

    XCTAssert([sampleResult.valueString isEqualToString:@"1.85"]);
    XCTAssertNotNil(sampleResult.values);
    XCTAssertEqual(sampleResult.values.count, 1);
    XCTAssertEqual(sampleResult.values[0].doubleValue, 1.85);
    
    // Double HKSample result (blood pressure).
    HKQuantitySample *diastolicSample = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodPressureDiastolic]
                                                                        quantity:[HKQuantity quantityWithUnit:[HKUnit millimeterOfMercuryUnit] doubleValue:120]
                                                                       startDate:[NSDate date]
                                                                         endDate:[NSDate date]];
    HKQuantitySample *systolicSample = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodPressureSystolic]
                                                                       quantity:[HKQuantity quantityWithUnit:[HKUnit millimeterOfMercuryUnit] doubleValue:80]
                                                                      startDate:[NSDate date]
                                                                        endDate:[NSDate date]];
    HKCorrelation *bloodPressure = [HKCorrelation correlationWithType:[HKCorrelationType correlationTypeForIdentifier:HKCorrelationTypeIdentifierBloodPressure] startDate:[NSDate date] endDate:[NSDate date] objects:[NSSet setWithObjects:diastolicSample, systolicSample, nil]];
    
    OCKCarePlanEventResult *correlationResult = [[OCKCarePlanEventResult alloc] initWithCorrelation:bloodPressure
                                                                            quantityStringFormatter:nil
                                                                                        displayUnit:[HKUnit millimeterOfMercuryUnit]
                                                                                     unitStringKeys:@{[HKUnit millimeterOfMercuryUnit] : @"mmHg"}
                                                                                           userInfo:nil];
    
    XCTAssertNotNil(correlationResult.values);
    XCTAssertEqual(correlationResult.values.count, 2);
    XCTAssertEqual(correlationResult.values[0].doubleValue, 120);
    XCTAssertEqual(correlationResult.values[1].doubleValue, 80);
    
}

- (void)carePlanStoreActivityListDidChange:(OCKCarePlanStore *)store {
    XCTAssertTrue([NSThread isMainThread]);
    XCTAssertFalse(_listChanged);
    _listChanged = YES;
}

- (void)carePlanStore:(OCKCarePlanStore *)store didReceiveUpdateOfEvent:(nonnull OCKCarePlanEvent *)event {
    XCTAssertTrue([NSThread isMainThread]);
    XCTAssertNil(_event);
    _event = event;
}

@end
