//
//  ViewController.m
//  OCKTest
//
//  Created by Yuan Zhu on 1/19/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "ViewController.h"
#import <CareKit/CareKit.h>
#import <ResearchKit/ResearchKit.h>


#define DefineStringKey(x) static NSString *const x = @#x

static const BOOL resetStoreOnLaunch = YES;

@interface ViewController () <OCKEvaluationTableViewDelegate, OCKCarePlanStoreDelegate, ORKTaskViewControllerDelegate>

@end


@implementation ViewController {
    UITabBarController *_tabBarController;
    OCKDashboardViewController *_dashboardViewController;
    OCKCareCardViewController *_careCardViewController;
    OCKEvaluationViewController *_evaluationViewController;
    OCKConnectViewController *_connectViewController;
    
    OCKCarePlanStore *_store;
    NSArray<OCKCarePlanActivity *> *_evaluations;
    NSArray<OCKCarePlanActivity *> *_treatments;
}


#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setUpCarePlanStore];

//    dispatch_sync(dispatch_get_main_queue(), ^{
//    });
    
    _dashboardViewController = [self dashboardViewController];
    _careCardViewController = [self careCardViewController];
    _evaluationViewController = [self evaluationViewController];
    _connectViewController = [self connectViewController];
    
    _tabBarController = [UITabBarController new];
    _tabBarController.viewControllers = @[_dashboardViewController, _careCardViewController, _evaluationViewController, _connectViewController];
    _tabBarController.selectedIndex = 1;
}

- (void)viewDidAppear:(BOOL)animated {
    [self presentViewController:_tabBarController animated:YES completion:nil];
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

- (OCKCareCardViewController *)careCardViewController {
    return [OCKCareCardViewController careCardViewControllerWithCarePlanStore:_store];
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


#pragma mark - CarePlan Store

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
    // Reset the store.
    if (resetStoreOnLaunch) {
        [[NSFileManager defaultManager] removeItemAtPath:[self storeDirectoryPath] error:nil];
    }
    
    // Set up store.
    _store = [[OCKCarePlanStore alloc] initWithPersistenceDirectoryURL:[self storeDirectoryURL]];
    _store.delegate = self;
    
    // Add new treatments to store.
    [self generateTreatments];
    for (OCKCarePlanActivity *treatment in _treatments) {
        [_store addActivity:treatment completion:^(BOOL success, NSError * _Nonnull error) {
            if (!success) {
                NSLog(@"%@", error.localizedDescription);
            }
        }];
    }
    
    // Add new evaluations to store.
    [self generateEvaluations];
    for (OCKCarePlanActivity *evaluation in _evaluations) {
        [_store addActivity:evaluation completion:^(BOOL success, NSError * _Nonnull error) {
            if (!success) {
                NSLog(@"%@", error.localizedDescription);
            }
        }];
    }
}


#pragma mark - CareCard

DefineStringKey(MeditationTreatment);
DefineStringKey(IbuprofenTreatment);
DefineStringKey(OutdoorWalkTreatment);
DefineStringKey(PhysicalTherapyTreatment);

- (void)generateTreatments {
    NSMutableArray *treatments = [NSMutableArray new];
    
    NSDateComponents *components = [NSDateComponents new];
    components.year = 2016;
    NSDate *startDate = [[NSCalendar currentCalendar] dateFromComponents:components];
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDate:startDate occurrencesOnEachDay:@[@2,@1,@2,@1,@2,@3,@3]];
        UIColor *color = OCKBlueColor();
        OCKCarePlanActivity *treatment = [[OCKCarePlanActivity alloc] initWithIdentifier:MeditationTreatment
                                                                                    type:OCKCarePlanActivityTypeTreatment
                                                                                   title:@"Meditation"
                                                                                    text:@"30 mins"
                                                                               tintColor:color
                                                                                schedule:schedule];
        [treatments addObject:treatment];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDate:startDate occurrencesOnEachDay:@[@4,@4,@4,@4,@4,@4,@4]];
        UIColor *color = OCKGreenColor();
        OCKCarePlanActivity *treatment = [[OCKCarePlanActivity alloc] initWithIdentifier:IbuprofenTreatment
                                                                                    type:OCKCarePlanActivityTypeTreatment
                                                                                   title:@"Ibuprofen"
                                                                                    text:@"200mg"
                                                                               tintColor:color
                                                                                schedule:schedule];
        [treatments addObject:treatment];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDate:startDate occurrencesOnEachDay:@[@2,@1,@2,@1,@2,@1,@2]];
        UIColor *color = OCKPinkColor();
        OCKCarePlanActivity *treatment = [[OCKCarePlanActivity alloc] initWithIdentifier:OutdoorWalkTreatment
                                                                                    type:OCKCarePlanActivityTypeTreatment
                                                                                   title:@"Outdoor Walk"
                                                                                    text:@"15 mins"
                                                                               tintColor:color
                                                                                schedule:schedule];
        [treatments addObject:treatment];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDate:startDate occurrencesOnEachDay:@[@1,@0,@1,@0,@1,@0,@1]];
        UIColor *color = OCKYellowColor();
        OCKCarePlanActivity *treatment = [[OCKCarePlanActivity alloc] initWithIdentifier:PhysicalTherapyTreatment
                                                                                    type:OCKCarePlanActivityTypeTreatment
                                                                                   title:@"Physical Therapy"
                                                                                    text:@"lower back"
                                                                               tintColor:color
                                                                                schedule:schedule];
        [treatments addObject:treatment];
    }
    
    _treatments = [treatments copy];
}


