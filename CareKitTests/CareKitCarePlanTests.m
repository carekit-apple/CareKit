//
//  CareKitTests.m
//  CareKitTests
//
//  Created by Yuan Zhu on 1/19/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <XCTest/XCTest.h>
#import <CareKit/CareKit.h>

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
    
    OCKCareSchedule *schedule = [OCKCareSchedule dailyScheduleWithStartDate:[NSDate date] occurrencesPerDay:3];
    
    OCKDayRange range = {1, 1};
    OCKCarePlanActivity *item1 = [[OCKCarePlanActivity alloc] initWithIdentifier:@"id1"
                                                                 groupIdentifier:@"gid1"
                                                                            type:OCKCarePlanActivityTypeTreatment
                                                                           title:@"title1"
                                                                            text:@"text1"
                                                                       tintColor:[UIColor redColor]
                                                                        schedule:schedule
                                                                        optional:YES
                                                            eventMutableDayRange:range
                                                                resultResettable:YES
                                                                        userInfo:@{@"key":@"value1"}];
    
    OCKCarePlanActivity *item2 = [[OCKCarePlanActivity alloc] initWithIdentifier:@"id2"
                                                                            type:OCKCarePlanActivityTypeTreatment
                                                                           title:@"title2"
                                                                            text:@"text2"
                                                                       tintColor:[UIColor redColor]
                                                                        schedule:schedule];
    
    OCKCarePlanActivity *item3 = [[OCKCarePlanActivity alloc] initWithIdentifier:@"id3"
                                                                            type:OCKCarePlanActivityTypeAssessment
                                                                           title:@"title3"
                                                                            text:@"text3"
                                                                       tintColor:[UIColor redColor]
                                                                        schedule:schedule];
    
    
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
    
    
    expectation = [self expectationWithDescription:@"add1"];
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
    
    expectation = [self expectationWithDescription:@"add1"];
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
    
    expectation = [self expectationWithDescription:@"activitiesWithType"];
    [store activitiesWithType:OCKCarePlanActivityTypeTreatment
                   completion:^(BOOL success, NSArray<OCKCarePlanActivity *> * _Nonnull activities, NSError * _Nonnull error) {
                       XCTAssertTrue(success);
                       XCTAssertNil(error);
                       XCTAssertEqual(activities.count, 2);
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
    [store activitiesWithType:OCKCarePlanActivityTypeTreatment
                   completion:^(BOOL success, NSArray<OCKCarePlanActivity *> * _Nonnull activities, NSError * _Nonnull error) {
                       XCTAssertTrue(success);
                       XCTAssertNil(error);
                       XCTAssertEqual(activities.count, 2);
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
                       XCTAssertEqual(activityArray.count, 3);
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
    expectation = [self expectationWithDescription:@"setEndDate"];
    [store setEndDate:endDate
          forActivity:activities[2]
           completion:^(BOOL success, OCKCarePlanActivity * _Nonnull activity, NSError * _Nonnull error) {
               XCTAssertTrue(success);
               XCTAssertNil(error);
               XCTAssertEqualObjects(activity.schedule.endDate, endDate);
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
        XCTAssertEqual(activityArray.count, 3);
        activities = activityArray;
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    XCTAssertEqualObjects(activities[2].schedule.endDate, endDate, @"%@", activities[2].identifier);
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
        XCTAssertEqual(activityArray.count, 2);
        activities = activityArray;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    XCTAssertEqual(activities.count, 2);
    XCTAssertEqualObjects(activities[0], item1);
    XCTAssertEqualObjects(activities[1], item2);
    
    __block NSArray<NSArray<OCKCarePlanEvent *> *> *eventGroups = nil;
    
    expectation = [self expectationWithDescription:@"fetchTreatmentEvents"];
    [store eventsOnDay:[NSDate date]
                  type:OCKCarePlanActivityTypeTreatment
            completion:^(NSArray<NSArray<OCKCarePlanEvent *> *> * _Nonnull eventsGroupedByActivity, NSError * _Nonnull error) {
                eventGroups = eventsGroupedByActivity;
                XCTAssertNil(error);
                [expectation fulfill];
            }];
    
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
   
    XCTAssertEqual(eventGroups.count, 2);
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
                                                                                completionDate:[NSDate dateWithTimeIntervalSinceNow:-1000]
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
                                                                                completionDate:[NSDate dateWithTimeIntervalSinceNow:-1001]
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
    [store eventsOnDay:[NSDate date]
                  type:OCKCarePlanActivityTypeTreatment
            completion:^(NSArray<NSArray<OCKCarePlanEvent *> *> * _Nonnull eventsGroupedByActivity, NSError * _Nonnull error) {
                eventGroups = eventsGroupedByActivity;
                XCTAssertNil(error);
                [expectation fulfill];
            }];
    
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    XCTAssertNil(error);
    XCTAssertEqual(eventGroups.count, 2);
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
                                                                                completionDate:[NSDate dateWithTimeIntervalSinceNow:-1003]
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
    [store eventsOnDay:[NSDate date]
                  type:OCKCarePlanActivityTypeTreatment
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
    [store enumerateEventsOfActivity:activities[0] startDate:[NSDate date] endDate:[NSDate dateWithTimeIntervalSinceNow:100*24*60*60]
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
    NSCalendar *calendar = nil;
    NSTimeZone *gmtTimezone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    
    NSDate *now = [NSDate date];
    
    // Every Day
    OCKCareSchedule *dailySchedule = [OCKCareSchedule dailyScheduleWithStartDate:now occurrencesPerDay:2];
    calendar = dailySchedule.calendar;
    XCTAssertEqual([dailySchedule numberOfEventsOnDay:[now dateByAddingTimeInterval:1]], 2);
    XCTAssertEqual([dailySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:now options:0]], 2);
    
    // Skip days
    dailySchedule = [OCKCareSchedule dailyScheduleWithStartDate:now
                                              occurrencesPerDay:3
                                                     daysToSkip:3
                                                        endDate:nil
                                                       timeZone:nil];
    calendar = dailySchedule.calendar;
    XCTAssertEqual([dailySchedule numberOfEventsOnDay:now], 3);
    XCTAssertEqual([dailySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:now options:0]], 0);
    XCTAssertEqual([dailySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitDay value:4 toDate:now options:0]], 3);
    
    // With end day
    dailySchedule = [OCKCareSchedule dailyScheduleWithStartDate:now
                                              occurrencesPerDay:4
                                                     daysToSkip:0
                                                        endDate:[calendar dateByAddingUnit:NSCalendarUnitDay value:3 toDate:now options:0]
                                                       timeZone:nil];
    calendar = dailySchedule.calendar;
    XCTAssertEqual([dailySchedule numberOfEventsOnDay:now], 4);
    XCTAssertEqual([dailySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:now options:0]], 4);
    XCTAssertEqual([dailySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitDay value:6 toDate:now options:0]], 0);
    
    // With timezone;
    dailySchedule = [OCKCareSchedule dailyScheduleWithStartDate:now
                                              occurrencesPerDay:5
                                                     daysToSkip:1
                                                        endDate:nil
                                                       timeZone:gmtTimezone];
    calendar = dailySchedule.calendar;
    XCTAssertEqual([dailySchedule numberOfEventsOnDay:now], 5);
    XCTAssertEqual([dailySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:now options:0]], 0);
    XCTAssertEqual([dailySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitDay value:2 toDate:now options:0]], 5);
    XCTAssertEqual([dailySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitDay value:3 toDate:now options:0]], 0);
    XCTAssertEqual([dailySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitDay value:4 toDate:now options:0]], 5);
    
}

