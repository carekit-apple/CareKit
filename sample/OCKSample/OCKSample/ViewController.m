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


#import "ViewController.h"


#define DefineStringKey(x) static NSString *const x = @#x

static const BOOL resetStoreOnLaunch = YES;

@interface ViewController () <OCKSymptomTrackerViewControllerDelegate, OCKCarePlanStoreDelegate, OCKConnectViewControllerDelegate, ORKTaskViewControllerDelegate>

@end


@implementation ViewController {
    OCKCarePlanStore *_store;
    NSArray<OCKInsightItem *> *_insightItems;
    NSArray<OCKCarePlanActivity *> *_interventions;
    NSArray<OCKCarePlanActivity *> *_assessments;
    NSArray<OCKContact *> *_contacts;
    OCKInsightsViewController *_insightsViewController;
    OCKCareCardViewController *_careCardViewController;
    OCKSymptomTrackerViewController *_symptomTrackerViewController;
    OCKConnectViewController *_connectViewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setUpCarePlanStore];
    
    _insightsViewController = [self insightsViewController];
    _insightsViewController.title = @"Insights";
    UINavigationController *insightsNavigationViewController = [[UINavigationController alloc] initWithRootViewController:_insightsViewController];
    insightsNavigationViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Insights"
                                                                                image:[UIImage imageNamed:@"insights"]
                                                                        selectedImage:[UIImage imageNamed:@"insights-filled"]];
    
    _careCardViewController = [self careCardViewController];
    _careCardViewController.title = @"Care Card";
    UINavigationController *careCardNavigationViewController = [[UINavigationController alloc] initWithRootViewController:_careCardViewController];
    careCardNavigationViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Care Card"
                                                                                image:[UIImage imageNamed:@"carecard"]
                                                                        selectedImage:[UIImage imageNamed:@"carecard-filled"]];
    
    _symptomTrackerViewController = [self symptomTrackerViewController];
    _symptomTrackerViewController.title = @"Symptom Tracker";
    UINavigationController *symptomTrackerNavigationViewController = [[UINavigationController alloc] initWithRootViewController:_symptomTrackerViewController];
    symptomTrackerNavigationViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Symptom Tracker"
                                                                                      image:[UIImage imageNamed:@"symptoms"]
                                                                              selectedImage:[UIImage imageNamed:@"symptoms-filled"]];
    
    _connectViewController = [self connectViewController];
    _connectViewController.title = @"Connect";
    UINavigationController *connectNavigationViewController = [[UINavigationController alloc] initWithRootViewController:_connectViewController];
    connectNavigationViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Connect"
                                                                               image:[UIImage imageNamed:@"connect"]
                                                                       selectedImage:[UIImage imageNamed:@"connect-filled"]];
    
    self.tabBar.tintColor = OCKRedColor();
    self.viewControllers = @[insightsNavigationViewController, careCardNavigationViewController, symptomTrackerNavigationViewController, connectNavigationViewController];
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
    
    // Add new interventions to store for the Care Card.
    [self generateInterventions];
    for (OCKCarePlanActivity *intervention in _interventions) {
        [_store addActivity:intervention completion:^(BOOL success, NSError * _Nonnull error) {
            if (!success) {
                NSLog(@"%@", error.localizedDescription);
            }
        }];
    }
    
    // Add new assessments to store for the Symptom Tracker.
    [self generateAssessments];
    for (OCKCarePlanActivity *assessment in _assessments) {
        [_store addActivity:assessment completion:^(BOOL success, NSError * _Nonnull error) {
            if (!success) {
                NSLog(@"%@", error.localizedDescription);
            }
        }];
    }
}


#pragma mark - Insights

