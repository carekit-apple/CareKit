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
                                                                        userInfo:@{@"key":@"value1"}];
    
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
                                                                        userInfo:@{@"key":@"value2"}];
    
    OCKCarePlanActivity *item3 = [OCKCarePlanActivity assessmentWithIdentifier:@"id3"
                                                               groupIdentifier:@"gid3"
                                                                         title:@"title3"
                                                                          text:@"text3"
                                                                     tintColor:[UIColor greenColor]
                                                              resultResettable:YES
                                                                      schedule:schedule
                                                                      userInfo:@{@"key":@"value3"}];
    
    OCKCarePlanActivity *item4 = [OCKCarePlanActivity interventionWithIdentifier:@"id4"
                                                                 groupIdentifier:@"gid4"
                                                                           title:@"title4"
                                                                            text:@"text4"
                                                                       tintColor:[UIColor redColor]
                                                                    instructions:@"detailText4"
                                                                        imageURL:url4
                                                                        schedule:schedule
                                                                        userInfo:@{@"key":@"value4"}];
    
    
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
