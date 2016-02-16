//
//  ViewController.m
//  OCKTest
//
//  Created by Yuan Zhu on 1/19/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "ViewController.h"
#import <CareKit/CareKit.h>


@interface ViewController () <OCKEvaluationTableViewDelegate, OCKCarePlanStoreDelegate, ORKTaskViewControllerDelegate>

@end


@implementation ViewController {
    UITabBarController *_tabBarController;
    OCKCarePlanStore *_store;
    
    NSArray<OCKEvaluation *> *_evaluations;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setUpCarePlanStore];
    
    UIViewController *dashboard = [self dashboardViewController];
    UIViewController *evaluation = [self evaluationViewController];
    UIViewController *connect = [self connectViewController];
    
    _tabBarController = [UITabBarController new];
    _tabBarController.viewControllers = @[dashboard, evaluation, connect];
    _tabBarController.selectedIndex = 1;
}

- (void)viewDidAppear:(BOOL)animated {
    [self presentViewController:_tabBarController animated:YES completion:nil];
}


#pragma mark - Helpers

- (NSString *)storeDirectoryPath {
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docPath = [searchPaths objectAtIndex:0];
    NSString *path = [docPath stringByAppendingPathComponent:@"carePlanStore"];
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    return path;
}

- (NSURL *)storeDirectoryURL {
    return [NSURL fileURLWithPath:[self storeDirectoryPath]];
}

- (void)setUpCarePlanStore {
    // Set up store.
    _store = [[OCKCarePlanStore alloc] initWithPersistenceDirectoryURL:[self storeDirectoryURL]];
    _store.delegate = self;
    
    // Populate evaluations.
    [self generateEvaluations];
    
    // Add new evaluations to store.
    NSError *error;
    for (OCKEvaluation *evaluation in _evaluations) {
        if (![_store evaluationForIdentifier:evaluation.identifier error:nil]) {
            [_store addEvaluation:evaluation error:&error];
            NSAssert(!error, error.localizedDescription);
        }
    }
}

- (void)generateEvaluations {
    NSMutableArray *evaluations = [NSMutableArray new];
    {
        OCKCareSchedule *coughEvaluationSchedule = [OCKCareSchedule weeklyScheduleWithStartDate:[NSDate date] occurrencesOnEachDay:@[@1,@1,@0,@1,@0,@1,@1]];
        OCKEvaluation *coughEvaluation = [[OCKEvaluation alloc] initWithIdentifier:@"coughEvaluation"
                                                                              type:@"survey"
                                                                             title:@"Cough"
                                                                              text:@"survey"
                                                                             color:[UIColor greenColor]
                                                                          schedule:coughEvaluationSchedule
                                                                              task:nil
                                                                          optional:NO
                                                                        retryLimit:0];
        [evaluations addObject:coughEvaluation];
    }
    _evaluations = [evaluations copy];
}


#pragma mark - CareKit View Controllers