- (OCKInsightsViewController *)insightsViewController {
    NSMutableArray *items = [NSMutableArray new];
    
    NSArray *axisTitles = @[@"S", @"M", @"T", @"W", @"T", @"F", @"S"];
    NSArray *axisSubtitles = @[@"2/21", @"", @"", @"", @"", @"", @"2/27"];
    
    {
        UIColor *color = OCKPinkColor();
        OCKMessageItem *item = [[OCKMessageItem alloc] initWithWithTitle:@"Medication Adherence"
                                                                    text:@"Your medication adherence was 90% last week."
                                                               tintColor:color
                                                             messageType:OCKMessageItemTypeTip];
        [items addObject:item];
    }
    
    {
        UIColor *color = OCKBlueColor();
        UIColor *lightColor = [color colorWithAlphaComponent:0.5];
        
        OCKBarSeries *series1 = [[OCKBarSeries alloc] initWithTitle:@"Pain"
                                                             values:@[@3, @4, @5, @7, @8, @9, @9]
                                                        valueLabels:@[@"30%", @"40%", @"50%", @"70%", @"80%", @"90%", @"90%"]
                                                          tintColor:color];
        
        OCKBarSeries *series2 = [[OCKBarSeries alloc] initWithTitle:@"Medication"
                                                             values:@[@3, @4, @5, @7, @8, @9, @9]
                                                        valueLabels:@[@"30%", @"40%", @"50%", @"70%", @"80%", @"90%", @"90%"]
                                                          tintColor:lightColor];
        
        OCKBarChart *chart = [[OCKBarChart alloc] initWithWithTitle:@"Pain Scores"
                                                               text:@"with Medication"
                                                          tintColor:color
                                                         axisTitles:axisTitles
                                                      axisSubtitles:axisSubtitles
                                                         dataSeries:@[series1, series2]];
        
        [items addObject:chart];
    }
    
    {
        UIColor *color = OCKGreenColor();
        OCKMessageItem *item = [[OCKMessageItem alloc] initWithWithTitle:@"Pain Score Update"
                                                                    text:@"Your pain score changed from 6 to 3 in the past week."
                                                               tintColor:color
                                                             messageType:OCKMessageItemTypeAlert];
        [items addObject:item];
    }
    
    {
        UIColor *color = OCKPurpleColor();
        UIColor *lightColor = [color colorWithAlphaComponent:0.5];
        
        OCKBarSeries *series1 = [[OCKBarSeries alloc] initWithTitle:@"Range of Motion"
                                                             values:@[@1, @4, @5, @5, @7, @9, @10]
                                                        valueLabels:@[@"10\u00B0", @"40\u00B0", @"50\u00B0", @"50\u00B0", @"70\u00B0", @"90\u00B0", @"100\u00B0"]
                                                          tintColor:color];
        
        OCKBarSeries *series2 = [[OCKBarSeries alloc] initWithTitle:@"Arm Stretches"
                                                             values:@[@8.5, @7, @5, @4, @3, @3, @2]
                                                        valueLabels:@[@"85%", @"75%", @"50%", @"54%", @"30%", @"30%", @"20%"]
                                                          tintColor:lightColor];
        
        OCKBarChart *chart = [[OCKBarChart alloc] initWithWithTitle:@"Range of Motion"
                                                               text:@"with Arm Stretch Completion"
                                                          tintColor:color
                                                         axisTitles:axisTitles
                                                      axisSubtitles:axisSubtitles
                                                         dataSeries:@[series1, series2]];
        
        [items addObject:chart];
    }
    
    _insightItems = [items copy];
    
    OCKInsightsViewController *insights = [[OCKInsightsViewController alloc] initWithInsightItems:items];
    insights.headerTitle = @"Weekly Charts";
    insights.headerSubtitle = @"2/21 - 2/27";
    
    return insights;
}


#pragma mark - Care Card

DefineStringKey(HamstringStretchIntervention);
DefineStringKey(IbuprofenIntervention);
DefineStringKey(OutdoorWalkIntervention);
DefineStringKey(PhysicalTherapyIntervention);

