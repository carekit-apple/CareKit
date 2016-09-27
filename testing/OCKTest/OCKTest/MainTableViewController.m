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


#import "MainTableViewController.h"
#import "BarChartViewController.h"
#import "DocumentViewController.h"


#define DefineStringKey(x) static NSString *const x = @#x
#define UIColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define RedColor() UIColorFromRGB(0xEF445B);
#define GreenColor() UIColorFromRGB(0x8DC63F);
#define BlueColor() UIColorFromRGB(0x3EA1EE);
#define PurpleColor() UIColorFromRGB(0x9B59B6);
#define PinkColor() UIColorFromRGB(0xF26D7D);
#define YellowColor() UIColorFromRGB(0xF1DF15);
#define OrangeColor() UIColorFromRGB(0xF89406);
#define GrayColor() UIColorFromRGB(0xBDC3C7);

static const BOOL resetStoreOnLaunch = YES;

typedef NS_ENUM(NSInteger, TestItem) {
    TestItemInsights,
    TestItemBarChartView,
    TestItemCareCard,
    TestItemCareCardCustom,
    TestItemSymptomTracker,
    TestItemConnectPage,
    TestItemDocument,
    TestItemCount
};


@implementation MainTableViewController {
    NSArray<OCKInsightItem *> *_items;
    NSArray<OCKCarePlanActivity *> *_interventions;
    NSArray<OCKCarePlanActivity *> *_assessments;
    NSArray<OCKContact *> *_contacts;
    OCKCarePlanStore *_store;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"OCKTest";
    [self setUpCarePlanStore];
}

- (UIViewController *)viewControllerForTestItem:(TestItem)testItem {
    UIViewController *viewController = nil;
    switch (testItem) {
        case TestItemInsights:
            viewController = [self insightsViewController];
            break;
        case TestItemBarChartView:
            viewController = [BarChartViewController new];
            break;
        case TestItemCareCard:
            viewController = [self careCardViewController];
            break;
        case TestItemSymptomTracker:
            viewController = [self symptomTrackerViewController];
            break;
        case TestItemCareCardCustom:
            viewController = [self careCardViewControllerCustom];
            break;
        case TestItemConnectPage:
            viewController = [self connectViewController];
            break;
        case TestItemDocument:
            viewController = [DocumentViewController new];
            break;
        default:
            break;
    }
    return viewController;
}


#pragma mark - Care Plan Store

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
    if (resetStoreOnLaunch) {
        [[NSFileManager defaultManager] removeItemAtPath:[self storeDirectoryPath] error:nil];
    }
    
    _store = [[OCKCarePlanStore alloc] initWithPersistenceDirectoryURL:[self storeDirectoryURL]];
    
    [self generateInterventions];
    for (OCKCarePlanActivity *intervention in _interventions) {
        [_store addActivity:intervention completion:^(BOOL success, NSError * _Nonnull error) {
            if (!success) {
                NSLog(@"%@", error.localizedDescription);
            }
        }];
    }
    
    [self generateAssessments];
    for (OCKCarePlanActivity *assessment in _assessments) {
        [_store addActivity:assessment completion:^(BOOL success, NSError * _Nonnull error) {
            if (!success) {
                NSLog(@"%@", error.localizedDescription);
            }
        }];
    }
}


#pragma mark - OCKInsightsViewController

- (OCKInsightsViewController *)insightsViewController {
    [self generateItems];
    
    OCKInsightsViewController *insightsViewController = [[OCKInsightsViewController alloc] initWithInsightItems:_items];
    insightsViewController.headerTitle = @"Weekly Insights";
    insightsViewController.headerSubtitle = @"3/15 - 3/21";
    return insightsViewController;
}