- (void)testWeeklySchedules {
    NSCalendar *calendar = nil;
    NSTimeZone *gmtTimezone = [NSTimeZone timeZoneForSecondsFromGMT:0];

    NSDate *now = [NSDate date];
    
    NSArray<NSNumber *> *occurrences = @[@(1), @(2), @(3), @(4), @(5), @(6), @(7)];
    
    // Every Week
    OCKCareSchedule *weeklySchedule = [OCKCareSchedule weeklyScheduleWithStartDate:now occurrencesOnEachDay:occurrences];
    calendar = weeklySchedule.calendar;
    NSUInteger weekday = [calendar component:NSCalendarUnitWeekday fromDate:now];
    NSUInteger occurrencesOnDay = occurrences[weekday - 1].unsignedIntegerValue;
    XCTAssertEqual([weeklySchedule numberOfEventsOnDay:now], occurrencesOnDay);
    XCTAssertEqual([weeklySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:now options:0]], occurrences[(weekday)%7].unsignedIntegerValue);
    
    // Skip weeks
    weeklySchedule = [OCKCareSchedule weeklyScheduleWithStartDate:now
                                             occurrencesOnEachDay:occurrences
                                                      weeksToSkip:3
                                                          endDate:nil
                                                         timeZone:nil];
    
    calendar = weeklySchedule.calendar;
    XCTAssertEqual([weeklySchedule numberOfEventsOnDay:now], occurrencesOnDay);
    XCTAssertEqual([weeklySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitWeekOfYear value:1 toDate:now options:0]], 0);
    XCTAssertEqual([weeklySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitWeekOfYear value:4 toDate:now options:0]], occurrencesOnDay);
    
    
    // With end day
    weeklySchedule = [OCKCareSchedule weeklyScheduleWithStartDate:now
                                             occurrencesOnEachDay:occurrences
                                                      weeksToSkip:0
                                                          endDate:[calendar dateByAddingUnit:NSCalendarUnitWeekOfYear value:3 toDate:now options:0]
                                                         timeZone:nil];
    
    calendar = weeklySchedule.calendar;
    XCTAssertEqual([weeklySchedule numberOfEventsOnDay:now], occurrencesOnDay);
    XCTAssertEqual([weeklySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitWeekOfYear value:1 toDate:now options:0]], occurrencesOnDay);
    XCTAssertEqual([weeklySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitWeekOfYear value:6 toDate:now options:0]], 0);
    
    // With timezone;
    weeklySchedule = [OCKCareSchedule weeklyScheduleWithStartDate:now
                                             occurrencesOnEachDay:occurrences
                                                      weeksToSkip:1
                                                          endDate:nil
                                                         timeZone:gmtTimezone];
    calendar = weeklySchedule.calendar;
    weekday = [calendar component:NSCalendarUnitWeekday fromDate:now];
    occurrencesOnDay = occurrences[weekday-1].unsignedIntegerValue;
    XCTAssertEqual([weeklySchedule numberOfEventsOnDay:now], occurrencesOnDay);
    XCTAssertEqual([weeklySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitWeekOfYear value:1 toDate:now options:0]], 0);
    XCTAssertEqual([weeklySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitWeekOfYear value:2 toDate:now options:0]], occurrencesOnDay);
    XCTAssertEqual([weeklySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitWeekOfYear value:3 toDate:now options:0]], 0);
    XCTAssertEqual([weeklySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitWeekOfYear value:4 toDate:now options:0]], occurrencesOnDay);
    
}