- (OCKCareCardViewController *)careCardViewController {
    return [[OCKCareCardViewController alloc] initWithCarePlanStore:_store];
}
- (void)generateInterventions {
    NSMutableArray *interventions = [NSMutableArray new];
    NSDateComponents *startDate = [[NSDateComponents alloc] initWithYear:2016 month:01 day:01];
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDate:startDate occurrencesOnEachDay:@[@3,@3,@3,@3,@3,@3,@3]];
        UIColor *color = OCKBlueColor();
        OCKCarePlanActivity *intervention = [OCKCarePlanActivity interventionWithIdentifier:HamstringStretchIntervention
                                                                            groupIdentifier:nil
                                                                                      title:@"Hamstring Stretch"
                                                                                       text:@"5 mins"
                                                                                  tintColor:color
                                                                               instructions:nil
                                                                                   imageURL:nil
                                                                                   schedule:schedule
                                                                                   userInfo:nil];
        [interventions addObject:intervention];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDate:startDate occurrencesOnEachDay:@[@4,@4,@4,@4,@4,@4,@4]];
        UIColor *color = OCKGreenColor();
        OCKCarePlanActivity *intervention = [OCKCarePlanActivity interventionWithIdentifier:IbuprofenIntervention
                                                                            groupIdentifier:nil
                                                                                      title:@"Ibuprofen"
                                                                                       text:@"200mg"
                                                                                  tintColor:color
                                                                               instructions:nil
                                                                                   imageURL:nil
                                                                                   schedule:schedule
                                                                                   userInfo:nil];
        [interventions addObject:intervention];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDate:startDate occurrencesOnEachDay:@[@1,@1,@1,@1,@1,@1,@1]];
        UIColor *color = OCKPurpleColor();
        OCKCarePlanActivity *intervention = [OCKCarePlanActivity interventionWithIdentifier:OutdoorWalkIntervention
                                                                            groupIdentifier:nil
                                                                                      title:@"Outdoor Walk"
                                                                                       text:@"15 mins"
                                                                                  tintColor:color
                                                                               instructions:nil
                                                                                   imageURL:nil
                                                                                   schedule:schedule
                                                                                   userInfo:nil];
        [interventions addObject:intervention];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDate:startDate occurrencesOnEachDay:@[@1,@1,@1,@1,@1,@1,@1]];
        UIColor *color = OCKYellowColor();
        OCKCarePlanActivity *intervention = [OCKCarePlanActivity interventionWithIdentifier:PhysicalTherapyIntervention
                                                                            groupIdentifier:nil
                                                                                      title:@"Physical Therapy"
                                                                                       text:@"lower back"
                                                                                  tintColor:color
                                                                               instructions:nil
                                                                                   imageURL:nil
                                                                                   schedule:schedule
                                                                                   userInfo:nil];
        [interventions addObject:intervention];
    }
    
    _interventions = [interventions copy];
}


#pragma mark - Symptom Tracker

DefineStringKey(PainAssessment);
DefineStringKey(MoodAssessment);
DefineStringKey(BloodGlucoseAssessment);
DefineStringKey(WeightAssessment);
DefineStringKey(TemperatureAssessment);