- (void)generateItems {
    NSMutableArray *items = [NSMutableArray new];
    
    NSArray *axisTitles = @[@"S", @"M", @"T", @"W", @"T", @"F", @"S"];
    NSArray *axisSubtitles = @[@"3/15", @"", @"", @"", @"", @"", @"3/21"];
    
    {
        UIColor *color = PinkColor();
        OCKMessageItem *item = [[OCKMessageItem alloc] initWithTitle:@"Medication Adherence"
                                                                text:@"Your Ibuprofen adherence was 90% last week which resulted in your targeted pain score of 4."
                                                           tintColor:color
                                                         messageType:OCKMessageItemTypeTip];
        [items addObject:item];
    }
    
    {
        UIColor *color = BlueColor();
        UIColor *lightColor = [color colorWithAlphaComponent:0.5];
        
        OCKBarSeries *series1 = [[OCKBarSeries alloc] initWithTitle:@"Pain"
                                                             values:@[@9, @8, @7, @7, @5, @4, @2]
                                                        valueLabels:@[@"9", @"8", @"7", @"7", @"5", @"4", @"2"]
                                                          tintColor:color];
        
        OCKBarSeries *series2 = [[OCKBarSeries alloc] initWithTitle:@"Medication"
                                                             values:@[@3, @4, @5, @7, @8, @9, @9]
                                                        valueLabels:@[@"30%", @"40%", @"50%", @"70%", @"80%", @"90%", @"90%"]
                                                          tintColor:lightColor];
        
        OCKBarChart *chart = [[OCKBarChart alloc] initWithTitle:@"Pain Scores"
                                                           text:@"with Medication"
                                                      tintColor:nil
                                                     axisTitles:axisTitles
                                                  axisSubtitles:axisSubtitles
                                                     dataSeries:@[series1, series2]];
        chart.tintColor = color;
        [items addObject:chart];
    }
    
    {
        UIColor *color = GreenColor();
        OCKMessageItem *item = [[OCKMessageItem alloc] initWithTitle:@"Pain Score Update"
                                                                text:@"Your pain score changed from 9 to 4 in the past week."
                                                           tintColor:color
                                                         messageType:OCKMessageItemTypeAlert];
        [items addObject:item];
    }
    
    {
        UIColor *color = PurpleColor();
        UIColor *lightColor = [color colorWithAlphaComponent:0.5];
        
        OCKBarSeries *series1 = [[OCKBarSeries alloc] initWithTitle:@"Range of Motion"
                                                             values:@[@1, @4, @5, @5, @7, @9, @10]
                                                        valueLabels:@[@"10\u00B0", @"40\u00B0", @"50\u00B0", @"50\u00B0", @"70\u00B0", @"90\u00B0", @"100\u00B0"]
                                                          tintColor:color];
        
        OCKBarSeries *series2 = [[OCKBarSeries alloc] initWithTitle:@"Arm Stretches"
                                                             values:@[@8.5, @7, @5, @4, @3, @3, @2]
                                                        valueLabels:@[@"85%", @"75%", @"50%", @"54%", @"30%", @"30%", @"20%"]
                                                          tintColor:lightColor];
        
        OCKBarChart *chart = [[OCKBarChart alloc] initWithTitle:@"Range of Motion"
                                                           text:@"with Arm Stretch Completion"
                                                      tintColor:color
                                                     axisTitles:axisTitles
                                                  axisSubtitles:axisSubtitles
                                                     dataSeries:@[series1, series2]];
        chart.tintColor = color;
        [items addObject:chart];
    }
    
    _items = [items copy];
}


#pragma mark - OCKCareCardViewController

DefineStringKey(MedicationIntervention);
DefineStringKey(MoveIntervention);
DefineStringKey(DietIntervention);
DefineStringKey(BandageIntervention);

DefineStringKey(MedicationChangeIntervention);
DefineStringKey(MoveChangeIntervention);
DefineStringKey(DietChangeIntervention);
DefineStringKey(BandageChangeIntervention);

- (OCKCareCardViewController *)careCardViewControllerCustom {
    OCKCareCardViewController *careCardViewController = [[OCKCareCardViewController alloc] initWithCarePlanStore:_store];
    careCardViewController.maskImage = [UIImage imageNamed:@"doctor"];
    careCardViewController.smallMaskImage = [UIImage imageNamed:@"doctor"];
    careCardViewController.maskImageTintColor = PurpleColor();
    return careCardViewController;
}

- (OCKCareCardViewController *)careCardViewController {
    OCKCareCardViewController *careCardViewController = [[OCKCareCardViewController alloc] initWithCarePlanStore:_store];
    careCardViewController.delegate = self;
    return careCardViewController;
}