- (OCKDashboardViewController *)dashboardViewController {
    NSMutableArray *charts = [NSMutableArray new];
    
    {
        OCKLinePoint *point1 = [OCKLinePoint linePointWithValue:1.0];
        OCKLinePoint *point2 = [OCKLinePoint linePointWithValue:2.0];
        OCKLinePoint *point3 = [OCKLinePoint linePointWithValue:3.0];
        OCKLinePoint *point4 = [OCKLinePoint linePointWithValue:4.0];
        OCKLinePoint *point5 = [OCKLinePoint linePointWithValue:5.0];
        OCKLine *line1 = [OCKLine lineWithLinePoints:@[point1, point2, point3, point4, point5]];
        line1.color = OCKGrayColor();
        OCKLine *line2 = [OCKLine lineWithLinePoints:@[point4, point3, point5, point1, point2]];
        line2.color = OCKYellowColor();
        OCKLineChart *lineChart = [OCKLineChart lineChartWithTitle:@"Line Chart"
                                                              text:@"Weekly sales of hardware and software"
                                                             lines:@[line1, line2]];
        lineChart.tintColor = OCKYellowColor();
        [charts addObject:lineChart];
    }
    
    {
        OCKRangePoint *range1 = [OCKRangePoint rangePointWithMinimumValue:10.0 maximumValue:20.0];
        OCKRangePoint *range2 = [OCKRangePoint rangePointWithMinimumValue:15.0 maximumValue:25.0];
        OCKRangePoint *range3 = [OCKRangePoint rangePointWithMinimumValue:5.0 maximumValue:15.0];
        OCKRangePoint *range4 = [OCKRangePoint rangePointWithMinimumValue:5.0 maximumValue:30.0];
        OCKRangePoint *range5 = [OCKRangePoint rangePointWithMinimumValue:15.0 maximumValue:30.0];
        
        OCKRangeGroup *rangeGroup1 = [OCKRangeGroup rangeGroupWithRangePoints:@[range1, range2, range3, range4, range5]];
        rangeGroup1.color = OCKBlueColor();
        OCKRangeGroup *rangeGroup2 = [OCKRangeGroup rangeGroupWithRangePoints:@[range1, range5, range4, range3, range2]];
        rangeGroup2.color = OCKGrayColor();
        
        OCKDiscreteChart *discreteChart = [OCKDiscreteChart discreteChartWithGroups:@[rangeGroup1, rangeGroup2]];
        discreteChart.title = @"Discrete Chart";
        discreteChart.text = @"Daily sales of hardware and software but I want to test multiple lines, so here's some more text.";
        discreteChart.tintColor = OCKBlueColor();
        discreteChart.xAxisTitle = @"Day";
        discreteChart.yAxisTitle = @"Sales";
        [charts addObject:discreteChart];
    }
    
    {
        OCKSegment *segment1 = [OCKSegment segmentWithValue:0.25 color:[UIColor brownColor] title:@"Brown"];
        OCKSegment *segment2 = [OCKSegment segmentWithValue:0.15 color:[UIColor purpleColor] title:@"Purple"];
        OCKSegment *segment3 = [OCKSegment segmentWithValue:0.05 color:[UIColor cyanColor] title:@"Cyan"];
        OCKSegment *segment4 = [OCKSegment segmentWithValue:0.55 color:[UIColor orangeColor] title:@"Orange"];
        OCKPieChart *pieChart = [OCKPieChart pieChartWithTitle:@"Pie Chart"
                                                          text:@"Apple employee color preference"
                                                      segments:@[segment1, segment2, segment3, segment4]];
        pieChart.showsPercentageLabels = YES;
        pieChart.usesLineSegments = YES;
        pieChart.tintColor = OCKRedColor();
        pieChart.height = 300.0;
        [charts addObject:pieChart];
    }
    
    OCKDashboardViewController *dashboard = [OCKDashboardViewController dashboardWithCharts:charts];
    dashboard.headerTitle = @"Today";
    
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    formatter.timeStyle = NSDateFormatterNoStyle;
    dashboard.headerText = [formatter stringFromDate:[NSDate date]];
    
    return dashboard;
}

- (OCKEvaluationViewController *)evaluationViewController {
    return [OCKEvaluationViewController evaluationViewControllerWithCarePlanStore:_store
                                                                         delegate:self];
}