- (OCKSymptomTrackerViewController *)symptomTrackerViewController {
    OCKSymptomTrackerViewController *symptomTrackerViewController = [[OCKSymptomTrackerViewController alloc] initWithCarePlanStore:_store];
    symptomTrackerViewController.delegate = self;
    return symptomTrackerViewController;
}
- (void)generateAssessments {
    NSMutableArray *assessments = [NSMutableArray new];
    NSDateComponents *startDate = [[NSDateComponents alloc] initWithYear:2016 month:01 day:01];
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDate:startDate occurrencesOnEachDay:@[@1,@1,@1,@1,@1,@1,@1]];
        UIColor *color = OCKBlueColor();
        OCKCarePlanActivity *assessment = [OCKCarePlanActivity assessmentWithIdentifier:PainAssessment
                                                                        groupIdentifier:nil
                                                                                  title:@"Pain"
                                                                                   text:@"Lower back"
                                                                              tintColor:color
                                                                       resultResettable:YES
                                                                               schedule:schedule
                                                                               userInfo:nil];
        
        [assessments addObject:assessment];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDate:startDate occurrencesOnEachDay:@[@1,@1,@1,@0,@1,@1,@1]];
        UIColor *color = OCKGreenColor();
        OCKCarePlanActivity *assessment = [OCKCarePlanActivity assessmentWithIdentifier:MoodAssessment
                                                                        groupIdentifier:nil
                                                                                  title:@"Mood"
                                                                                   text:@"Survey"
                                                                              tintColor:color
                                                                       resultResettable:YES
                                                                               schedule:schedule
                                                                               userInfo:nil];
        
        [assessments addObject:assessment];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDate:startDate occurrencesOnEachDay:@[@1,@1,@1,@1,@1,@1,@1]];
        UIColor *color = OCKPurpleColor();
        OCKCarePlanActivity *assessment = [OCKCarePlanActivity assessmentWithIdentifier:BloodGlucoseAssessment
                                                                        groupIdentifier:nil
                                                                                  title:@"Blood Glucose"
                                                                                   text:@"After dinner"
                                                                              tintColor:color
                                                                       resultResettable:YES
                                                                               schedule:schedule
                                                                               userInfo:nil];
        
        [assessments addObject:assessment];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDate:startDate occurrencesOnEachDay:@[@1,@0,@1,@0,@1,@0,@1]];
        UIColor *color = OCKYellowColor();
        OCKCarePlanActivity *assessment = [OCKCarePlanActivity assessmentWithIdentifier:WeightAssessment
                                                                        groupIdentifier:nil
                                                                                  title:@"Weight"
                                                                                   text:@"Early morning"
                                                                              tintColor:color
                                                                       resultResettable:YES
                                                                               schedule:schedule
                                                                               userInfo:nil];
        
        [assessments addObject:assessment];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDate:startDate occurrencesOnEachDay:@[@1,@1,@1,@1,@1,@1,@1]];
        UIColor *color = OCKOrangeColor();
        OCKCarePlanActivity *assessment = [OCKCarePlanActivity assessmentWithIdentifier:TemperatureAssessment
                                                                        groupIdentifier:nil
                                                                                  title:@"Temperature"
                                                                                   text:@"Oral"
                                                                              tintColor:color
                                                                       resultResettable:YES
                                                                               schedule:schedule
                                                                               userInfo:nil];
        
        [assessments addObject:assessment];
    }
    
    _assessments = [assessments copy];
}
- (void)presentViewControllerForAssessmentIdentifier:(NSString *)identifier {
    ORKOrderedTask *task;
    
    if ([identifier isEqualToString:PainAssessment]) {
        ORKScaleAnswerFormat *format = [ORKScaleAnswerFormat scaleAnswerFormatWithMaximumValue:10
                                                                                  minimumValue:1
                                                                                  defaultValue:NSIntegerMax
                                                                                          step:1
                                                                                      vertical:NO
                                                                       maximumValueDescription:@"Very much"
                                                                       minimumValueDescription:@"Not at all"];
        
        ORKQuestionStep *step = [ORKQuestionStep questionStepWithIdentifier:PainAssessment
                                                                      title:@"How was your pain today?"
                                                                     answer:format];
        step.optional = NO;
        
        task = [[ORKOrderedTask alloc] initWithIdentifier:PainAssessment steps:@[step]];
        
    } else if ([identifier isEqualToString:MoodAssessment]) {
        ORKScaleAnswerFormat *format = [ORKScaleAnswerFormat scaleAnswerFormatWithMaximumValue:10
                                                                                  minimumValue:1
                                                                                  defaultValue:NSIntegerMax
                                                                                          step:1
                                                                                      vertical:NO
                                                                       maximumValueDescription:nil
                                                                       minimumValueDescription:nil];
        
        ORKQuestionStep *step = [ORKQuestionStep questionStepWithIdentifier:MoodAssessment
                                                                      title:@"On a scale from 1 to 10, how would you rate your mood today?"
                                                                     answer:format];
        step.optional = NO;
        
        task = [[ORKOrderedTask alloc] initWithIdentifier:MoodAssessment steps:@[step]];
    } else if ([identifier isEqualToString:BloodGlucoseAssessment]) {
        HKQuantityType *quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodGlucose];
        ORKHealthKitQuantityTypeAnswerFormat *format = [ORKHealthKitQuantityTypeAnswerFormat answerFormatWithQuantityType:quantityType
                                                                                                                     unit:[HKUnit unitFromString:@"mg/dL"]
                                                                                                                    style:ORKNumericAnswerStyleDecimal];
        ORKQuestionStep *step = [ORKQuestionStep questionStepWithIdentifier:BloodGlucoseAssessment
                                                                      title:@"Input your blood glucose"
                                                                     answer:format];
        step.optional = NO;
        
        task = [[ORKOrderedTask alloc] initWithIdentifier:BloodGlucoseAssessment steps:@[step]];
    } else if ([identifier isEqualToString:WeightAssessment]) {
        HKQuantityType *quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
        ORKHealthKitQuantityTypeAnswerFormat *format = [ORKHealthKitQuantityTypeAnswerFormat answerFormatWithQuantityType:quantityType
                                                                                                                     unit:[HKUnit poundUnit]
                                                                                                                    style:ORKNumericAnswerStyleDecimal];
        ORKQuestionStep *step = [ORKQuestionStep questionStepWithIdentifier:WeightAssessment
                                                                      title:@"Input your weight"
                                                                     answer:format];
        step.optional = NO;
        
        task = [[ORKOrderedTask alloc] initWithIdentifier:WeightAssessment steps:@[step]];
    } else if ([identifier isEqualToString:TemperatureAssessment]) {
        HKQuantityType *quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyTemperature];
        ORKHealthKitQuantityTypeAnswerFormat *format = [ORKHealthKitQuantityTypeAnswerFormat answerFormatWithQuantityType:quantityType
                                                                                                                     unit:[HKUnit degreeFahrenheitUnit]
                                                                                                                    style:ORKNumericAnswerStyleDecimal];
        ORKQuestionStep *step = [ORKQuestionStep questionStepWithIdentifier:TemperatureAssessment
                                                                      title:@"Input your temperature"
                                                                     answer:format];
        step.optional = NO;
        
        task = [[ORKOrderedTask alloc] initWithIdentifier:TemperatureAssessment steps:@[step]];
    }
    
    ORKTaskViewController *taskViewController = [[ORKTaskViewController alloc] initWithTask:task taskRunUUID:nil];
    taskViewController.delegate = self;
    
    [self presentViewController:taskViewController animated:YES completion:nil];
}
- (void)updateAssessmentEvent:(OCKCarePlanEvent *)event withTaskResult:(ORKTaskResult *)result {
    NSString *identifier = event.activity.identifier;
    
    if ([identifier isEqualToString:PainAssessment] || [identifier isEqualToString:MoodAssessment]) {
        ORKStepResult *stepResult = (ORKStepResult*)[result firstResult];
        NSArray <ORKResult *> *results = stepResult.results;
        ORKScaleQuestionResult *numericResult = (ORKScaleQuestionResult *)results[0];
        
        OCKCarePlanEventResult *result = [[OCKCarePlanEventResult alloc] initWithValueString:numericResult.scaleAnswer.stringValue
                                                                                  unitString:@"of 10"
                                                                                    userInfo:nil];
        [_store updateEvent:event
                 withResult:result
                      state:OCKCarePlanEventStateCompleted
                 completion:^(BOOL success, OCKCarePlanEvent * _Nonnull event, NSError * _Nonnull error) {
                     NSAssert(success, error.localizedDescription);
                 }];
        
    } else if ([identifier isEqualToString:BloodGlucoseAssessment] || [identifier isEqualToString:WeightAssessment] || [identifier isEqualToString:TemperatureAssessment]) {
        ORKStepResult *stepResult = (ORKStepResult*)[result firstResult];
        NSArray <ORKResult *> *results = stepResult.results;
        ORKNumericQuestionResult *numericResult = (ORKNumericQuestionResult *)results[0];
        
        OCKCarePlanEventResult *result = [[OCKCarePlanEventResult alloc] initWithValueString:numericResult.numericAnswer.stringValue
                                                                                  unitString:numericResult.unit
                                                                                    userInfo:nil];
        [_store updateEvent:event
                 withResult:result
                      state:OCKCarePlanEventStateCompleted
                 completion:^(BOOL success, OCKCarePlanEvent * _Nonnull event, NSError * _Nonnull error) {
                     NSAssert(success, error.localizedDescription);
                 }];
        
    }
}

