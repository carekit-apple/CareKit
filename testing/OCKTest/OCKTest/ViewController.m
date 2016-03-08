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
#import <MessageUI/MessageUI.h>


#define DefineStringKey(x) static NSString *const x = @#x

static const BOOL resetStoreOnLaunch = YES;

@interface ViewController () <OCKEvaluationTableViewDelegate, OCKCarePlanStoreDelegate, ORKTaskViewControllerDelegate, OCKConnectSharingDelegate, MFMailComposeViewControllerDelegate>

@end


@implementation ViewController {
    OCKCarePlanStore *_store;
    NSArray<OCKCarePlanActivity *> *_evaluations;
    NSArray<OCKCarePlanActivity *> *_treatments;
    
    OCKDashboardViewController *_dashboardViewController;
    OCKCareCardViewController *_careCardViewController;
    OCKEvaluationViewController *_evaluationViewController;
    OCKConnectViewController *_connectViewController;
}


#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self performSelectorOnMainThread:@selector(setUpCarePlanStore) withObject:nil waitUntilDone:YES];
    

    
    _dashboardViewController = [self dashboardViewController];
    _dashboardViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Insights"
                                                                        image:[UIImage imageNamed:@"insights"]
                                                                selectedImage:[UIImage imageNamed:@"insights-filled"]];
    UIImageView *image1 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 7, self.view.frame.size.width, 30)];
    image1.image = [UIImage imageNamed:@"tmc-logo"];
    image1.contentMode = UIViewContentModeScaleAspectFit;
    [_dashboardViewController.navigationBar addSubview:image1];
    
    _careCardViewController = [self careCardViewController];
    _careCardViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Care Card"
                                                                       image:[UIImage imageNamed:@"carecard"]
                                                               selectedImage:[UIImage imageNamed:@"carecard-filled"]];
    UIImageView *image2 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 7, self.view.frame.size.width, 30)];
    image2.image = [UIImage imageNamed:@"tmc-logo"];
    image2.contentMode = UIViewContentModeScaleAspectFit;
    [_careCardViewController.navigationBar addSubview:image2];
    
    _evaluationViewController = [self evaluationViewController];
    _evaluationViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Progress Card"
                                                                         image:[UIImage imageNamed:@"checkups"]
                                                                 selectedImage:[UIImage imageNamed:@"checkups-filled"]];
    UIImageView *image3 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 7, self.view.frame.size.width, 30)];
    image3.image = [UIImage imageNamed:@"tmc-logo"];
    image3.contentMode = UIViewContentModeScaleAspectFit;
    [_evaluationViewController.navigationBar addSubview:image3];
    
    _connectViewController = [self connectViewController];
    _connectViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Connect"
                                                                      image:[UIImage imageNamed:@"connect"]
                                                              selectedImage:[UIImage imageNamed:@"connect-filled"]];
    UIImageView *image4 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 7, self.view.frame.size.width, 30)];
    image4.image = [UIImage imageNamed:@"tmc-logo"];
    image4.contentMode = UIViewContentModeScaleAspectFit;
    [_connectViewController.navigationBar addSubview:image4];
    
    self.tabBar.tintColor = OCKRedColor();
    self.viewControllers = @[_dashboardViewController, _careCardViewController, _evaluationViewController, _connectViewController];
    self.selectedIndex = 1;
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


#pragma mark - Dashboard