#pragma mark - Evaluations

DefineStringKey(PainEvaluation);
DefineStringKey(MoodEvaluation);
DefineStringKey(SleepQualityEvaluation);
DefineStringKey(BloodPressureEvaluation);
DefineStringKey(WeightEvaluation);

- (void)generateEvaluations {
    NSMutableArray *evaluations = [NSMutableArray new];
    
    NSDateComponents *components = [NSDateComponents new];
    components.year = 2016;
    NSDate *startDate = [[NSCalendar currentCalendar] dateFromComponents:components];
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDate:startDate occurrencesOnEachDay:@[@1,@0,@1,@0,@1,@0,@1]];
        UIColor *color = OCKBlueColor();
        OCKCarePlanActivity *evaluation = [[OCKCarePlanActivity alloc] initWithIdentifier:PainEvaluation
                                                                                     type:OCKCarePlanActivityTypeAssessment
                                                                                    title:@"Pain"
                                                                                     text:@"lower back"
                                                                                tintColor:color
                                                                                 schedule:schedule];
        [evaluations addObject:evaluation];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDate:startDate occurrencesOnEachDay:@[@1,@1,@1,@1,@1,@1,@1]];
        UIColor *color = OCKGreenColor();
        OCKCarePlanActivity *evaluation = [[OCKCarePlanActivity alloc] initWithIdentifier:MoodEvaluation
                                                                                     type:OCKCarePlanActivityTypeAssessment
                                                                                    title:@"Mood"
                                                                                     text:@"survey"
                                                                                tintColor:color
                                                                                 schedule:schedule];
        [evaluations addObject:evaluation];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDate:startDate occurrencesOnEachDay:@[@1,@1,@0,@1,@1,@1,@0]];
        UIColor *color = OCKRedColor();
        OCKCarePlanActivity *evaluation = [[OCKCarePlanActivity alloc] initWithIdentifier:SleepQualityEvaluation
                                                                                     type:OCKCarePlanActivityTypeAssessment
                                                                                    title:@"Sleep Quality"
                                                                                     text:@"last night"
                                                                                tintColor:color
                                                                                 schedule:schedule];
        [evaluations addObject:evaluation];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDate:startDate occurrencesOnEachDay:@[@0,@1,@0,@1,@0,@1,@0]];
        UIColor *color = OCKYellowColor();
        OCKCarePlanActivity *evaluation = [[OCKCarePlanActivity alloc] initWithIdentifier:BloodPressureEvaluation
                                                                                     type:OCKCarePlanActivityTypeAssessment
                                                                                    title:@"Blood Pressure"
                                                                                     text:@"after dinner"
                                                                                tintColor:color
                                                                                 schedule:schedule];
        [evaluations addObject:evaluation];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDate:startDate occurrencesOnEachDay:@[@1,@1,@1,@1,@1,@1,@1]];
        UIColor *color = OCKPurpleColor();
        OCKCarePlanActivity *evaluation = [[OCKCarePlanActivity alloc] initWithIdentifier:WeightEvaluation
                                                                                     type:OCKCarePlanActivityTypeAssessment
                                                                                    title:@"Weight"
                                                                                     text:@"before breakfast"
                                                                                tintColor:color
                                                                                 schedule:schedule];
        [evaluations addObject:evaluation];
    }
    
    _evaluations = [evaluations copy];
}