#pragma mark - Symptom Tracker Delegate (OCKSymptomTrackerDelegate)

- (void)symptomTrackerViewController:(OCKSymptomTrackerViewController *)viewController didSelectRowWithAssessmentEvent:(OCKCarePlanEvent *)assessmentEvent {
    NSInteger validState = (assessmentEvent.state == OCKCarePlanEventStateInitial || assessmentEvent.state == OCKCarePlanEventStateNotCompleted) ||
    (assessmentEvent.state == OCKCarePlanEventStateCompleted && assessmentEvent.activity.resultResettable);
    
    if (validState) {
        NSString *identifier = assessmentEvent.activity.identifier;
        [self presentViewControllerForAssessmentIdentifier:identifier];
    }
}

#pragma mark - Task View Controller Delegate (ORKTaskViewControllerDelegate)

- (void)taskViewController:(ORKTaskViewController *)taskViewController didFinishWithReason:(ORKTaskViewControllerFinishReason)reason error:(NSError *)error {
    if (reason == ORKTaskViewControllerFinishReasonCompleted) {
        OCKCarePlanEvent *assessmentEvent = _symptomTrackerViewController.lastSelectedAssessmentEvent;
        ORKTaskResult *taskResult = taskViewController.result;
        [self updateAssessmentEvent:assessmentEvent withTaskResult:taskResult];
    }
    [taskViewController dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Connect

- (OCKConnectViewController *)connectViewController {
    NSMutableArray *contacts = [NSMutableArray new];
    
    {
        UIColor *color = OCKBlueColor();
        OCKContact *contact = [[OCKContact alloc] initWithContactType:OCKContactTypeCareTeam
                                                                 name:@"Dr. Giselle Guerrero"
                                                             relation:@"Physician"
                                                            tintColor:color
                                                          phoneNumber:[CNPhoneNumber phoneNumberWithStringValue:@"123-456-7890"]
                                                        messageNumber:[CNPhoneNumber phoneNumberWithStringValue:@"123-456-7890"]
                                                         emailAddress:@"g_guerrero@hospital.edu"
                                                                image:[UIImage imageNamed:@"doctor"]];
        [contacts addObject:contact];
    }
    
    {
        UIColor *color = OCKGreenColor();
        OCKContact *contact = [[OCKContact alloc] initWithContactType:OCKContactTypeCareTeam
                                                                 name:@"Greg Apodaca"
                                                             relation:@"Nurse"
                                                            tintColor:color
                                                          phoneNumber:[CNPhoneNumber phoneNumberWithStringValue:@"123-456-7890"]
                                                        messageNumber:[CNPhoneNumber phoneNumberWithStringValue:@"123-456-7890"]
                                                         emailAddress:@"nbrooks@hospital.edu"
                                                                image:[UIImage imageNamed:@"nurse"]];
        [contacts addObject:contact];
    }
    
    {
        UIColor *color = OCKYellowColor();
        OCKContact *contact = [[OCKContact alloc] initWithContactType:OCKContactTypePersonal
                                                                 name:@"Kevin Frank"
                                                             relation:@"Father"
                                                            tintColor:color
                                                          phoneNumber:[CNPhoneNumber phoneNumberWithStringValue:@"123-456-7890"]
                                                        messageNumber:[CNPhoneNumber phoneNumberWithStringValue:@"123-456-7890"]
                                                         emailAddress:nil
                                                                image:[UIImage imageNamed:@"father"]];
        [contacts addObject:contact];
    }
    
    _contacts = [contacts copy];
    
    OCKConnectViewController *connectViewController = [[OCKConnectViewController alloc] initWithContacts:contacts];
    connectViewController.delegate = self;
    return connectViewController;
}

- (OCKDocument *)generatePDF {
    OCKDocumentElementSubtitle *subtitle = [[OCKDocumentElementSubtitle alloc] initWithSubtitle:@"First subtitle"];
    OCKDocumentElementParagraph *paragrah = [[OCKDocumentElementParagraph alloc] initWithContent:@"Lorem ipsum dolor sit amet, vim primis noster sententiae ne, et albucius apeirian accusata mea, vim at dicunt laoreet. Eu probo omnes inimicus ius, duo at veritus alienum. Nostrud facilisi id pro. Putant oporteat id eos. Admodum antiopam mel in, at per everti quaeque. Lorem ipsum dolor sit amet, vim primis noster sententiae ne, et albucius apeirian accusata mea, vim at dicunt laoreet. Eu probo omnes inimicus ius, duo at veritus alienum. Nostrud facilisi id pro. Putant oporteat id eos. Admodum antiopam mel in, at per everti quaeque. Lorem ipsum dolor sit amet, vim primis noster sententiae ne, et albucius apeirian accusata mea, vim at dicunt laoreet. Eu probo omnes inimicus ius, duo at veritus alienum. Nostrud facilisi id pro. Putant oporteat id eos. Admodum antiopam mel in, at per everti quaeque."];
    
    OCKChart *chart = (OCKChart *)_insightItems[1];
    OCKDocumentElementChart *barChart = [[OCKDocumentElementChart alloc] initWithChart:chart];
    
    OCKDocumentElementTable *table = [[OCKDocumentElementTable alloc] init];
    table.headers = @[@"Mon", @"Tue", @"Wed", @"Thu", @"Fri"];
    table.rows = @[@[@"1", @"2", @"3", @"4", @"5"], @[@"2", @"3", @"4", @"5", @"6"], @[@"3", @"4", @"5", @"6", @"7"]];
    
    OCKDocument *doc = [[OCKDocument alloc] initWithTitle:@"This is a title" elements:@[subtitle, table, paragrah, barChart]];
    doc.pageHeader = @"App Name: ABC, User Name: John Appleseed";
    
    return doc;
}

#pragma mark Connect View Controller Delegate (OCKConnectViewControllerDelegate)

- (void)connectViewController:(OCKConnectViewController *)connectViewController didSelectShareButtonForContact:(OCKContact *)contact {
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[[self generatePDF]] applicationActivities:nil];
    [self presentViewController:activityController animated:YES completion:nil];
}

- (NSString *)connectViewController:(OCKConnectViewController *)connectViewController titleForSharingCellForContact:(OCKContact *)contact {
    return NSLocalizedString(@"Share report", nil);
}

@end
