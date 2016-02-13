//
//  CareKitTests.m
//  CareKitTests
//
//  Created by Yuan Zhu on 1/19/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <XCTest/XCTest.h>
#import <CareKit/CareKit.h>
#import "OCKCareSchedule_Internal.h"


@interface CareKitTests : XCTestCase <OCKCarePlanStoreDelegate>

@end

@implementation CareKitTests {
    BOOL _listChanged;
    OCKCareEvent *_event;
}

- (NSString *)testPath {
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docPath = [searchPaths objectAtIndex:0];
    NSString *treatmentPath = [docPath stringByAppendingPathComponent:@"treatmentStore"];
    [[NSFileManager defaultManager] createDirectoryAtPath:treatmentPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    return treatmentPath;
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

- (void)testTreatments {
    
    NSURL *directoryURL = [NSURL fileURLWithPath:[self cleanTestPath]];
    OCKCarePlanStore *store = [[OCKCarePlanStore alloc] initWithPersistenceDirectoryURL:directoryURL];
    store.delegate = self;
    
    OCKCareSchedule *schedule = [[OCKCareDailySchedule alloc] initWithStartDate:[NSDate date] occurrencesPerDay:3];
    
    OCKTreatment *item1 = [[OCKTreatment alloc] initWithType:@"type1"
                                                       title:@"title1"
                                                        text:@"text1"
                                                        color:[UIColor greenColor]
                                                         schedule:schedule
                                                    optional:NO onlyMutableDuringEventDay:NO];
    
    OCKTreatment *item2 = [[OCKTreatment alloc] initWithType:@"type2"
                                                       title:@"title2"
                                                        text:@"text2"
                                                       color:[UIColor blueColor]
                                                    schedule:schedule
                                                    optional:NO onlyMutableDuringEventDay:NO];
    
    NSError *error;
    BOOL result;
    
    result = [store addTreatment:item1 error:&error];
    XCTAssertTrue(result);
    XCTAssertNil(error);
    XCTAssertTrue([self isListChangeDelegateCalled]);
    
    result = [store addTreatment:item2 error:&error];
    XCTAssertTrue(result);
    XCTAssertNil(error);
    XCTAssertTrue([self isListChangeDelegateCalled]);
    
    XCTAssertEqual(store.treatments.count, 2);
    
    XCTAssertEqual([store treatmentsWithType:@"type1" error:&error].count, 1);
    XCTAssertNil(error);
    XCTAssertEqual([store treatmentsWithType:@"type2" error:&error].count, 1);
    XCTAssertNil(error);
    
    store = [[OCKCarePlanStore alloc] initWithPersistenceDirectoryURL:directoryURL];
    store.delegate = self;
    
    XCTAssertEqual(store.treatments.count, 2);
    
    NSArray *treatments = store.treatments;
    
    XCTAssertEqualObjects(treatments[0], item1);
    XCTAssertEqualObjects(treatments[1], item2);
    
    NSDate *endDate = [NSDate dateWithTimeIntervalSinceNow:8*24*60*60];
    result = [store setEndDate:endDate forTreatment:treatments[1] error:&error];
    XCTAssertTrue(result);
    XCTAssertNil(error);
    XCTAssertEqualObjects(store.treatments[1].schedule.endDate, endDate);
    XCTAssertTrue([self isListChangeDelegateCalled]);
    
    result = [store removeTreatment:treatments[1] error:&error];
    XCTAssertTrue(result);
    XCTAssertNil(error);
    XCTAssertTrue([self isListChangeDelegateCalled]);
    
    treatments = store.treatments;
    XCTAssertEqual(treatments.count, 1);
    XCTAssertEqualObjects(treatments[0], item1);
    
    NSArray<NSArray<OCKTreatmentEvent *> *> *events = [store treatmentEventsOnDay:[NSDate date] error:&error];
    XCTAssertNil(error);
    XCTAssertEqual(events.count, 1);
    XCTAssertEqual(events.firstObject.count, 3);
    XCTAssertEqual(events[0][0].state, OCKCareEventStateInitial);
    XCTAssertEqual(events[0][1].state, OCKCareEventStateInitial);
    XCTAssertEqual(events[0][2].state, OCKCareEventStateInitial);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"updateEvent"];
    
    [store updateTreatmentEvent:events[0][0]
                      completed:YES
                 completionDate:[NSDate date]
              completionHandler:^(BOOL success, OCKTreatmentEvent * _Nonnull event, NSError * _Nonnull error) {
        XCTAssertNil(error);
        XCTAssertTrue(success);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    events = [store treatmentEventsOnDay:[NSDate date] error:&error];
    XCTAssertNil(error);
    XCTAssertEqual(events.count, 1);
    XCTAssertEqual(events.firstObject.count, 3);
    XCTAssertEqual(events[0][0].state, OCKCareEventStateCompleted);
    XCTAssertNotNil(events[0][0].completionDate);
    XCTAssertEqual(events[0][1].state, OCKCareEventStateInitial);
    XCTAssertEqual(events[0][2].state, OCKCareEventStateInitial);
    XCTAssertTrue([self isEventChangeDelegateCalled]);
    
    expectation = [self expectationWithDescription:@"enumerateEvents"];
    NSMutableArray<OCKTreatmentEvent *> *eventsOfTreatment = [[NSMutableArray alloc] init];
    [store enumerateEventsOfTreatment:treatments[0] startDate:[NSDate date] endDate:[NSDate dateWithTimeIntervalSinceNow:100*24*60*60]
                           usingBlock:^(OCKTreatmentEvent * _Nonnull event, BOOL * _Nonnull stop, NSError * _Nonnull error) {
                               XCTAssertNil(error);
                               XCTAssertNotNil(event);
                               [eventsOfTreatment addObject:event];
                               if (eventsOfTreatment.count == 303) {
                                   [expectation fulfill];
                               }
                           }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    
    XCTAssertEqual(eventsOfTreatment.count, 3*101);
    XCTAssertEqual(eventsOfTreatment[0].numberOfDaysSinceStart, 0);
    XCTAssertEqual(eventsOfTreatment[1].numberOfDaysSinceStart, 0);
    XCTAssertEqual(eventsOfTreatment[2].numberOfDaysSinceStart, 0);
    
    XCTAssertEqual(eventsOfTreatment[3*3].numberOfDaysSinceStart, 3);
    XCTAssertEqual(eventsOfTreatment[5*3].numberOfDaysSinceStart, 5);
    
    store.delegate = nil;
    [self measureBlock:^{
        
        for (OCKTreatmentEvent* event in eventsOfTreatment) {
            XCTestExpectation *expectation = [self expectationWithDescription:@"updateEvent"];
            [store updateTreatmentEvent:event completed:YES
                         completionDate:[NSDate date]
                      completionHandler:^(BOOL success, OCKTreatmentEvent * _Nonnull event, NSError * _Nonnull error) {
                          XCTAssertNil(error);
                          XCTAssertTrue(success);
                          [expectation fulfill];
            }];
        }
        
        [self waitForExpectationsWithTimeout:10.0 handler:^(NSError * _Nullable error) {
            XCTAssertNil(error);
        }];
    }];
    
    NSLog(@"open %@", [self testPath]);
}

- (void)testEvaluations {

    [self measureBlock:^{
        
        NSURL *directoryURL = [NSURL fileURLWithPath:[self cleanTestPath]];
        OCKCarePlanStore *store = [[OCKCarePlanStore alloc] initWithPersistenceDirectoryURL:directoryURL];
        store.delegate = self;
        
        OCKCareSchedule *schedule = [[OCKCareDailySchedule alloc] initWithStartDate:[NSDate date] occurrencesPerDay:3];
        
        OCKEvaluation *item1 = [[OCKEvaluation alloc] initWithType:@"type1"
                                                             title:@"title1"
                                                              text:@"text1"
                                                             color:[UIColor orangeColor]
                                                          schedule:schedule
                                                              task:[[ORKOrderedTask alloc] initWithIdentifier:@"id" steps:nil]
                                                          optional:NO
                                                        retryLimit:0];
        
        OCKEvaluation *item2 = [[OCKEvaluation alloc] initWithType:@"type2"
                                                             title:@"title2"
                                                              text:@"text2"
                                                             color:[UIColor blueColor]
                                                          schedule:schedule
                                                              task:nil
                                                          optional:NO
                                                        retryLimit:0];
        
        NSError *error;
        BOOL result;
        result = [store addEvaluation:item1 error:&error];
        XCTAssertTrue(result);
        XCTAssertNil(error);
        XCTAssertTrue([self isListChangeDelegateCalled]);
        result = [store addEvaluation:item2 error:&error];
        XCTAssertTrue(result);
        XCTAssertNil(error);
        XCTAssertTrue([self isListChangeDelegateCalled]);
        
        XCTAssertEqual(store.evaluations.count, 2);
        
        XCTAssertEqual([store evaluationsWithType:@"type1" error:&error].count, 1);
        XCTAssertNil(error);
        XCTAssertEqual([store evaluationsWithType:@"type2" error:&error].count, 1);
        XCTAssertNil(error);
        
        store = [[OCKCarePlanStore alloc] initWithPersistenceDirectoryURL:directoryURL];
        store.delegate = self;
        
        XCTAssertEqual(store.evaluations.count, 2);
        
        NSArray *evaluations = store.evaluations;
        
        XCTAssertEqualObjects(evaluations[0], item1);
        XCTAssertEqualObjects(evaluations[1], item2);
        
        NSDate *endDate = [NSDate dateWithTimeIntervalSinceNow:8*24*60*60];
        result = [store setEndDate:endDate forEvaluation:evaluations[1] error:&error];
        XCTAssertTrue(result);
        XCTAssertNil(error);
        XCTAssertEqualObjects(store.evaluations[1].schedule.endDate, endDate);
        XCTAssertTrue([self isListChangeDelegateCalled]);
        
        result = [store removeEvaluation:evaluations[1] error:&error];
        XCTAssertTrue(result);
        XCTAssertNil(error);
        XCTAssertTrue([self isListChangeDelegateCalled]);
        
        evaluations = store.evaluations;
        XCTAssertEqual(evaluations.count, 1);
        XCTAssertEqualObjects(evaluations[0], item1);
        
        NSArray<NSArray<OCKEvaluationEvent *> *> *events = [store evaluationEventsOnDay:[NSDate date] error:&error];
        XCTAssertNil(error);
        XCTAssertEqual(events.count, 1);
        XCTAssertEqual(events.firstObject.count, 3);
        XCTAssertEqual(events[0][0].state, OCKCareEventStateInitial);
        XCTAssertEqual(events[0][1].state, OCKCareEventStateInitial);
        XCTAssertEqual(events[0][2].state, OCKCareEventStateInitial);
        
        XCTestExpectation* expectation = [self expectationWithDescription:@"updateEvent"];
        [store updateEvaluationEvent:events[0][0]
                     evaluationValue:@(9.5)
               evaluationValueString:@"9.5"
                    evaluationResult:NSStringFromClass([self class])
                      completionDate:[NSDate date]
                   completionHandler:^(BOOL success, OCKEvaluationEvent * _Nonnull event, NSError * _Nonnull error) {
                       XCTAssertTrue(success);
                       XCTAssertNotNil(event);
                       XCTAssertNil(error);
                       [expectation fulfill];
                   }];
        [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
            XCTAssertNil(error);
        }];
        
        events = [store evaluationEventsOnDay:[NSDate date] error:&error];
        XCTAssertNil(error);
        XCTAssertEqual(events.count, 1);
        XCTAssertEqual(events.firstObject.count, 3);
        XCTAssertEqual(events[0][0].state, OCKCareEventStateCompleted);
        XCTAssertNotNil(events[0][0].completionDate);
        XCTAssertEqualObjects(events[0][0].evaluationValue, @(9.5));
        XCTAssertEqualObjects(events[0][0].evaluationValueString, @"9.5");
        XCTAssertEqualObjects(events[0][0].evaluationResult, NSStringFromClass([self class]));
        XCTAssertEqual(events[0][1].state, OCKCareEventStateInitial);
        XCTAssertEqual(events[0][2].state, OCKCareEventStateInitial);
        XCTAssertTrue([self isEventChangeDelegateCalled]);
        
        
        expectation = [self expectationWithDescription:@"enumerateEvents"];
        NSMutableArray<OCKEvaluationEvent *> *eventsOfEvaluation = [[NSMutableArray alloc] init];
        [store enumerateEventsOfEvaluation:evaluations[0]
                                 startDate:[NSDate date]
                                   endDate:[NSDate dateWithTimeIntervalSinceNow:8*24*60*60]
                               usingBlock:^(OCKEvaluationEvent * _Nonnull event, BOOL * _Nonnull stop, NSError * _Nonnull error) {
                                   XCTAssertNil(error);
                                   XCTAssertNotNil(event);
                                   [eventsOfEvaluation addObject:event];
                                   if (eventsOfEvaluation.count == 3*9) {
                                       [expectation fulfill];
                                   }
                               }];
        
        [self waitForExpectationsWithTimeout:2.0 handler:^(NSError * _Nullable error) {
            XCTAssertNil(error);
        }];
        
        XCTAssertNil(error);
        XCTAssertEqual(eventsOfEvaluation.count, 3*9);
        XCTAssertEqual(eventsOfEvaluation[0].numberOfDaysSinceStart, 0);
        XCTAssertEqual(eventsOfEvaluation[1].numberOfDaysSinceStart, 0);
        XCTAssertEqual(eventsOfEvaluation[2].numberOfDaysSinceStart, 0);
        
        XCTAssertEqual(eventsOfEvaluation[3*3].numberOfDaysSinceStart, 3);
        XCTAssertEqual(eventsOfEvaluation[5*3].numberOfDaysSinceStart, 5);
        
        
    }];
}

- (void)testDailySchedules {
    NSCalendar *calendar = nil;
    NSTimeZone *gmtTimezone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    
    NSDate *now = [NSDate date];
    
    // Every Day
    OCKCareDailySchedule *dailySchedule = [[OCKCareDailySchedule alloc] initWithStartDate:now occurrencesPerDay:2];
    calendar = dailySchedule.calendar;
    XCTAssertEqual([dailySchedule numberOfEventsOnDay:[now dateByAddingTimeInterval:1]], 2);
    XCTAssertEqual([dailySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:now options:0]], 2);
    
    // Skip days
    dailySchedule = [[OCKCareDailySchedule alloc] initWithStartDate:now
                                                         daysToSkip:3
                                                  occurrencesPerDay:3 endDate:nil timeZone:nil];
    calendar = dailySchedule.calendar;
    XCTAssertEqual([dailySchedule numberOfEventsOnDay:now], 3);
    XCTAssertEqual([dailySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:now options:0]], 0);
    XCTAssertEqual([dailySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitDay value:4 toDate:now options:0]], 3);
    
    
    // With end day
    dailySchedule = [[OCKCareDailySchedule alloc] initWithStartDate:now
                                                         daysToSkip:0
                                                  occurrencesPerDay:4 endDate:[calendar dateByAddingUnit:NSCalendarUnitDay value:3 toDate:now options:0] timeZone:nil];
    calendar = dailySchedule.calendar;
    XCTAssertEqual([dailySchedule numberOfEventsOnDay:now], 4);
    XCTAssertEqual([dailySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:now options:0]], 4);
    XCTAssertEqual([dailySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitDay value:6 toDate:now options:0]], 0);
    
    // With timezone;
    dailySchedule = [[OCKCareDailySchedule alloc] initWithStartDate:now
                                                         daysToSkip:1
                                                  occurrencesPerDay:5 endDate:nil timeZone:gmtTimezone];
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
    OCKCareWeeklySchedule *weeklySchedule = [[OCKCareWeeklySchedule alloc] initWithStartDate:now occurrencesOnEachDay:occurrences];
    calendar = weeklySchedule.calendar;
    NSUInteger weekday = [calendar component:NSCalendarUnitWeekday fromDate:now];
    NSUInteger occurrencesOnDay = occurrences[weekday - 1].unsignedIntegerValue;
    XCTAssertEqual([weeklySchedule numberOfEventsOnDay:now], occurrencesOnDay);
    XCTAssertEqual([weeklySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:now options:0]], occurrences[(weekday)%7].unsignedIntegerValue);
    
    // Skip weeks
    weeklySchedule = [[OCKCareWeeklySchedule alloc] initWithStartDate:now
                                                           weeksToSkip:3
                                                 occurrencesOnEachDay:occurrences
                                                              endDate:nil
                                                             timeZone:nil];
    calendar = weeklySchedule.calendar;
    XCTAssertEqual([weeklySchedule numberOfEventsOnDay:now], occurrencesOnDay);
    XCTAssertEqual([weeklySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitWeekOfYear value:1 toDate:now options:0]], 0);
    XCTAssertEqual([weeklySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitWeekOfYear value:4 toDate:now options:0]], occurrencesOnDay);
    
    
    // With end day
    weeklySchedule = [[OCKCareWeeklySchedule alloc] initWithStartDate:now
                                                          weeksToSkip:0
                                                 occurrencesOnEachDay:occurrences
                                                              endDate:[calendar dateByAddingUnit:NSCalendarUnitWeekOfYear value:3 toDate:now options:0] timeZone:nil];
    calendar = weeklySchedule.calendar;
    XCTAssertEqual([weeklySchedule numberOfEventsOnDay:now], occurrencesOnDay);
    XCTAssertEqual([weeklySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitWeekOfYear value:1 toDate:now options:0]], occurrencesOnDay);
    XCTAssertEqual([weeklySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitWeekOfYear value:6 toDate:now options:0]], 0);
    
    // With timezone;
    
    
    weeklySchedule = [[OCKCareWeeklySchedule alloc] initWithStartDate:now
                                                         weeksToSkip:1
                                                occurrencesOnEachDay:occurrences
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
    OCKCareMonthlySchedule *monthlySchedule = [[OCKCareMonthlySchedule alloc] initWithStartDate:now occurrencesOnEachDay:occurrences];
    calendar = monthlySchedule.calendar;
    NSUInteger dayInMonth = [calendar component:NSCalendarUnitDay fromDate:now];
    NSUInteger occurrencesOnDay = occurrences[dayInMonth - 1].unsignedIntegerValue;
  
    XCTAssertEqual([monthlySchedule numberOfEventsOnDay:now], occurrencesOnDay);
    NSDate *nextDay = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:now options:0];
    NSUInteger nextDayInMonth = [calendar component:NSCalendarUnitDay fromDate:nextDay];
    XCTAssertEqual([monthlySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:now options:0]], occurrences[nextDayInMonth - 1].unsignedIntegerValue);
    
    // Skip month
    monthlySchedule = [[OCKCareMonthlySchedule alloc] initWithStartDate:now
                                                          monthsToSkip:3
                                                   occurrencesOnEachDay:occurrences
                                                                endDate:nil
                                                               timeZone:nil];
    calendar = monthlySchedule.calendar;
    XCTAssertEqual([monthlySchedule numberOfEventsOnDay:now], occurrencesOnDay);
    XCTAssertEqual([monthlySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:now options:0]], 0);
    XCTAssertEqual([monthlySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitMonth value:4 toDate:now options:0]], occurrencesOnDay);
    
    
    // With end day
    monthlySchedule = [[OCKCareMonthlySchedule alloc] initWithStartDate:now
                                                          monthsToSkip:0
                                                   occurrencesOnEachDay:occurrences
                                                              endDate:[calendar dateByAddingUnit:NSCalendarUnitMonth value:3 toDate:now options:0] timeZone:nil];
    calendar = monthlySchedule.calendar;
    XCTAssertEqual([monthlySchedule numberOfEventsOnDay:now], occurrencesOnDay);
    XCTAssertEqual([monthlySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:now options:0]], occurrencesOnDay);
    XCTAssertEqual([monthlySchedule numberOfEventsOnDay:[calendar dateByAddingUnit:NSCalendarUnitMonth value:6 toDate:now options:0]], 0);
    
    // With timezone;
    monthlySchedule = [[OCKCareMonthlySchedule alloc] initWithStartDate:now
                                                          monthsToSkip:1
                                                 occurrencesOnEachDay:occurrences
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

- (void)carePlanStoreTreatmentListDidChange:(OCKCarePlanStore *)store {
    XCTAssertFalse(_listChanged);
    _listChanged = YES;
}

- (void)carePlanStoreEvaluationListDidChange:(OCKCarePlanStore *)store {
    XCTAssertFalse(_listChanged);
    _listChanged = YES;
}

- (void)carePlanStore:(OCKCarePlanStore *)store didReceiveUpdateOfTreatmentEvent:(OCKTreatmentEvent *)event {
    XCTAssertNil(_event);
    _event = event;
}

- (void)carePlanStore:(OCKCarePlanStore *)store didReceiveUpdateOfEvaluationEvent:(OCKEvaluationEvent *)event {
    XCTAssertNil(_event);
    _event = event;
}

@end