- (void)presentViewControllerForEvaluationIdentifier:(NSString *)identifer {
    ORKOrderedTask *task;
    
    if ([identifer isEqualToString:PainEvaluation]) {
        ORKScaleAnswerFormat *format = [ORKScaleAnswerFormat scaleAnswerFormatWithMaximumValue:10
                                                                                  minimumValue:1
                                                                                  defaultValue:NSIntegerMax
                                                                                          step:1
                                                                                      vertical:NO
                                                                       maximumValueDescription:@"Good"
                                                                       minimumValueDescription:@"Bad"];
        
        ORKQuestionStep *step = [ORKQuestionStep questionStepWithIdentifier:@"pain"
                                                                      title:@"How was your lower back pain today?"
                                                                     answer:format];
        step.optional = NO;
    
        task = [[ORKOrderedTask alloc] initWithIdentifier:@"pain" steps:@[step]];
    } else if ([identifer isEqualToString:MoodEvaluation]) {
        ORKScaleAnswerFormat *format = [ORKScaleAnswerFormat scaleAnswerFormatWithMaximumValue:10
                                                                                  minimumValue:1
                                                                                  defaultValue:NSIntegerMax
                                                                                          step:1
                                                                                      vertical:NO
                                                                       maximumValueDescription:@"Good"
                                                                       minimumValueDescription:@"Bad"];
        
        ORKQuestionStep *step = [ORKQuestionStep questionStepWithIdentifier:@"mood"
                                                                      title:@"How was your mood today?"
                                                                     answer:format];
        step.optional = NO;
        
        task = [[ORKOrderedTask alloc] initWithIdentifier:@"mood" steps:@[step]];
        
    } else if ([identifer isEqualToString:SleepQualityEvaluation]) {
        ORKScaleAnswerFormat *format = [ORKScaleAnswerFormat scaleAnswerFormatWithMaximumValue:10
                                                                                  minimumValue:1
                                                                                  defaultValue:NSIntegerMax
                                                                                          step:1
                                                                                      vertical:NO
                                                                       maximumValueDescription:@"Good"
                                                                       minimumValueDescription:@"Bad"];
        
        ORKQuestionStep *step = [ORKQuestionStep questionStepWithIdentifier:@"sleepQuality"
                                                                      title:@"How was your sleep quality?"
                                                                     answer:format];
        step.optional = NO;
        
        task = [[ORKOrderedTask alloc] initWithIdentifier:@"sleepQuality" steps:@[step]];
    } else if ([identifer isEqualToString:BloodPressureEvaluation]) {
        ORKFormStep *step = [[ORKFormStep alloc] initWithIdentifier:@"bloodPressure" title:@"Input your blood pressure" text:nil];
       
        NSMutableArray *items = [NSMutableArray new];
        
        {
            HKQuantityType *healthKitType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodPressureSystolic];
            ORKHealthKitQuantityTypeAnswerFormat *format = [ORKHealthKitQuantityTypeAnswerFormat answerFormatWithQuantityType:healthKitType
                                                                                                                         unit:[HKUnit millimeterOfMercuryUnit]
                                                                                                                        style:ORKNumericAnswerStyleInteger];
            
            ORKFormItem *item = [[ORKFormItem alloc] initWithIdentifier:@"systolicBloodPressure"
                                                                   text:@"Systolic"
                                                           answerFormat:format
                                                               optional:NO];
            [items addObject:item];
        }
        
        {
            HKQuantityType *healthKitType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodPressureDiastolic];
            ORKHealthKitQuantityTypeAnswerFormat *format = [ORKHealthKitQuantityTypeAnswerFormat answerFormatWithQuantityType:healthKitType
                                                                                                                         unit:[HKUnit millimeterOfMercuryUnit]
                                                                                                                        style:ORKNumericAnswerStyleInteger];
            
            ORKFormItem *item = [[ORKFormItem alloc] initWithIdentifier:@"diastolicBloodPressure"
                                                                   text:@"Diastolic"
                                                           answerFormat:format
                                                               optional:NO];
            [items addObject:item];
        }
        
        step.formItems = items;
        step.optional = NO;
        
        task = [[ORKOrderedTask alloc] initWithIdentifier:@"bloodPressure" steps:@[step]];
    } else if ([identifer isEqualToString:WeightEvaluation]) {
        HKQuantityType *quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
        ORKHealthKitQuantityTypeAnswerFormat *format = [ORKHealthKitQuantityTypeAnswerFormat answerFormatWithQuantityType:quantityType
                                                                                                                     unit:[HKUnit poundUnit]
                                                                                                                    style:ORKNumericAnswerStyleDecimal];
        ORKQuestionStep *step = [ORKQuestionStep questionStepWithIdentifier:@"weight"
                                                                      title:@"Input your weight"
                                                                     answer:format];
        step.optional = NO;
        
        task = [[ORKOrderedTask alloc] initWithIdentifier:@"bloodPressure" steps:@[step]];
    }
    
    ORKTaskViewController *taskViewController = [[ORKTaskViewController alloc] initWithTask:task taskRunUUID:nil];
    taskViewController.delegate = self;
    
    [_tabBarController presentViewController:taskViewController animated:YES completion:nil];
}