- (OCKDashboardViewController *)dashboardViewController {
    NSMutableArray *charts = [NSMutableArray new];
    
    NSArray *axisTitles = @[@"S", @"M", @"T", @"W", @"T", @"F", @"S"];
    NSArray *axisSubtitles = @[@"2/21", @"", @"", @"", @"", @"", @"2/27"];
    
    {
        UIColor *color = OCKBlueColor();
        UIColor *lightColor = [color colorWithAlphaComponent:0.5];
        
        OCKBarGroup *group1 = [OCKBarGroup barGroupWithTitle:@"Pain"
                                                      values:@[@9, @8, @7, @7, @5, @4, @2]
                                                 valueLabels:@[@"9", @"8", @"7", @"7", @"5", @"4", @"2"]
                                                   tintColor:color];
        
        OCKBarGroup *group2 = [OCKBarGroup barGroupWithTitle:@"Medication"
                                                      values:@[@3, @4, @5, @7, @8, @9, @9]
                                                 valueLabels:@[@"30%", @"40%", @"50%", @"70%", @"80%", @"90%", @"90%"]
                                                   tintColor:lightColor];
        
        OCKBarChart *chart = [OCKBarChart barChartWithTitle:@"Pain Scores"
                                                       text:@"with Medication"
                                                 axisTitles:axisTitles
                                              axisSubtitles:axisSubtitles
                                                     groups:@[group1, group2]];
        chart.tintColor = color;
        [charts addObject:chart];
    }
    
    {
        UIColor *color = OCKPurpleColor();
        UIColor *lightColor = [color colorWithAlphaComponent:0.5];
        
        OCKBarGroup *group1 = [OCKBarGroup barGroupWithTitle:@"Range of Motion"
                                                      values:@[@1, @4, @5, @5, @7, @9, @10]
                                                 valueLabels:@[@"10\u00B0", @"40\u00B0", @"50\u00B0", @"50\u00B0", @"70\u00B0", @"90\u00B0", @"100\u00B0"]
                                                   tintColor:color];
        
        OCKBarGroup *group2 = [OCKBarGroup barGroupWithTitle:@"Arm Stretches"
                                                      values:@[@8.5, @7, @5, @4, @3, @3, @2]
                                                 valueLabels:@[@"85%", @"75%", @"50%", @"54%", @"30%", @"30%", @"20%"]
                                                   tintColor:lightColor];
        
        OCKBarChart *chart = [OCKBarChart barChartWithTitle:@"Range of Motion"
                                                       text:@"with Arm Stretch Completion"
                                                 axisTitles:axisTitles
                                              axisSubtitles:axisSubtitles
                                                     groups:@[group1, group2]];
        chart.tintColor = color;
        [charts addObject:chart];
    }
    
    OCKDashboardViewController *dashboard = [OCKDashboardViewController dashboardWithCharts:charts];
    dashboard.headerTitle = @"Weekly Charts";
    dashboard.headerText = @"2/21 - 2/27";
    
    return dashboard;
}


#pragma mark - CareCard

DefineStringKey(IbuprofenTreatment);
DefineStringKey(OutdoorWalkTreatment);
DefineStringKey(PhysicalTherapyTreatment);
DefineStringKey(ExerciseTreatment);
DefineStringKey(WalkTreatment);
DefineStringKey(StretchTreatment);