- (void)generateInterventions {
    NSMutableArray *interventions = [NSMutableArray new];
    
    NSDateComponents *startDate = [[NSDateComponents alloc] initWithYear:2016 month:01 day:01];
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDate:startDate occurrencesOnEachDay:@[@4,@10,@10,@12,@12,@0,@0]];
        
        UIGraphicsBeginImageContext(self.view.frame.size);
        [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        NSData *data = UIImagePNGRepresentation(image);
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:@"view.png"];
        [data writeToFile:path atomically:YES];
        
        OCKCarePlanActivity *intervention = [OCKCarePlanActivity interventionWithIdentifier:MedicationIntervention
                                                                            groupIdentifier:nil
                                                                                      title:@"Hydrocodone/Acetaminophen"
                                                                                       text:@"5mg/300mg"
                                                                                  tintColor:nil
                                                                               instructions:@"Take twice daily with food. May cause drowsiness. It is not recommended to drive with this medication. For any severe side effects, please contact your physician."
                                                                                   imageURL:[NSURL fileURLWithPath:path]
                                                                                   schedule:schedule
                                                                                   userInfo:nil];
        
        [interventions addObject:intervention];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDate:startDate occurrencesOnEachDay:@[@2,@2,@2,@2,@2,@0,@0]];
        UIColor *color = PurpleColor();
        
        OCKCarePlanActivity *intervention = [OCKCarePlanActivity interventionWithIdentifier:MoveIntervention
                                                                            groupIdentifier:nil
                                                                                      title:@"Stand and move a little"
                                                                                       text:@"For at least 2 minutes"
                                                                                  tintColor:color
                                                                               instructions:nil
                                                                                   imageURL:nil
                                                                                   schedule:schedule
                                                                                   userInfo:nil];
        [interventions addObject:intervention];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDate:startDate occurrencesOnEachDay:@[@4,@4,@4,@4,@4,@0,@0]];
        UIColor *color = GreenColor();
        
        OCKCarePlanActivity *intervention = [OCKCarePlanActivity interventionWithIdentifier:DietIntervention
                                                                            groupIdentifier:nil
                                                                                      title:@"Diet"
                                                                                       text:@"Fluids only, every 6 hours"
                                                                                  tintColor:color
                                                                               instructions:nil
                                                                                   imageURL:nil
                                                                                   schedule:schedule
                                                                                   userInfo:nil];
        [interventions addObject:intervention];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDate:startDate occurrencesOnEachDay:@[@1,@1,@1,@1,@1,@0,@0]];
        UIColor *color = PinkColor();
        
        OCKCarePlanActivity *intervention = [OCKCarePlanActivity interventionWithIdentifier:BandageIntervention
                                                                            groupIdentifier:nil
                                                                                      title:@"Keep bandage dry"
                                                                                       text:@"Do not change gauze"
                                                                                  tintColor:color
                                                                               instructions:nil
                                                                                   imageURL:nil
                                                                                   schedule:schedule
                                                                                   userInfo:nil];
        [interventions addObject:intervention];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDate:startDate occurrencesOnEachDay:@[@0,@0,@0,@0,@0,@3,@3]];
        UIColor *color = BlueColor();
        
        OCKCarePlanActivity *intervention = [OCKCarePlanActivity interventionWithIdentifier:MedicationChangeIntervention
                                                                            groupIdentifier:nil
                                                                                      title:@"Ibuprofen"
                                                                                       text:@"400mg"
                                                                                  tintColor:color
                                                                               instructions:nil
                                                                                   imageURL:nil
                                                                                   schedule:schedule
                                                                                   userInfo:nil];
        [interventions addObject:intervention];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDate:startDate occurrencesOnEachDay:@[@0,@0,@0,@0,@0,@2,@2]];
        UIColor *color = PurpleColor();
        
        OCKCarePlanActivity *intervention = [OCKCarePlanActivity interventionWithIdentifier:MoveChangeIntervention
                                                                            groupIdentifier:nil
                                                                                      title:@"Walk"
                                                                                       text:@"5 minutes"
                                                                                  tintColor:color
                                                                               instructions:nil
                                                                                   imageURL:nil
                                                                                   schedule:schedule
                                                                                   userInfo:nil];
        [interventions addObject:intervention];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDate:startDate occurrencesOnEachDay:@[@0,@0,@0,@0,@0,@4,@4]];
        UIColor *color = GreenColor();
        
        OCKCarePlanActivity *intervention = [OCKCarePlanActivity interventionWithIdentifier:DietIntervention
                                                                            groupIdentifier:nil
                                                                                      title:@"Diet"
                                                                                       text:@"Eat soft solid foods every 6 hours"
                                                                                  tintColor:color
                                                                               instructions:nil
                                                                                   imageURL:nil
                                                                                   schedule:schedule
                                                                                   userInfo:nil];
        [interventions addObject:intervention];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule weeklyScheduleWithStartDate:startDate occurrencesOnEachDay:@[@0,@0,@0,@0,@0,@1,@1]];
        UIColor *color = PinkColor();
        
        OCKCarePlanActivity *intervention = [OCKCarePlanActivity interventionWithIdentifier:BandageChangeIntervention
                                                                            groupIdentifier:nil
                                                                                      title:@"Change bandage"
                                                                                       text:@"Use new gauze"
                                                                                  tintColor:color
                                                                               instructions:nil
                                                                                   imageURL:nil
                                                                                   schedule:schedule
                                                                                   userInfo:nil];
        [interventions addObject:intervention];
    }
    
    _interventions = [interventions copy];
}