- (void)updateEvaluationEvent:(OCKCarePlanEvent *)event withTaskResult:(ORKTaskResult *)result {
    NSString *identifier = event.activity.identifier;
    
    if ([identifier isEqualToString:PainEvaluation] ||
        [identifier isEqualToString:MoodEvaluation] ||
        [identifier isEqualToString:SleepQualityEvaluation]) {
        // Fetch the result value.
        ORKStepResult *stepResult = (ORKStepResult*)[result firstResult];
        ORKScaleQuestionResult *questionResult = (ORKScaleQuestionResult*)[stepResult firstResult];
        NSNumber *value = questionResult.scaleAnswer;
        
        OCKCarePlanEventResult *result = [[OCKCarePlanEventResult alloc] initWithValueString:value.stringValue
                                                                                  unitString:@"/10"
                                                                              completionDate:[NSDate date]
                                                                                    userInfo:nil];
        
        [_store updateEvent:event
                 withResult:result
                      state:OCKCarePlanEventStateCompleted
                 completion:^(BOOL success, OCKCarePlanEvent * _Nonnull event, NSError * _Nonnull error) {
                     NSAssert(success, error.localizedDescription);
                 }];
    
    } else if ([identifier isEqualToString:BloodPressureEvaluation]) {
        // Fetch the result value.
        ORKStepResult *stepResult = (ORKStepResult*)[result firstResult];
        NSArray <ORKResult *> *results = stepResult.results;
        
        ORKNumericQuestionResult *result1 = (ORKNumericQuestionResult *)results[0];
        NSNumber *systolicValue = result1.numericAnswer;
        ORKNumericQuestionResult *result2 = (ORKNumericQuestionResult *)results[1];
        NSNumber *diastolicValue = result2.numericAnswer;
        
        OCKCarePlanEventResult *result = [[OCKCarePlanEventResult alloc] initWithValueString:[NSString stringWithFormat:@"%@/%@", systolicValue.stringValue, diastolicValue.stringValue]
                                                                                  unitString:@"mmHg"
                                                                              completionDate:[NSDate date]
                                                                                    userInfo:nil];
        
        [_store updateEvent:event
                 withResult:result
                      state:OCKCarePlanEventStateCompleted
                 completion:^(BOOL success, OCKCarePlanEvent * _Nonnull event, NSError * _Nonnull error) {
                     NSAssert(success, error.localizedDescription);
                 }];
        
    } else if ([identifier isEqualToString:WeightEvaluation]) {
        // Fetch the result value.
        ORKStepResult *stepResult = (ORKStepResult*)[result firstResult];
        NSArray <ORKResult *> *results = stepResult.results;

        ORKNumericQuestionResult *numericResult = (ORKNumericQuestionResult *)results[0];
        NSNumber *weightValue = numericResult.numericAnswer;
        
        OCKCarePlanEventResult *result = [[OCKCarePlanEventResult alloc] initWithValueString:weightValue.stringValue
                                                                                  unitString:@"lbs"
                                                                              completionDate:[NSDate date]
                                                                                    userInfo:nil];
        
        [_store updateEvent:event
                 withResult:result
                      state:OCKCarePlanEventStateCompleted
                 completion:^(BOOL success, OCKCarePlanEvent * _Nonnull event, NSError * _Nonnull error) {
                     NSAssert(success, error.localizedDescription);
                 }];
    }
}


#pragma mark - Evaluation Table View Delegate (OCKEvaluationTableViewDelegate)

- (void)tableViewDidSelectRowWithEvaluationEvent:(OCKCarePlanEvent *)evaluationEvent {
    NSInteger validState = (evaluationEvent.state == OCKCarePlanEventStateInitial || evaluationEvent.state == OCKCarePlanEventStateNotCompleted) ||
    (evaluationEvent.state == OCKCarePlanEventStateCompleted && evaluationEvent.activity.resultResettable);

    if (validState) {
        NSString *identifier = evaluationEvent.activity.identifier;
        [self presentViewControllerForEvaluationIdentifier:identifier];
    }
}


#pragma mark - Task View Controller Delegate (ORKTaskViewControllerDelegate)

- (void)taskViewController:(ORKTaskViewController *)taskViewController didFinishWithReason:(ORKTaskViewControllerFinishReason)reason error:(NSError *)error {
    if (reason == ORKTaskViewControllerFinishReasonCompleted) {
        OCKCarePlanEvent *evaluationEvent = _evaluationViewController.lastSelectedEvaluationEvent;
        ORKTaskResult *taskResult = taskViewController.result;
        [self updateEvaluationEvent:evaluationEvent withTaskResult:taskResult];
    }
    
    [taskViewController dismissViewControllerAnimated:YES completion:nil];
}


@end