- (OCKCareCardViewController *)careCardViewController {
    return [OCKCareCardViewController careCardViewControllerWithCarePlanStore:_store];
}
- (void)generateTreatments {
    NSMutableArray *treatments = [NSMutableArray new];

    OCKCarePlanDay *startDate = [[OCKCarePlanDay alloc] initWithYear:2016 month:01 day:01];
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDay:startDate occurrencesOnEachDay:@[@4,@2,@4,@4,@0,@0,@0]];
        UIColor *color = OCKGreenColor();
        OCKCarePlanActivity *treatment = [[OCKCarePlanActivity alloc] initWithIdentifier:PhysicalTherapyTreatment
                                                                                    type:OCKCarePlanActivityTypeIntervention
                                                                                   title:@"Stand"
                                                                                    text:@"1 minute per hour"
                                                                               tintColor:color
                                                                                schedule:schedule];
        [treatments addObject:treatment];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDay:startDate occurrencesOnEachDay:@[@2,@3,@2,@2,@0,@0,@0]];
        UIColor *color = OCKBlueColor();
        OCKCarePlanActivity *treatment = [[OCKCarePlanActivity alloc] initWithIdentifier:IbuprofenTreatment
                                                                         groupIdentifier:nil
                                                                                    type:OCKCarePlanActivityTypeIntervention
                                                                                   title:@"Vicodin"
                                                                                    text:@"5mg/500mg"
                                                                              detailText:@"Take twice daily with food. May cause drowsiness. It is not recommended to drive with this medication. For any severe side effects, please contact your physician."
                                                                               tintColor:color
                                                                                schedule:schedule
                                                                                optional:NO
                                                                   numberOfDaysWriteable:NSIntegerMax
                                                                        resultResettable:YES
                                                                                userInfo:nil];
        [treatments addObject:treatment];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDay:startDate occurrencesOnEachDay:@[@1,@1,@1,@1,@0,@0,@0]];
        UIColor *color = OCKPurpleColor();
        OCKCarePlanActivity *treatment = [[OCKCarePlanActivity alloc] initWithIdentifier:OutdoorWalkTreatment
                                                                                    type:OCKCarePlanActivityTypeIntervention
                                                                                   title:@"Bed Rest"
                                                                                    text:@"limited mobility"
                                                                               tintColor:color
                                                                                schedule:schedule];
        [treatments addObject:treatment];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDay:startDate occurrencesOnEachDay:@[@0,@0,@0,@0,@0,@0,@0]];
        UIColor *color = OCKBlueColor();
        OCKCarePlanActivity *treatment = [[OCKCarePlanActivity alloc] initWithIdentifier:ExerciseTreatment
                                                                                    type:OCKCarePlanActivityTypeIntervention
                                                                                   title:@"Ibuprofen"
                                                                                    text:@"200mg"
                                                                               tintColor:color
                                                                                schedule:schedule];
        [treatments addObject:treatment];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDay:startDate occurrencesOnEachDay:@[@0,@0,@0,@0,@0,@0,@0]];
        UIColor *color = OCKPurpleColor();
        OCKCarePlanActivity *treatment = [[OCKCarePlanActivity alloc] initWithIdentifier:WalkTreatment
                                                                                    type:OCKCarePlanActivityTypeIntervention
                                                                                   title:@"Walk"
                                                                                    text:@"5 minutes"
                                                                               tintColor:color
                                                                                schedule:schedule];
        [treatments addObject:treatment];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDay:startDate occurrencesOnEachDay:@[@0,@0,@0,@0,@0,@0,@0]];
        UIColor *color = OCKYellowColor();
        OCKCarePlanActivity *treatment = [[OCKCarePlanActivity alloc] initWithIdentifier:StretchTreatment
                                                                                    type:OCKCarePlanActivityTypeIntervention
                                                                                   title:@"Stretch Arm"
                                                                                    text:@"2 minutes"
                                                                               tintColor:color
                                                                                schedule:schedule];
        [treatments addObject:treatment];
    }
    
    _treatments = [treatments copy];
}


#pragma mark - Evaluations

DefineStringKey(RangeOfMotionEvaluation);
DefineStringKey(PainEvaluation);
DefineStringKey(BleedingEvaluation);
DefineStringKey(TemperatureEvaluation);