- (BOOL)careCardViewController:(OCKCareCardViewController *)viewController shouldHandleEventCompletionForActivity:(OCKCarePlanActivity *)interventionActivity {
    BOOL shouldHandleEventCompletion = YES;
    if ([interventionActivity.identifier isEqualToString:MoveIntervention]) {
        shouldHandleEventCompletion = NO;
    }
    return shouldHandleEventCompletion;
}

- (void)careCardViewController:(OCKCareCardViewController *)viewController didSelectButtonWithInterventionEvent:(OCKCarePlanEvent *)interventionEvent {
    if ([interventionEvent.activity.identifier isEqualToString:MoveIntervention]) {
        OCKCarePlanEventState state = (interventionEvent.state == OCKCarePlanEventStateCompleted) ? OCKCarePlanEventStateNotCompleted : OCKCarePlanEventStateCompleted;
        
        [viewController.store updateEvent:interventionEvent
                               withResult:nil
                                    state:state
                               completion:^(BOOL success, OCKCarePlanEvent * _Nullable event, NSError * _Nullable error) {
                                   NSAssert(success, error.localizedDescription);
                               }];
    }
}


#pragma mark - OCKSymptomTrackerViewController

DefineStringKey(RangeOfMotionAssessment);
DefineStringKey(PainAssessment);
DefineStringKey(BleedingAssessment);
DefineStringKey(TemperatureAssessment);

- (OCKSymptomTrackerViewController *)symptomTrackerViewController {
    OCKSymptomTrackerViewController *symptomTrackerViewController = [[OCKSymptomTrackerViewController alloc] initWithCarePlanStore:_store];
    symptomTrackerViewController.delegate = self;
    symptomTrackerViewController.progressRingTintColor = [UIColor greenColor];
    return symptomTrackerViewController;
}

- (void)generateAssessments {
    NSMutableArray *assessments = [NSMutableArray new];
    
    NSDateComponents *startDate = [[NSDateComponents alloc] initWithYear:2016 month:01 day:01];
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule dailyScheduleWithStartDate:startDate occurrencesPerDay:1];
        
        OCKCarePlanActivity *assessment = [OCKCarePlanActivity assessmentWithIdentifier:RangeOfMotionAssessment
                                                                        groupIdentifier:nil
                                                                                  title:@"Range of Motion"
                                                                                   text:@"Arm movement"
                                                                              tintColor:nil
                                                                       resultResettable:NO
                                                                               schedule:schedule
                                                                               userInfo:nil];
        [assessments addObject:assessment];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule dailyScheduleWithStartDate:startDate occurrencesPerDay:3];
        UIColor *color = BlueColor();
        
        OCKCarePlanActivity *assessment = [OCKCarePlanActivity assessmentWithIdentifier:PainAssessment
                                                                        groupIdentifier:nil
                                                                                  title:@"Pain jasdfj sadfj "
                                                                                   text:@"Scale assessment asdfkj sadfkj "
                                                                              tintColor:color
                                                                       resultResettable:NO
                                                                               schedule:schedule
                                                                               userInfo:nil];
        [assessments addObject:assessment];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule dailyScheduleWithStartDate:startDate occurrencesPerDay:1];
        UIColor *color = GreenColor();
        
        OCKCarePlanActivity *assessment = [OCKCarePlanActivity assessmentWithIdentifier:BleedingAssessment
                                                                        groupIdentifier:nil
                                                                                  title:@"Bleeding"
                                                                                   text:@"Around wound"
                                                                              tintColor:color
                                                                       resultResettable:NO
                                                                               schedule:schedule
                                                                               userInfo:nil];
        [assessments addObject:assessment];
    }
    
    {
        OCKCareSchedule *schedule = [OCKCareSchedule dailyScheduleWithStartDate:startDate occurrencesPerDay:1];
        UIColor *color = YellowColor();
        
        OCKCarePlanActivity *assessment = [OCKCarePlanActivity assessmentWithIdentifier:TemperatureAssessment
                                                                        groupIdentifier:nil
                                                                                  title:@"Temperature"
                                                                                   text:@"Oral"
                                                                              tintColor:color
                                                                       resultResettable:NO
                                                                               schedule:schedule
                                                                               userInfo:nil];
        [assessments addObject:assessment];
    }
    
    _assessments = [assessments copy];
}