- (OCKConnectViewController *)connectViewController {
    NSMutableArray *contacts = [NSMutableArray new];
    
    {
        OCKContact *contact = [OCKContact contactWithContactType:OCKContactTypeClinician
                                                            name:@"Dr. John Smith"
                                                        relation:@"physician"
                                                     phoneNumber:@"123-456-7890"
                                                   messageNumber:@"123-456-7890"
                                                    emailAddress:@"jsmith@researchkit.org"];
        contact.tintColor = OCKBlueColor();
        [contacts addObject:contact];
    }
    
    {
        OCKContact *contact = [OCKContact contactWithContactType:OCKContactTypeClinician
                                                            name:@"Dr. Casey Watson"
                                                        relation:@"dermatologist"
                                                     phoneNumber:@"123-456-7890"
                                                   messageNumber:nil
                                                    emailAddress:nil];
        contact.tintColor = OCKPinkColor();
        [contacts addObject:contact];
    }
    
    {
        
        OCKContact *contact = [OCKContact contactWithContactType:OCKContactTypeEmergencyContact
                                                            name:@"John Appleseed"
                                                        relation:@"father"
                                                     phoneNumber:@"123-456-7890"
                                                   messageNumber:@"123-456-7890"
                                                    emailAddress:nil];
        contact.tintColor = OCKYellowColor();
        [contacts addObject:contact];
    }
    
    {
        OCKContact *contact = [OCKContact contactWithContactType:OCKContactTypeClinician
                                                            name:@"Shelby Brooks"
                                                        relation:@"nurse"
                                                     phoneNumber:@"123-456-7890"
                                                   messageNumber:nil
                                                    emailAddress:@"nbrooks@researchkit.org"];
        contact.tintColor = OCKGreenColor();
        [contacts addObject:contact];
    }
    
    return [OCKConnectViewController connectViewControllerWithContacts:contacts];
}


#pragma mark - Evaluation Table View Delegate (OCKEvaluationTableViewDelegate)

- (void)tableViewDidSelectEvaluationEvent:(OCKEvaluationEvent *)evaluationEvent {
    ORKAnswerFormat *answerFormat = [ORKAnswerFormat scaleAnswerFormatWithMaximumValue:10
                                                                          minimumValue:0
                                                                          defaultValue:NSIntegerMax
                                                                                  step:1
                                                                              vertical:NO
                                                               maximumValueDescription:@"Good"
                                                               minimumValueDescription:@"Bad"];
    ORKQuestionStep *step = [ORKQuestionStep questionStepWithIdentifier:@"coughStep"
                                                                  title:@"How was your cough today?"
                                                                 answer:answerFormat];
    step.optional = NO;
    
    ORKOrderedTask *task = [[ORKOrderedTask alloc] initWithIdentifier:@"coughSurvey" steps:@[step]];

    ORKTaskViewController *taskViewController = [[ORKTaskViewController alloc] initWithTask:task
                                                                                taskRunUUID:nil];
    taskViewController.delegate = self;
    
    [_tabBarController presentViewController:taskViewController animated:YES completion:nil];
}


#pragma mark - Care Plan Store Delegate (OCKCarePlanStoreDelegate)

- (void)carePlanStore:(OCKCarePlanStore *)store didReceiveUpdateOfEvaluationEvent:(OCKEvaluationEvent *)event {
    
}

- (void)carePlanStoreEvaluationListDidChange:(OCKCarePlanStore *)store {
    
}


#pragma mark - Task View Controller Delegate (ORKTaskViewControllerDelegate)

- (void)taskViewController:(ORKTaskViewController *)taskViewController didFinishWithReason:(ORKTaskViewControllerFinishReason)reason error:(NSError *)error {
    if (reason == ORKTaskViewControllerFinishReasonCompleted) {
        // Fetch the result value.
        ORKStepResult *stepResult = (ORKStepResult*)[taskViewController.result firstResult];
        ORKScaleQuestionResult *questionResult = (ORKScaleQuestionResult*)[stepResult firstResult];
        CGFloat value = [questionResult.scaleAnswer floatValue];
        
        // Grab the evaluation and update it in the store.
        NSError *error;
        OCKEvaluation *evaluation = _evaluations[0];
        OCKEvaluationEvent *evaluationEvent = [[_store eventsOfEvaluation:evaluation
                                                                    onDay:[NSDate date]
                                                                    error:&error] firstObject];
        NSAssert(!error, error.localizedDescription);
        [_store updateEvaluationEvent:evaluationEvent
                      evaluationValue:@(value)
                evaluationValueString:[NSString stringWithFormat:@"%@", @(value)]
                     evaluationResult:nil
                       completionDate:[NSDate date]
                    completionHandler:^(BOOL success, OCKEvaluationEvent * _Nonnull event, NSError * _Nonnull error) {
                        NSAssert(success, error.localizedDescription);
                    }];
        
    }
    
    [_tabBarController dismissViewControllerAnimated:taskViewController completion:nil];
}


@end