- (void)testMonthlySchedules {
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    
    NSTimeZone *gmtTimezone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    
    NSDate *now = [calendar dateWithEra:1 year:2016 month:2 day:10 hour:8 minute:0 second:0 nanosecond:8];
    NSMutableArray<NSNumber *> *occurrences = [NSMutableArray new];
    for (NSInteger i = 1; i <= 31; i++) {
        [occurrences addObject:@(i)];
    }
   
    // Every month
    OCKCareSchedule *monthlySchedule = [OCKCareSchedule monthlyScheduleWithStartDate:now occurrencesOnEachDay:occurrences];
    calendar = monthlySchedule.calendar;
    NSUInteger dayInMonth = [calendar component:NSCalendarUnitDay fromDate:now];
    NSUInteger occurrencesOnDay = occurrences[dayInMonth - 1].unsignedIntegerValue;
  
    XCTAssertEqual([monthlySchedule numberOfEventsOnDay:now], occurrencesOnDay);
    NSDate *nextDay = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:now options:0];
    NSUInteger nextDayInMonth = [calendar component:NSCalendarUnitDay fromDate:nextDay];
    XCTAssertEqual([monthlySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:now options:0]], occurrences[nextDayInMonth - 1].unsignedIntegerValue);
    
    // Skip month
    monthlySchedule = [OCKCareSchedule monthlyScheduleWithStartDate:now
                                               occurrencesOnEachDay:occurrences
                                                       monthsToSkip:3
                                                            endDate:nil
                                                           timeZone:nil];
    calendar = monthlySchedule.calendar;
    XCTAssertEqual([monthlySchedule numberOfEventsOnDay:now], occurrencesOnDay);
    XCTAssertEqual([monthlySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:now options:0]], 0);
    XCTAssertEqual([monthlySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitMonth value:4 toDate:now options:0]], occurrencesOnDay);
    
    
    // With end day
    monthlySchedule = [OCKCareSchedule monthlyScheduleWithStartDate:now
                                               occurrencesOnEachDay:occurrences
                                                       monthsToSkip:0
                                                            endDate:[calendar dateByAddingUnit:NSCalendarUnitMonth value:3 toDate:now options:0]
                                                           timeZone:nil];
    calendar = monthlySchedule.calendar;
    XCTAssertEqual([monthlySchedule numberOfEventsOnDay:now], occurrencesOnDay);
    XCTAssertEqual([monthlySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:now options:0]], occurrencesOnDay);
    XCTAssertEqual([monthlySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitMonth value:6 toDate:now options:0]], 0);
    
    // With timezone;
    monthlySchedule = [OCKCareSchedule monthlyScheduleWithStartDate:now
                                               occurrencesOnEachDay:occurrences
                                                       monthsToSkip:1
                                                            endDate:nil
                                                           timeZone:gmtTimezone];
    calendar = monthlySchedule.calendar;
    dayInMonth = [calendar component:NSCalendarUnitDay fromDate:now];
    occurrencesOnDay = occurrences[dayInMonth - 1].unsignedIntegerValue;
    
    XCTAssertEqual([monthlySchedule numberOfEventsOnDay:now], occurrencesOnDay);
    XCTAssertEqual([monthlySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:now options:0]], 0);
    XCTAssertEqual([monthlySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitMonth value:2 toDate:now options:0]], occurrencesOnDay);
    XCTAssertEqual([monthlySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitMonth value:3 toDate:now options:0]], 0);
    XCTAssertEqual([monthlySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitMonth value:4 toDate:now options:0]], occurrencesOnDay);
    
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