- (void)symptomTrackerViewController:(OCKSymptomTrackerViewController *)viewController didSelectRowWithAssessmentEvent:(OCKCarePlanEvent *)assessmentEvent {
    NSString *identifier = assessmentEvent.activity.identifier;
    
    if ([identifier isEqualToString:RangeOfMotionAssessment]) {
        OCKCarePlanEventResult *result = [[OCKCarePlanEventResult alloc] initWithValueString:@"50"
                                                                                  unitString:@"degrees"
                                                                                    userInfo:nil];
        [_store updateEvent:assessmentEvent
                 withResult:result
                      state:OCKCarePlanEventStateCompleted
                 completion:^(BOOL success, OCKCarePlanEvent * _Nonnull event, NSError * _Nonnull error) {
                     NSAssert(success, error.localizedDescription);
                 }];
    } else if ([identifier isEqualToString:PainAssessment]) {
        OCKCarePlanEventResult *result = [[OCKCarePlanEventResult alloc] initWithValueString:@"6 asdfkj lkdasf"
                                                                                  unitString:@"of 10"
                                                                                    userInfo:nil];
        [_store updateEvent:assessmentEvent
                 withResult:result
                      state:OCKCarePlanEventStateCompleted
                 completion:^(BOOL success, OCKCarePlanEvent * _Nonnull event, NSError * _Nonnull error) {
                     NSAssert(success, error.localizedDescription);
                 }];
    } else if ([identifier isEqualToString:BleedingAssessment]) {
        OCKCarePlanEventResult *result = [[OCKCarePlanEventResult alloc] initWithValueString:@"2"
                                                                                  unitString:@"of 10"
                                                                                    userInfo:nil];
        [_store updateEvent:assessmentEvent
                 withResult:result
                      state:OCKCarePlanEventStateCompleted
                 completion:^(BOOL success, OCKCarePlanEvent * _Nonnull event, NSError * _Nonnull error) {
                     NSAssert(success, error.localizedDescription);
                 }];
    } else if ([identifier isEqualToString:TemperatureAssessment]) {
        
        HKHealthStore *hkstore = [HKHealthStore new];
        HKQuantityType *type = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyTemperature];
    
        [hkstore requestAuthorizationToShareTypes:[NSSet setWithObject:type]
                                        readTypes:[NSSet setWithObject:type]
                                       completion:^(BOOL success, NSError * _Nullable error) {
                                           
                                           HKQuantitySample *sample = [HKQuantitySample quantitySampleWithType:type
                                                                                                      quantity:[HKQuantity quantityWithUnit:[HKUnit degreeFahrenheitUnit] doubleValue:99.1]
                                                                                                     startDate:[NSDate date]
                                                                                                       endDate:[NSDate date]];
                                           
                                           [hkstore saveObject:sample withCompletion:^(BOOL success, NSError * _Nullable error) {
                                               OCKCarePlanEventResult *result = [[OCKCarePlanEventResult alloc] initWithQuantitySample:sample
                                                                                                               quantityStringFormatter:nil
                                                                                                                        unitStringKeys:@{[HKUnit degreeFahrenheitUnit]: @"\u00B0F",
                                                                                                                                         [HKUnit degreeCelsiusUnit]: @"\u00B0C",}
                                                                                                                              userInfo:nil];
                                               [_store updateEvent:assessmentEvent
                                                        withResult:result
                                                             state:OCKCarePlanEventStateCompleted
                                                        completion:^(BOOL success, OCKCarePlanEvent * _Nonnull event, NSError * _Nonnull error) {
                                                            NSAssert(success, error.localizedDescription);
                                                        }];
                                           }];
                                           
                                        }];
    }
}


