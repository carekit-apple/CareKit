//
//  CareKitTests.m
//  CareKitTests
//
//  Created by Yuan Zhu on 1/19/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <XCTest/XCTest.h>
#import <CareKit/CareKit.h>


@interface CareKitTests : XCTestCase

@end

@implementation CareKitTests

- (NSString *)testPath {
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docPath = [searchPaths objectAtIndex:0];
    NSString *treatmentPath = [docPath stringByAppendingPathComponent:@"treatmentManager"];
    [[NSFileManager defaultManager] createDirectoryAtPath:treatmentPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    return treatmentPath;
}

- (NSString *)cleanTestPath {
    NSString *testPath = [self testPath];
    [[NSFileManager defaultManager] removeItemAtPath:testPath error:nil];
    return [self testPath];
}

- (void)testTreatmentMananger {
    NSURL *directoryURL = [NSURL fileURLWithPath:[self cleanTestPath]];
    OCKTreatmentPlanManager *manager = [[OCKTreatmentPlanManager alloc] initWithPersistenceDirectoryURL:directoryURL];
    
    OCKTreatmentType *type1 = [[OCKTreatmentType alloc] initWithName:@"type1" text:@"type1_text"];
    OCKTreatmentType *type2 = [[OCKTreatmentType alloc] initWithName:@"type2" text:@"type2_text"];

    [manager addTreatmentTypes:@[type1 , type2]];
    
    OCKTreatmentSchedule *schedule = [[OCKTreatmentSchedule alloc] initWithStartDate:[NSDate date] endDate:nil timeZone:nil];
    OCKTreatment *treatment1 = [[OCKTreatment alloc] initWithType:type1
                                                            color:[UIColor greenColor]
                                                         schedule:schedule
                                                         inActive:NO];
    
    OCKTreatment *treatment2 = [[OCKTreatment alloc] initWithType:type2
                                                            color:[UIColor blueColor]
                                                         schedule:schedule
                                                         inActive:NO];
    
    [manager addTreatment:treatment1];
    [manager addTreatment:treatment2];
    
    XCTAssertEqual(manager.treatments.count, 2);
    XCTAssertEqual(manager.treatmentTypes.count, 2);
    
    manager = [[OCKTreatmentPlanManager alloc] initWithPersistenceDirectoryURL:directoryURL];
    
    XCTAssertEqual(manager.treatments.count, 2);
    XCTAssertEqual(manager.treatmentTypes.count, 2);
    
    XCTAssertEqualObjects(manager.treatments[0], treatment1);
    XCTAssertEqualObjects(manager.treatments[1], treatment2);
    
    XCTAssertEqualObjects(manager.treatmentTypes[0], type1);
    XCTAssertEqualObjects(manager.treatmentTypes[1], type2);
}

@end