- (OCKEvaluationViewController *)evaluationViewController {
    return [OCKEvaluationViewController evaluationViewControllerWithCarePlanStore:_store
                                                                         delegate:self];
}
- (void)generateEvaluations {
    NSMutableArray *evaluations = [NSMutableArray new];

    OCKCarePlanDay *startDate = [[OCKCarePlanDay alloc] initWithYear:2016 month:01 day:01];

    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDay:startDate occurrencesOnEachDay:@[@1,@1,@1,@0,@0,@0,@0]];
        UIColor *color = OCKPurpleColor();
        OCKCarePlanActivity *evaluation = [[OCKCarePlanActivity alloc] initWithIdentifier:RangeOfMotionEvaluation
                                                                                     type:OCKCarePlanActivityTypeAssessment
                                                                                    title:@"Range of Motion"
                                                                                     text:@"Arm movement"
                                                                                tintColor:color
                                                                                 schedule:schedule];
        [evaluations addObject:evaluation];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDay:startDate occurrencesOnEachDay:@[@1,@1,@1,@0,@0,@0,@0]];
        UIColor *color = OCKBlueColor();
        OCKCarePlanActivity *evaluation = [[OCKCarePlanActivity alloc] initWithIdentifier:PainEvaluation
                                                                                     type:OCKCarePlanActivityTypeAssessment
                                                                                    title:@"Pain"
                                                                                     text:@"Scale assessment"
                                                                                tintColor:color
                                                                                 schedule:schedule];
        [evaluations addObject:evaluation];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDay:startDate occurrencesOnEachDay:@[@1,@1,@1,@0,@1,@0,@1]];
        UIColor *color = OCKGreenColor();
        OCKCarePlanActivity *evaluation = [[OCKCarePlanActivity alloc] initWithIdentifier:BleedingEvaluation
                                                                                     type:OCKCarePlanActivityTypeAssessment
                                                                                    title:@"Bleeding"
                                                                                     text:@"Around surgical area"
                                                                                tintColor:color
                                                                                 schedule:schedule];
        [evaluations addObject:evaluation];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDay:startDate occurrencesOnEachDay:@[@1,@1,@1,@0,@1,@0,@1]];
        UIColor *color = OCKYellowColor();
        OCKCarePlanActivity *evaluation = [[OCKCarePlanActivity alloc] initWithIdentifier:TemperatureEvaluation
                                                                                     type:OCKCarePlanActivityTypeAssessment
                                                                                    title:@"Temperature"
                                                                                     text:@"Oral"
                                                                                tintColor:color
                                                                                 schedule:schedule];
        [evaluations addObject:evaluation];
    }
    
    _evaluations = [evaluations copy];
}
- (void)presentViewControllerForEvaluationIdentifier:(NSString *)identifer {
    ORKOrderedTask *task;
    
    if ([identifer isEqualToString:RangeOfMotionEvaluation]) {
        ORKInstructionStep *step = [[ORKInstructionStep alloc] initWithIdentifier:@"step1"];
        step.title = @"Range of Motion";
        step.text = @"In this active task, you will hold your phone in your right hand and place it by your side. When you hear the beep, raise your arm as high as you can.";
        task = [[ORKOrderedTask alloc] initWithIdentifier:@"hunger" steps:@[step]];
    }
    else if ([identifer isEqualToString:PainEvaluation]) {
        ORKScaleAnswerFormat *format = [ORKScaleAnswerFormat scaleAnswerFormatWithMaximumValue:10
                                                                                  minimumValue:1
                                                                                  defaultValue:NSIntegerMax
                                                                                          step:1
                                                                                      vertical:NO
                                                                       maximumValueDescription:@"Very much"
                                                                       minimumValueDescription:@"Not at all"];
        
        ORKQuestionStep *step = [ORKQuestionStep questionStepWithIdentifier:@"pain"
                                                                      title:@"How was your pain today?"
                                                                     answer:format];
        step.optional = NO;
        
        task = [[ORKOrderedTask alloc] initWithIdentifier:@"fatigue" steps:@[step]];
    }
    else if ([identifer isEqualToString:BleedingEvaluation]) {
        ORKScaleAnswerFormat *format = [ORKScaleAnswerFormat scaleAnswerFormatWithMaximumValue:10
                                                                                  minimumValue:1
                                                                                  defaultValue:NSIntegerMax
                                                                                          step:1
                                                                                      vertical:NO
                                                                       maximumValueDescription:@"Very much"
                                                                       minimumValueDescription:@"Not at all"];
        
        ORKQuestionStep *step = [ORKQuestionStep questionStepWithIdentifier:@"pain"
                                                                      title:@"How was your pain today?"
                                                                     answer:format];
        step.optional = NO;
        
        task = [[ORKOrderedTask alloc] initWithIdentifier:@"fatigue" steps:@[step]];
    }
    else if ([identifer isEqualToString:TemperatureEvaluation]) {
        
        HKQuantityType *quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBasalBodyTemperature];
        ORKHealthKitQuantityTypeAnswerFormat *format = [ORKHealthKitQuantityTypeAnswerFormat answerFormatWithQuantityType:quantityType
                                                                                                                     unit:[HKUnit degreeFahrenheitUnit]
                                                                                                                    style:ORKNumericAnswerStyleDecimal];
        ORKQuestionStep *step = [ORKQuestionStep questionStepWithIdentifier:@"temperature"
                                                                      title:@"Input your temperature"
                                                                     answer:format];
        step.optional = NO;
        
        task = [[ORKOrderedTask alloc] initWithIdentifier:@"bloodPressure" steps:@[step]];
    }
    
    ORKTaskViewController *taskViewController = [[ORKTaskViewController alloc] initWithTask:task taskRunUUID:nil];
    taskViewController.delegate = self;
    
    [self presentViewController:taskViewController animated:YES completion:nil];
}
- (void)updateEvaluationEvent:(OCKCarePlanEvent *)event withTaskResult:(ORKTaskResult *)result {
    NSString *identifier = event.activity.identifier;
    
    if ([identifier isEqualToString:RangeOfMotionEvaluation]) {
        OCKCarePlanEventResult *result = [[OCKCarePlanEventResult alloc] initWithValueString:@"50"
                                                                                  unitString:@"degrees"
                                                                                    userInfo:nil];
        
        [_store updateEvent:event
                 withResult:result
                      state:OCKCarePlanEventStateCompleted
                 completion:^(BOOL success, OCKCarePlanEvent * _Nonnull event, NSError * _Nonnull error) {
                     NSAssert(success, error.localizedDescription);
                 }];
    
    }
    
    else if ([identifier isEqualToString:PainEvaluation]) {
        // Fetch the result value.
        ORKStepResult *stepResult = (ORKStepResult*)[result firstResult];
        NSArray <ORKResult *> *results = stepResult.results;
        
        ORKScaleQuestionResult *numericResult = (ORKScaleQuestionResult *)results[0];
        NSNumber *weightValue = numericResult.scaleAnswer;
        
        OCKCarePlanEventResult *result = [[OCKCarePlanEventResult alloc] initWithValueString:weightValue.stringValue
                                                                                  unitString:@"of 10"
                                                                                    userInfo:nil];
        
        [_store updateEvent:event
                 withResult:result
                      state:OCKCarePlanEventStateCompleted
                 completion:^(BOOL success, OCKCarePlanEvent * _Nonnull event, NSError * _Nonnull error) {
                     NSAssert(success, error.localizedDescription);
                 }];
        
    }
    
    else if ([identifier isEqualToString:BleedingEvaluation]) {
        // Fetch the result value.
        ORKStepResult *stepResult = (ORKStepResult*)[result firstResult];
        NSArray <ORKResult *> *results = stepResult.results;

        ORKScaleQuestionResult *numericResult = (ORKScaleQuestionResult *)results[0];
        NSNumber *weightValue = numericResult.scaleAnswer;
        
        OCKCarePlanEventResult *result = [[OCKCarePlanEventResult alloc] initWithValueString:weightValue.stringValue
                                                                                  unitString:@"of 10"
                                                                                    userInfo:nil];
        
        [_store updateEvent:event
                 withResult:result
                      state:OCKCarePlanEventStateCompleted
                 completion:^(BOOL success, OCKCarePlanEvent * _Nonnull event, NSError * _Nonnull error) {
                     NSAssert(success, error.localizedDescription);
                 }];
    }
    
    else if ([identifier isEqualToString:TemperatureEvaluation]) {
        OCKCarePlanEventResult *result = [[OCKCarePlanEventResult alloc] initWithValueString:@"99.1"
                                                                                  unitString:@"\u00B0F"
                                                                                    userInfo:nil];
        
        [_store updateEvent:event
                 withResult:result
                      state:OCKCarePlanEventStateCompleted
                 completion:^(BOOL success, OCKCarePlanEvent * _Nonnull event, NSError * _Nonnull error) {
                     NSAssert(success, error.localizedDescription);
                 }];
    }
}