#pragma mark - OCKConnectViewController

- (OCKConnectViewController *)connectViewController {
    [self generateContacts];
    
    OCKConnectViewController *connectViewController = [[OCKConnectViewController alloc] initWithContacts:_contacts];
    connectViewController.delegate = self;
    return connectViewController;
}

- (void)generateContacts {
    NSMutableArray *contacts = [NSMutableArray new];
    
    {
        UIColor *color = BlueColor();
        OCKContact *contact = [[OCKContact alloc] initWithContactType:OCKContactTypeCareTeam
                                                                 name:@"Dr. Maria Ruiz"
                                                             relation:@"Physician"
                                                            tintColor:color
                                                          phoneNumber:[CNPhoneNumber phoneNumberWithStringValue:@"888-555-5512"]
                                                        messageNumber:[CNPhoneNumber phoneNumberWithStringValue:@"888-555-5512"]
                                                         emailAddress:@"mruiz2@mac.com"
                                                             monogram:@"MR"
                                                                image:nil];
        [contacts addObject:contact];
    }
    
    {
        UIColor *color = GreenColor();
        OCKContact *contact = [[OCKContact alloc] initWithContactType:OCKContactTypeCareTeam
                                                                 name:@"Bill James"
                                                             relation:@"Nurse"
                                                            tintColor:color
                                                          phoneNumber:[CNPhoneNumber phoneNumberWithStringValue:@"888-555-5512"]
                                                        messageNumber:[CNPhoneNumber phoneNumberWithStringValue:@"888-555-5512"]
                                                         emailAddress:@"billjames2@mac.com"
                                                             monogram:@"BJ"
                                                                image:nil];
        [contacts addObject:contact];
    }
    
    {
        OCKContact *contact = [[OCKContact alloc] initWithContactType:OCKContactTypePersonal
                                                                 name:@"Tom Clark"
                                                             relation:@"Father"
                                                            tintColor:nil
                                                          phoneNumber:[CNPhoneNumber phoneNumberWithStringValue:@"888-555-5512"]
                                                        messageNumber:[CNPhoneNumber phoneNumberWithStringValue:@"888-555-5512"]
                                                         emailAddress:nil
                                                             monogram:@"TC"
                                                                image:nil];
        [contacts addObject:contact];
    }
    
    _contacts = [contacts copy];
}


#pragma mark - OCKConnectViewControllerDelegate

- (NSString *)connectViewController:(OCKConnectViewController *)connectViewController titleForSharingCellForContact:(OCKContact *)contact {
    NSString *title;
    if (![contact isEqual:_contacts[1]]){
        title = @"Send weekly reports";
    }
    return title;
}

- (void)connectViewController:(OCKConnectViewController *)connectViewController didSelectShareButtonForContact:(OCKContact *)contact presentationSourceView:(UIView *)sourceView {
    NSLog(@"Share button tapped");
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return TestItemCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    NSString *title = @"";
    switch (indexPath.row) {
        case TestItemInsights:
            title = @"Insights";
            break;
        case TestItemBarChartView:
            title = @"Bar Chart View";
            break;
        case TestItemCareCard:
            title = @"Care Card";
            break;
        case TestItemCareCardCustom:
            title = @"Care Card - Custom";
            break;
        case TestItemSymptomTracker:
            title = @"Symptom Tracker";
            break;
        case TestItemConnectPage:
            title = @"Connect Page";
            break;
        case TestItemDocument:
            title = @"PDF Document";
            break;
        default:
            title = @"Unknown";
            break;
    }
    cell.textLabel.text = title;
    return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.navigationController pushViewController:[self viewControllerForTestItem:indexPath.row] animated:YES];
}

@end
