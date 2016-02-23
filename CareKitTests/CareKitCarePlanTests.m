//
//  CareKitTests.m
//  CareKitTests
//
//  Created by Yuan Zhu on 1/19/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <XCTest/XCTest.h>
#import <CareKit/CareKit.h>
#import "OCKCarePlanDay_Internal.h"

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
    
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    OCKCarePlanDay *startDay = [[OCKCarePlanDay alloc] initWithDate:[NSDate date] calendar:calendar];
    
    OCKCareSchedule *schedule = [OCKCareSchedule dailyScheduleWithStartDay:startDay occurrencesPerDay:3];
    
    OCKCarePlanActivity *item1 = [[OCKCarePlanActivity alloc] initWithIdentifier:@"id1"
                                                                 groupIdentifier:@"gid1"
                                                                            type:OCKCarePlanActivityTypeIntervention
                                                                           title:@"title1"
                                                                            text:@"text1"
                                                                       tintColor:[UIColor redColor]
                                                                        schedule:schedule
                                                                        optional:YES
                                                           numberOfDaysWriteable:1
                                                                resultResettable:YES
                                                                        userInfo:@{@"key":@"value1"}];
    
    OCKCareSchedule *weeklySchedule = [OCKCareSchedule weeklyScheduleWithStartDay:startDay
                                                             occurrencesOnEachDay:@[@3, @3, @3, @3, @3, @3, @3]];
    
    OCKCarePlanActivity *item2 = [[OCKCarePlanActivity alloc] initWithIdentifier:@"id2"
                                                                            type:OCKCarePlanActivityTypeIntervention
                                                                           title:@"title2"
                                                                            text:@"text2"
                                                                       tintColor:[UIColor redColor]
                                                                        schedule:weeklySchedule];
    
    OCKCarePlanActivity *item3 = [[OCKCarePlanActivity alloc] initWithIdentifier:@"id3"
                                                                            type:OCKCarePlanActivityTypeAssessment
                                                                           title:@"title3"
                                                                            text:@"text3"
                                                                       tintColor:[UIColor redColor]
                                                                        schedule:schedule];
    
    OCKCarePlanActivity *item4 = [[OCKCarePlanActivity alloc] initWithIdentifier:@"id4"
                                                                            type:OCKCarePlanActivityTypeIntervention
                                                                           title:@"title4"
                                                                            text:@"text4"
                                                                       tintColor:[UIColor orangeColor]
                                                                        schedule:weeklySchedule];
    
    
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
    
    
    expectation = [self expectationWithDescription:@"add2"];
    [store addActivity:item2 completion:^(BOOL success, NSError * _Nonnull error) {
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
    
    store = [[OCKCarePlanStore alloc] initWithPersistenceDirectoryURL:directoryURL];
    store.delegate = self;
    
    expectation = [self expectationWithDescription:@"activityForIdentifier"];
    [store activityForIdentifier:item1.identifier
                      completion:^(BOOL success, OCKCarePlanActivity * _Nonnull activity, NSError * _Nonnull error) {
                          XCTAssertTrue(success);
                          XCTAssertEqualObjects(activity, item1);
                          XCTAssertNil(error);
                          [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    
    expectation = [self expectationWithDescription:@"activityForIdentifier"];
    [store activityForIdentifier:item2.identifier
                      completion:^(BOOL success, OCKCarePlanActivity * _Nonnull activity, NSError * _Nonnull error) {
                          XCTAssertTrue(success);
                          XCTAssertEqualObjects(activity, item2);
                          XCTAssertNil(error);
                          [expectation fulfill];
                      }];
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    expectation = [self expectationWithDescription:@"activityForIdentifier"];
    [store activityForIdentifier:item3.identifier
                      completion:^(BOOL success, OCKCarePlanActivity * _Nonnull activity, NSError * _Nonnull error) {
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
    
    __block NSArray<OCKCarePlanActivity *> *activities;
    
    expectation = [self expectationWithDescription:@"activities"];
    [store activitiesWithCompletion:^(BOOL success, NSArray<OCKCarePlanActivity *> * _Nonnull activityArray, NSError * _Nonnull error) {
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
    XCTAssertEqualObjects(activities[1], item2);
    XCTAssertEqualObjects(activities[2], item3);
    
    NSDate *endDate = [NSDate dateWithTimeIntervalSinceNow:8*24*60*60];
    OCKCarePlanDay *endDay = [[OCKCarePlanDay alloc] initWithDate:endDate calendar:[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian]];
    expectation = [self expectationWithDescription:@"setEndDate"];
    [store setEndDay:endDay
         forActivity:activities[2]
          completion:^(BOOL success, OCKCarePlanActivity * _Nonnull activity, NSError * _Nonnull error) {
               XCTAssertTrue(success);
               XCTAssertNil(error);
               XCTAssertEqualObjects(activity.schedule.endDay, endDay);
               [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];

    activities = nil;
    expectation = [self expectationWithDescription:@"activities2"];
    [store activitiesWithCompletion:^(BOOL success, NSArray<OCKCarePlanActivity *> * _Nonnull activityArray, NSError * _Nonnull error) {
        XCTAssertTrue(success);
        XCTAssertNil(error);
        XCTAssertEqual(activityArray.count, 4);
        activities = activityArray;
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    XCTAssertEqualObjects(activities[2].schedule.endDay, endDay, @"%@", activities[2].identifier);
    XCTAssertTrue([self isListChangeDelegateCalled]);
    
    expectation = [self expectationWithDescription:@"removeActivity"];
    [store removeActivity:activities[2] completion:^(BOOL success, NSError * _Nonnull error) {
        XCTAssertTrue(success);
        XCTAssertNil(error);
       [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    XCTAssertTrue([self isListChangeDelegateCalled]);
    
    expectation = [self expectationWithDescription:@"activities"];
    [store activitiesWithCompletion:^(BOOL success, NSArray<OCKCarePlanActivity *> * _Nonnull activityArray, NSError * _Nonnull error) {
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
    [store eventsOfDay:startDay
                  type:OCKCarePlanActivityTypeIntervention
            completion:^(NSArray<NSArray<OCKCarePlanEvent *> *> * _Nonnull eventsGroupedByActivity, NSError * _Nonnull error) {
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
                         XCTAssertNil(error);
                         XCTAssertTrue(success);
                         [expectation fulfill];
                     }];
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    XCTAssertTrue([self isEventChangeDelegateCalled]);
    
    expectation = [self expectationWithDescription:@"fetchTreatmentEvents"];
    [store eventsOfDay:startDay
                  type:OCKCarePlanActivityTypeIntervention
            completion:^(NSArray<NSArray<OCKCarePlanEvent *> *> * _Nonnull eventsGroupedByActivity, NSError * _Nonnull error) {
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
                XCTAssertNil(error);
                XCTAssertTrue(success);
                [expectation fulfill];
            }];
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    XCTAssertTrue([self isEventChangeDelegateCalled]);
    
    expectation = [self expectationWithDescription:@"fetchTreatmentEvents"];
    [store eventsOfDay:startDay
                  type:OCKCarePlanActivityTypeIntervention
            completion:^(NSArray<NSArray<OCKCarePlanEvent *> *> * _Nonnull eventsGroupedByActivity, NSError * _Nonnull error) {
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
    NSMutableArray<OCKCarePlanEvent *> *eventsOfActivity = [[NSMutableArray alloc] init];
    OCKCarePlanDay *futureDay = [[OCKCarePlanDay alloc] initWithDate:[NSDate dateWithTimeIntervalSinceNow:100*24*60*60] calendar:calendar];
    [store enumerateEventsOfActivity:activities[0] startDay:startDay endDay:futureDay
                           usingBlock:^(OCKCarePlanEvent * _Nonnull event, BOOL * _Nonnull stop, NSError * _Nonnull error) {
                               XCTAssertNil(error);
                               XCTAssertNotNil(event);
                               [eventsOfActivity addObject:event];
                               if (eventsOfActivity.count == 303) {
                                   [expectation fulfill];
                               }
                           }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError * _Nullable error) {
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
                          XCTAssertNil(error);
                          XCTAssertTrue(success, @"%@: %@", event, error);
                          [expectation fulfill];
            }];
        }
        
        [self waitForExpectationsWithTimeout:10.0 handler:^(NSError * _Nullable error) {
            XCTAssertNil(error);
        }];
    }];
}


- (void)testDailySchedules {
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSDate *now = [NSDate date];
    OCKCarePlanDay *today = [[OCKCarePlanDay alloc] initWithDate:now calendar:calendar];
    
    // Every Day
    OCKCareSchedule *dailySchedule = [OCKCareSchedule dailyScheduleWithStartDay:today occurrencesPerDay:2];
    XCTAssertEqual([dailySchedule numberOfEventsOnDay:[today nextDay]], 2);
    XCTAssertEqual([dailySchedule numberOfEventsOnDay:[today dayByAddingDays:2]], 2);
    
    // Skip days
    dailySchedule = [OCKCareSchedule dailyScheduleWithStartDay:today
                                              occurrencesPerDay:3
                                                     daysToSkip:3
                                                        endDay:nil];
                     
    XCTAssertEqual([dailySchedule numberOfEventsOnDay:today], 3);
    XCTAssertEqual([dailySchedule numberOfEventsOnDay:[today dayByAddingDays:1]], 0);
    XCTAssertEqual([dailySchedule numberOfEventsOnDay:[today dayByAddingDays:4]], 3);
    
    // With end day
    dailySchedule = [OCKCareSchedule dailyScheduleWithStartDay:today
                                              occurrencesPerDay:4
                                                     daysToSkip:0
                                                         endDay:[today dayByAddingDays:3]];
    

    XCTAssertEqual([dailySchedule numberOfEventsOnDay:today], 4);
    XCTAssertEqual([dailySchedule numberOfEventsOnDay:[today dayByAddingDays:1]], 4);
    XCTAssertEqual([dailySchedule numberOfEventsOnDay:[today dayByAddingDays:6]], 0);
    
}

- (void)testWeeklySchedules {
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSDate *now = [NSDate date];
    OCKCarePlanDay *today = [[OCKCarePlanDay alloc] initWithDate:now calendar:calendar];
    
    NSArray<NSNumber *> *occurrences = @[@(1), @(2), @(3), @(4), @(5), @(6), @(7)];
    
    // Every Week
    OCKCareSchedule *weeklySchedule = [OCKCareSchedule weeklyScheduleWithStartDay:today occurrencesOnEachDay:occurrences];

    NSUInteger weekday = [calendar component:NSCalendarUnitWeekday fromDate:now];
    NSUInteger occurrencesOnDay = occurrences[weekday - 1].unsignedIntegerValue;
    XCTAssertEqual([weeklySchedule numberOfEventsOnDay:today], occurrencesOnDay);
    XCTAssertEqual([weeklySchedule numberOfEventsOnDay:[today dayByAddingDays:1]], occurrences[(weekday)%7].unsignedIntegerValue);
    
    // Skip weeks
    weeklySchedule = [OCKCareSchedule weeklyScheduleWithStartDay:today
                                             occurrencesOnEachDay:occurrences
                                                      weeksToSkip:3
                                                          endDay:nil];
    

    XCTAssertEqual([weeklySchedule numberOfEventsOnDay:today], occurrencesOnDay);
    XCTAssertEqual([weeklySchedule numberOfEventsOnDay:[today dayByAddingDays:7]], 0);
    XCTAssertEqual([weeklySchedule numberOfEventsOnDay:[today dayByAddingDays:4*7]], occurrencesOnDay);
    
    
    // With end day
    weeklySchedule = [OCKCareSchedule weeklyScheduleWithStartDay:today
                                             occurrencesOnEachDay:occurrences
                                                        weeksToSkip:0
                                                            endDay:[today dayByAddingDays:3*7]];
    

    XCTAssertEqual([weeklySchedule numberOfEventsOnDay:today], occurrencesOnDay);
    XCTAssertEqual([weeklySchedule numberOfEventsOnDay:[today dayByAddingDays:1*7]], occurrencesOnDay);
    XCTAssertEqual([weeklySchedule numberOfEventsOnDay:[today dayByAddingDays:6*7]], 0);
    
}

- (void)testMonthlySchedules {

    OCKCarePlanDay *startDay = [[OCKCarePlanDay alloc] initWithYear:2016 month:2 day:10];

    NSMutableArray<NSNumber *> *occurrences = [NSMutableArray new];
    for (NSInteger i = 1; i <= 31; i++) {
        [occurrences addObject:@(i)];
    }
   
    // Every month
    OCKCareSchedule *monthlySchedule = [OCKCareSchedule monthlyScheduleWithStartDay:startDay
                                                               occurrencesOnEachDay:occurrences];

    NSUInteger dayInMonth = 10;
    NSUInteger occurrencesOnDay = occurrences[dayInMonth - 1].unsignedIntegerValue;
  
    XCTAssertEqual([monthlySchedule numberOfEventsOnDay:startDay], occurrencesOnDay);
  
    XCTAssertEqual([monthlySchedule numberOfEventsOnDay:[startDay dayByAddingDays:1]], occurrences[dayInMonth+1-1].unsignedIntegerValue);
    
    // Skip month
    monthlySchedule = [OCKCareSchedule monthlyScheduleWithStartDay:startDay
                                               occurrencesOnEachDay:occurrences
                                                       monthsToSkip:3
                                                            endDay:nil];

    XCTAssertEqual([monthlySchedule numberOfEventsOnDay:startDay], occurrencesOnDay);
    XCTAssertEqual([monthlySchedule numberOfEventsOnDay:[[OCKCarePlanDay alloc] initWithYear:2016 month:3 day:10]], 0);
    XCTAssertEqual([monthlySchedule numberOfEventsOnDay:[[OCKCarePlanDay alloc] initWithYear:2016 month:6 day:10]], occurrencesOnDay);
    
    
    // With end day
    monthlySchedule = [OCKCareSchedule monthlyScheduleWithStartDay:startDay
                                               occurrencesOnEachDay:occurrences
                                                       monthsToSkip:0
                                                                endDay:[[OCKCarePlanDay alloc] initWithYear:2016 month:5 day:10]];

    XCTAssertEqual([monthlySchedule numberOfEventsOnDay:startDay], occurrencesOnDay);
    XCTAssertEqual([monthlySchedule numberOfEventsOnDay:[[OCKCarePlanDay alloc] initWithYear:2016 month:3 day:10]], occurrencesOnDay);
    XCTAssertEqual([monthlySchedule numberOfEventsOnDay:[[OCKCarePlanDay alloc] initWithYear:2016 month:8 day:10]], 0);
    
}

- (void)carePlanStoreActivityListDidChange:(OCKCarePlanStore *)store {
    XCTAssertFalse(_listChanged);
    _listChanged = YES;
}

- (void)carePlanStore:(OCKCarePlanStore *)store didReceiveUpdateOfEvent:(nonnull OCKCarePlanEvent *)event {
    XCTAssertNil(_event);
    _event = event;
}

@end