#pragma mark Evaluation Table View Delegate (OCKEvaluationTableViewDelegate)

- (void)tableViewDidSelectRowWithEvaluationEvent:(OCKCarePlanEvent *)evaluationEvent {
    NSInteger validState = (evaluationEvent.state == OCKCarePlanEventStateInitial || evaluationEvent.state == OCKCarePlanEventStateNotCompleted) ||
    (evaluationEvent.state == OCKCarePlanEventStateCompleted && evaluationEvent.activity.resultResettable);

    if (validState) {
        NSString *identifier = evaluationEvent.activity.identifier;
        [self presentViewControllerForEvaluationIdentifier:identifier];
    }
}

#pragma mark Task View Controller Delegate (ORKTaskViewControllerDelegate)

- (void)taskViewController:(ORKTaskViewController *)taskViewController didFinishWithReason:(ORKTaskViewControllerFinishReason)reason error:(NSError *)error {
    if (reason == ORKTaskViewControllerFinishReasonCompleted) {
        OCKCarePlanEvent *evaluationEvent = _evaluationViewController.lastSelectedEvaluationEvent;
        ORKTaskResult *taskResult = taskViewController.result;
        [self updateEvaluationEvent:evaluationEvent withTaskResult:taskResult];
    }
    
    [taskViewController dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Connect

- (OCKConnectViewController *)connectViewController {
    NSMutableArray *contacts = [NSMutableArray new];
    
    {
        OCKContact *contact = [OCKContact contactWithContactType:OCKContactTypeClinician
                                                            name:@"Dr. Giselle Guerrero"
                                                        relation:@"Physician"
                                                     phoneNumber:@"123-456-7890"
                                                   messageNumber:nil
                                                    emailAddress:@"g_guerrero@hospital.edu"
                                                           image:[UIImage imageNamed:@"doctor"]];
        contact.tintColor = OCKBlueColor();
        [contacts addObject:contact];
    }
    
    {
        OCKContact *contact = [OCKContact contactWithContactType:OCKContactTypeClinician
                                                            name:@"Greg Apodaca"
                                                        relation:@"Nurse"
                                                     phoneNumber:@"123-456-7890"
                                                   messageNumber:nil
                                                    emailAddress:@"nbrooks@researchkit.org"
                                                           image:[UIImage imageNamed:@"nurse"]];
        contact.tintColor = OCKGreenColor();
        [contacts addObject:contact];
    }
    
    {
        
        OCKContact *contact = [OCKContact contactWithContactType:OCKContactTypeEmergencyContact
                                                            name:@"Kevin Frank"
                                                        relation:@"Father"
                                                     phoneNumber:@"123-456-7890"
                                                   messageNumber:@"123-456-7890"
                                                    emailAddress:nil
                                                           image:[UIImage imageNamed:@"father"]];
        contact.tintColor = OCKYellowColor();
        [contacts addObject:contact];
    }
    
    return [OCKConnectViewController connectViewControllerWithContacts:contacts
                                                       sharingDelegate:self];
}

#pragma mark Connect Sharing Delegate (OCKConnectSharingDelegate)

- (NSString *)titleForSharingCellForContact:(OCKContact *)contact {
    return @"Send weekly reports";
}
- (void)didSelectShareButtonForContact:(OCKContact *)contact {
    MFMailComposeViewController *emailViewController = [MFMailComposeViewController new];
    if ([MFMailComposeViewController canSendMail]) {
        emailViewController.mailComposeDelegate = self;
        [emailViewController setToRecipients:@[contact.emailAddress]];
        [emailViewController setSubject:@"My CareKit Report"];
        
        NSString *pdfPath = [[NSBundle mainBundle] pathForResource:@"MedicalReport" ofType:@"pdf"];
        NSData *pdfData = [NSData dataWithContentsOfFile:pdfPath];
        [emailViewController addAttachmentData:pdfData mimeType:@"application/pdf" fileName:@"CareKitReport.pdf"];
        
        [self presentViewController:emailViewController animated:YES completion:nil];
    }
}

#pragma mark Mail Compose Delegate (MFMailComposeViewControllerDelegate)

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
    if (result == MFMailComposeResultFailed) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                 message:@"Email send failed."
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alertController animated:YES completion:nil];
        
        NSLog(@"%@", error);
    }
}


@end
