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


import CareKit
import HealthKit


class SymptomTrackerTableViewController: UITableViewController, OCKSymptomTrackerViewControllerDelegate {
    
    var healthKitStore:HKHealthStore?

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("cell") {
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "No Delegate, No Edges"
            case 1:
                cell.textLabel?.text = "No Activities"
            case 2:
                cell.textLabel?.text = "With Delegate"
            case 3:
                cell.textLabel?.text = "Track Health Data"
                if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.Pad {
                    cell.textLabel?.textColor = UIColor.grayColor()
                    cell.userInteractionEnabled = false
                }
            case 4:
                cell.textLabel?.text = "Delete all Activites"
            default:
                cell.textLabel?.text = nil
            }
            return cell
        } else {
            return UITableViewCell.init()
        }
        
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        
        if indexPath.row == 0 {
            
            // No Delegate, No Edges
            
            let startDateComponents = NSDateComponents.init()
            startDateComponents.day = 20
            startDateComponents.month = 3
            startDateComponents.year = 2000
            let schedule = OCKCareSchedule.dailyScheduleWithStartDate(startDateComponents, occurrencesPerDay: 1)
            let firstGroupId = "Group A1"
            let carePlanActivity1 = OCKCarePlanActivity.init(identifier: "Assessment Activity #1", groupIdentifier: firstGroupId, type: OCKCarePlanActivityType.Assessment, title: "Assessment Activity Title 1", text: "Read the instructions about this task", tintColor: UIColor.redColor(), instructions: "Perform the described task and report the results. Talk to your doctor if you need help", imageURL: nil, schedule: schedule, resultResettable: true, userInfo: ["Key1":"Value1","Key2":"Value2"])

            let carePlanActivity2 = OCKCarePlanActivity.init(identifier: "Assessment Activity #2", groupIdentifier: firstGroupId, type: OCKCarePlanActivityType.Assessment, title: "Assessment Activity Title 2", text: "Complete this activity ASAP", tintColor: UIColor.orangeColor(), instructions: nil, imageURL: nil, schedule: schedule, resultResettable: true, userInfo: ["Key1":"Value1","Key2":"Value2"])

            let carePlanStore = OCKCarePlanStore.init(persistenceDirectoryURL: NSURL.init(string: documentsDirectory[0])!)
            carePlanStore .addActivity(carePlanActivity1, completion: { (boolVal, error) in
                assert(boolVal, (error?.description)!)
            })
            carePlanStore .addActivity(carePlanActivity2, completion: { (boolVal, error) in
                assert(boolVal, (error?.description)!)
            })
            let symptomTracker = OCKSymptomTrackerViewController.init(carePlanStore: carePlanStore)
            self.navigationController?.pushViewController(symptomTracker, animated: true)
            
        } else if indexPath.row == 1 {
            
            // No Activities

            let dataPath = documentsDirectory[0].stringByAppendingString("/EmptyAssessmentPlan")
            if !NSFileManager.defaultManager().fileExistsAtPath(dataPath) {
                do {
                    try NSFileManager.defaultManager().createDirectoryAtPath(dataPath, withIntermediateDirectories: false, attributes: nil)
                } catch(_) {
                    assertionFailure("Unable to Create Directory for EmptyAssessmentPlan")
                }
            }
            
            let carePlanStore = OCKCarePlanStore.init(persistenceDirectoryURL: NSURL.init(string: dataPath)!)

            let symptomTracker = OCKSymptomTrackerViewController.init(carePlanStore: carePlanStore)
            symptomTracker.showEdgeIndicators = true
            self.navigationController?.pushViewController(symptomTracker, animated: true)
       
        } else if indexPath.row == 2 {
            
            // With Delegate
            
            let startDateComponents = NSDateComponents.init()
            startDateComponents.day = 20
            startDateComponents.month = 3
            startDateComponents.year = 0010
            
            let endDate = NSDate().dateByAddingTimeInterval(-86400.0)
            let unitFlags: NSCalendarUnit = [.Day, .Month, .Year]
            let endDateComponents = NSCalendar.currentCalendar().components(unitFlags, fromDate: endDate)
            
            let schedule1 = OCKCareSchedule.weeklyScheduleWithStartDate(startDateComponents, occurrencesOnEachDay: [1, 2, 3, 4, 5, 6, 7], weeksToSkip: 0, endDate: endDateComponents)
            let schedule2 = OCKCareSchedule.dailyScheduleWithStartDate(startDateComponents, occurrencesPerDay: 1, daysToSkip: 0, endDate: nil)
            let secondGroupId = "Group A2"
            let carePlanActivity1 = OCKCarePlanActivity.init(identifier: "Assessment Activity #1", groupIdentifier: secondGroupId, type: OCKCarePlanActivityType.Assessment, title: "Activity that ended yesterday ", text: "Read the instructions about this task", tintColor: nil, instructions: "Perform the described task and report the results. Talk to your doctor if you need help", imageURL: nil, schedule: schedule1, resultResettable: false, userInfo: ["Key1":"Value1","Key2":"Value2"])
            
            let carePlanActivity2 = OCKCarePlanActivity.assessmentWithIdentifier("Assessment Activity #2", groupIdentifier: secondGroupId, title: "A Daily Activity is one that repeats every day", text: "This is an assessment. Be careful. You are being evaluated every single day.", tintColor: UIColor.purpleColor(), resultResettable: false, schedule: schedule2, userInfo: nil)
            
            let dataPath = documentsDirectory[0].stringByAppendingString("/CarePlan2")
            if !NSFileManager.defaultManager().fileExistsAtPath(dataPath) {
                do {
                    try NSFileManager.defaultManager().createDirectoryAtPath(dataPath, withIntermediateDirectories: false, attributes: nil)
                } catch(_) {
                    assertionFailure("Unable to Create Directory for CarePlan2")
                }
            }
    
            let carePlanStore = OCKCarePlanStore.init(persistenceDirectoryURL: NSURL.init(string: dataPath)!)
            carePlanStore.addActivity(carePlanActivity1, completion: { (boolVal, error) in
                assert(boolVal, (error?.description)!)
            })
            carePlanStore.addActivity(carePlanActivity2, completion: { (boolVal, error) in
                assert(boolVal, (error?.description)!)
            })
            
            let symptomTracker = OCKSymptomTrackerViewController.init(carePlanStore: carePlanStore)
            symptomTracker.progressRingTintColor = UIColor.magentaColor()
            symptomTracker.delegate = self
            symptomTracker.showEdgeIndicators = true
            self.navigationController?.pushViewController(symptomTracker, animated: true)
     
        } else if indexPath.row == 3 {
            
            // Track Health Data
            
            self.authorizeHealthKit({ (success, error) in
                assert(success, error.description)
                dispatch_async(dispatch_get_main_queue()) {
                    self.saveHKSamples()
                }
            })
            
            let startDateComponents = NSDateComponents.init(year: 1, month: 1, day: 1)
            let schedule = OCKCareSchedule.weeklyScheduleWithStartDate(startDateComponents, occurrencesOnEachDay: [1, 1, 1, 1, 1, 1, 1])
            
            let dataPath = documentsDirectory[0].stringByAppendingString("/CarePlanHealth")
            if !NSFileManager.defaultManager().fileExistsAtPath(dataPath) {
                do {
                    try NSFileManager.defaultManager().createDirectoryAtPath(dataPath, withIntermediateDirectories: false, attributes: nil)
                } catch(_) {
                    assertionFailure("Unable to Create Directory for CarePlanHealth")
                }
            }
            
            let carePlanStore = OCKCarePlanStore.init(persistenceDirectoryURL: NSURL.init(string: dataPath)!)
            let thirdGroupId = "Group A3"
            let carePlanActivity1 = OCKCarePlanActivity.assessmentWithIdentifier("Step Count", groupIdentifier: thirdGroupId, title: "Step Count", text: "Get steps from Health app", tintColor: UIColor.init(red: 0.3, green: 0.2, blue: 0.9, alpha: 0.4), resultResettable: true, schedule: schedule, userInfo: ["Type":"Steps"])
            carePlanStore.addActivity(carePlanActivity1, completion: { (boolVal, error) in
                assert(boolVal, (error?.description)!)
            })
            let carePlanActivity2 = OCKCarePlanActivity.assessmentWithIdentifier("Body Fat", groupIdentifier: thirdGroupId, title: "Body Fat", text: "Get Body Fat from Health app", tintColor: UIColor.init(red: 0.3, green: 0.2, blue: 0.9, alpha: 0.4), resultResettable: true, schedule: schedule, userInfo:  ["Type":"BodyFat"])
            carePlanStore.addActivity(carePlanActivity2, completion: { (boolVal, error) in
                assert(boolVal, (error?.description)!)
            })
            let carePlanActivity3 = OCKCarePlanActivity.assessmentWithIdentifier("Sleep Analysis", groupIdentifier: thirdGroupId, title: "Sleep Analysis", text: "Get Sleep Data from Health app", tintColor: UIColor.init(red: 0.3, green: 0.2, blue: 0.9, alpha: 0.4), resultResettable: true, schedule: schedule, userInfo: ["Type":"Sleep"])
            carePlanStore.addActivity(carePlanActivity3, completion: { (boolVal, error) in
                assert(boolVal, (error?.description)!)
            })
            let carePlanActivity4 = OCKCarePlanActivity.assessmentWithIdentifier("Ovulation", groupIdentifier: thirdGroupId, title: "Ovulation", text: "Get Ovulation Data from Health app", tintColor: UIColor.init(red: 0.3, green: 0.2, blue: 0.9, alpha: 0.4), resultResettable: true, schedule: schedule, userInfo: ["Type":"Ovulation"])
            carePlanStore.addActivity(carePlanActivity4, completion: { (boolVal, error) in
                assert(boolVal, (error?.description)!)
            })
            
            let carePlanActivity5 = OCKCarePlanActivity.assessmentWithIdentifier("Blood Pressure", groupIdentifier: thirdGroupId, title: "Blood Pressure", text: "Get Blood Pressure from Health app", tintColor: UIColor.init(red: 0.3, green: 0.2, blue: 0.9, alpha: 0.4), resultResettable: true, schedule: schedule, userInfo: ["Type":"Blood Pressure"])
            carePlanStore.addActivity(carePlanActivity5, completion: { (boolVal, error) in
                assert(boolVal, (error?.description)!)
            })
            
            let symptomTracker = OCKSymptomTrackerViewController.init(carePlanStore: carePlanStore)
            symptomTracker.delegate = self
            symptomTracker.showEdgeIndicators = true
            symptomTracker.progressRingTintColor = UIColor.init(red: 0.3, green: 0.2, blue: 0.9, alpha: 0.4)
            self.navigationController?.pushViewController(symptomTracker, animated: true)

        } else if indexPath.row == 4 {
            
            // Delete all Activites
            
            tableView.cellForRowAtIndexPath(indexPath)?.selected = false
            let store = OCKCarePlanStore.init(persistenceDirectoryURL: NSURL.init(string: documentsDirectory[0])!)
            
            store.activitiesWithGroupIdentifier("Group A1", completion: { (boolVal, activities, error) in
                for activity:OCKCarePlanActivity in activities
                {
                    store.removeActivity(activity, completion: { (boolVal, error) in
                        if boolVal == true {
                            tableView.cellForRowAtIndexPath(indexPath)?.textLabel?.textColor = UIColor.greenColor()
                        } else {
                            tableView.cellForRowAtIndexPath(indexPath)?.textLabel?.textColor = UIColor.redColor()
                        }
                        assert(boolVal, (error?.description)!)
                    })
                }
            })
            
            if NSFileManager.defaultManager().fileExistsAtPath(documentsDirectory[0].stringByAppendingString("/CarePlan2")) {
                let dataPath = NSURL.init(string:documentsDirectory[0].stringByAppendingString("/CarePlan2"))
                let store2 = OCKCarePlanStore.init(persistenceDirectoryURL: dataPath!)
                store2.activitiesWithGroupIdentifier("Group A2", completion: { (boolVal, activities, error) in
                    for activity:OCKCarePlanActivity in activities
                    {
                        store2.removeActivity(activity, completion: { (boolVal, error) in
                            if boolVal == true {
                                tableView.cellForRowAtIndexPath(indexPath)?.textLabel?.textColor = UIColor.greenColor()
                            } else {
                                tableView.cellForRowAtIndexPath(indexPath)?.textLabel?.textColor = UIColor.redColor()
                            }
                            assert(boolVal, (error?.description)!)
                        })
                    }
                })
            }
            
            if NSFileManager.defaultManager().fileExistsAtPath(documentsDirectory[0].stringByAppendingString("/CarePlanHealth")) {
                let dataPath = NSURL.init(string:documentsDirectory[0].stringByAppendingString("/CarePlanHealth"))
                let store3 = OCKCarePlanStore.init(persistenceDirectoryURL:dataPath!)
                store3.activitiesWithGroupIdentifier("Group A3", completion: { (boolVal, activities, error) in
                    for activity:OCKCarePlanActivity in activities
                    {
                        store3.removeActivity(activity, completion: { (boolVal, error) in
                            if boolVal == true {
                                tableView.cellForRowAtIndexPath(indexPath)?.textLabel?.textColor = UIColor.greenColor()
                            } else {
                                tableView.cellForRowAtIndexPath(indexPath)?.textLabel?.textColor = UIColor.redColor()
                            }
                            assert(boolVal, (error?.description)!)
                        })
                    }
                })
            }
        }
    }
    
    func authorizeHealthKit(completion: ((success:Bool, error:NSError!) -> Void)!)
    {
        healthKitStore = HKHealthStore()
        let typesSet:Set<HKSampleType> = [HKCategoryType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!, HKCategoryType.categoryTypeForIdentifier(HKCategoryTypeIdentifierOvulationTestResult)!, HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!, HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyFatPercentage)!, HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureSystolic)!, HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureDiastolic)!]
        
            healthKitStore?.requestAuthorizationToShareTypes(typesSet, readTypes: typesSet, completion: { (boolVal, error) in
                completion(success: boolVal, error: error)
        })
    }
    
    func readHKSample(sampleType:HKSampleType , completion: ((HKSample!, NSError!) -> Void)!)
    {
        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
        let limit = 1
        let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: nil, limit: limit, sortDescriptors: [sortDescriptor])
        { (sampleQuery, results, error ) -> Void in
            
            if let failureDescription = error?.description { assertionFailure(failureDescription) }
            
            let mostRecentSample = results!.first
            if completion != nil {
                completion(mostRecentSample,nil)
            }
        }
        healthKitStore!.executeQuery(sampleQuery)
    }
    
    func saveHKSamples() {
        
        let stepCountType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!
        let numSteps = HKQuantity(unit: HKUnit.countUnit(), doubleValue: 10000)
        let stepsSample = HKQuantitySample(type: stepCountType, quantity: numSteps, startDate: NSDate(), endDate: NSDate())

        let bodyFatType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyFatPercentage)!
        let bodyFatPercentage = HKQuantity(unit: HKUnit.percentUnit(), doubleValue: 0.25)
        let bodyFatSample = HKQuantitySample(type: bodyFatType, quantity: bodyFatPercentage, startDate: NSDate(), endDate: NSDate())
        
        let sleepType = HKCategoryType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!
        let sleepSample = HKCategorySample(type: sleepType, value: 1, startDate: NSDate(), endDate: NSDate())
      
        let ovulationType = HKCategoryType.categoryTypeForIdentifier(HKCategoryTypeIdentifierOvulationTestResult)!
        let ovulationSample = HKCategorySample(type: ovulationType, value: 1, startDate: NSDate(), endDate: NSDate())
        
        let diastolicBPType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureDiastolic)!
        let diastolicBP = HKQuantity(unit: HKUnit.millimeterOfMercuryUnit(), doubleValue: 80)
        let diastolicBPSample = HKQuantitySample(type: diastolicBPType, quantity: diastolicBP, startDate: NSDate(), endDate: NSDate())

        let systolicBPType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureSystolic)!
        let systolicBP = HKQuantity(unit: HKUnit.millimeterOfMercuryUnit(), doubleValue: 120)
        let systolicBPSample = HKQuantitySample(type: systolicBPType, quantity: systolicBP, startDate: NSDate(), endDate: NSDate())
        
        let bpSample = HKCorrelation(type: HKCorrelationType.correlationTypeForIdentifier(HKCorrelationTypeIdentifierBloodPressure)!, startDate: NSDate(), endDate: NSDate(), objects: [systolicBPSample, diastolicBPSample])
        
        healthKitStore?.saveObjects([stepsSample, bodyFatSample, sleepSample, ovulationSample, bpSample], withCompletion: { (success, error) in
            if success == false {
                print("Error saving Health Samples: \(error?.localizedDescription)")
            } else {
                print("Health data saved successfully!")
            }
        })
    }

    func symptomTrackerViewController(viewController: OCKSymptomTrackerViewController, didSelectRowWithAssessmentEvent assessmentEvent: OCKCarePlanEvent) {

        if viewController.progressRingTintColor == UIColor.init(red: 0.3, green: 0.2, blue: 0.9, alpha: 0.4)
        {
            if String(assessmentEvent.activity.userInfo!["Type"]!) == "Steps" {
                if (healthKitStore?.authorizationStatusForType(HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!)) == HKAuthorizationStatus.SharingAuthorized {
                    self.readHKSample(HKQuantityType.quantityTypeForIdentifier(
                        HKQuantityTypeIdentifierStepCount)!, completion: { (sample, error) in
                            let qResult = OCKCarePlanEventResult.init(quantitySample: sample as! HKQuantitySample, quantityStringFormatter: nil, unitStringKeys: [HKUnit.countUnit():"Steps Today"], userInfo: nil)
                            viewController.store.updateEvent(assessmentEvent, withResult: qResult, state: OCKCarePlanEventState.Completed, completion: { (boolVal, event, error) in
                                
                            })
                    })
                }
            } else if String(assessmentEvent.activity.userInfo!["Type"]!) == "BodyFat" {
                if (healthKitStore?.authorizationStatusForType(HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyFatPercentage)!)) == HKAuthorizationStatus.SharingAuthorized {
                    self.readHKSample(HKQuantityType.quantityTypeForIdentifier(
                        HKQuantityTypeIdentifierBodyFatPercentage)!, completion: { (sample, error) in
                            let qResult = OCKCarePlanEventResult.init(quantitySample: sample as! HKQuantitySample, quantityStringFormatter: nil, displayUnit: HKUnit.percentUnit(), displayUnitStringKey: "X100 %", userInfo: nil)
                            viewController.store.updateEvent(assessmentEvent, withResult: qResult, state: OCKCarePlanEventState.Completed, completion: { (boolVal, event, error) in
                                assert(boolVal, (error?.description)!)
                            })
                    })
                }
            } else if String(assessmentEvent.activity.userInfo!["Type"]!) == "Sleep" {
                if (healthKitStore?.authorizationStatusForType(HKCategoryType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!)) == HKAuthorizationStatus.SharingAuthorized {
                    self.readHKSample(HKCategoryType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!, completion: { (sample, error) in
                        let catResult = OCKCarePlanEventResult.init(categorySample: sample as! HKCategorySample, categoryValueStringKeys: [0 : "In Bed", 1 : "Asleep"], userInfo: nil)
                            viewController.store.updateEvent(assessmentEvent, withResult: catResult, state: OCKCarePlanEventState.Completed, completion: { (boolVal, event, error) in
                                assert(boolVal, (error?.description)!)
                            })
                    })
                }
            } else if String(assessmentEvent.activity.userInfo!["Type"]!) == "Ovulation" {
                if (healthKitStore?.authorizationStatusForType(HKCategoryType.categoryTypeForIdentifier(HKCategoryTypeIdentifierOvulationTestResult)!)) == HKAuthorizationStatus.SharingAuthorized {
                    self.readHKSample(HKCategoryType.categoryTypeForIdentifier(HKCategoryTypeIdentifierOvulationTestResult)!, completion: { (sample, error) in
                        let catResult = OCKCarePlanEventResult.init(categorySample: sample as! HKCategorySample, categoryValueStringKeys: [1 : "Negative", 2 : "Positive", 3 : "Intermediate"], userInfo: nil)
                        viewController.store.updateEvent(assessmentEvent, withResult: catResult, state: OCKCarePlanEventState.Completed, completion: { (boolVal, event, error) in
                            assert(boolVal, (error?.description)!)
                        })
                    })
                }
            } else if String(assessmentEvent.activity.userInfo!["Type"]!) == "Blood Pressure" {
                if (healthKitStore?.authorizationStatusForType(HKCorrelationType.correlationTypeForIdentifier(HKCorrelationTypeIdentifierBloodPressure)!)) == HKAuthorizationStatus.SharingAuthorized {
                    self.readHKSample(HKCorrelationType.correlationTypeForIdentifier(HKCorrelationTypeIdentifierBloodPressure)!, completion: { (sample, error) in
                        let correlationResult = OCKCarePlanEventResult.init(correlation: sample as! HKCorrelation, quantityStringFormatter: nil, displayUnit: HKUnit.millimeterOfMercuryUnit(), unitStringKeys: [HKUnit.millimeterOfMercuryUnit():"mm"], userInfo: nil)
                        viewController.store.updateEvent(assessmentEvent, withResult: correlationResult, state: OCKCarePlanEventState.Completed, completion: { (boolVal, event, error) in
                            assert(boolVal, (error?.description)!)
                        })
                    })
                }
            }
        } else {
            if assessmentEvent.state == OCKCarePlanEventState.Initial || assessmentEvent.state == OCKCarePlanEventState.NotCompleted {
                let result = OCKCarePlanEventResult.init(valueString: "Value", unitString: "200g", userInfo: nil)
                viewController.store.updateEvent(assessmentEvent, withResult: result, state: OCKCarePlanEventState.Completed) { (boolVal, carePlanEvent, error) in
                        if error != nil {
                            print("Failed "+error!.description)
                        } else {
                            print("Symptom Event Details\n")
                            print("Occurence: " + String(carePlanEvent!.occurrenceIndexOfDay))
                            print("Days Since Start: " + String(carePlanEvent!.numberOfDaysSinceStart))
                            print("Date: " + String(carePlanEvent!.date))
                            print("Activity: " + String(carePlanEvent!.activity.title))
                            print("State: " + String(carePlanEvent!.state.rawValue))
                            print("Result Value: " + String(result.valueString))
                            print("Result Unit: " + String(result.unitString))
                            print("Result Creation: " + String(result.creationDate))
                        }
                    }
            } else {
                let result = OCKCarePlanEventResult.init(valueString: "", unitString: nil, userInfo: nil)
                viewController.store.updateEvent(assessmentEvent, withResult: result, state: OCKCarePlanEventState.NotCompleted) { (boolVal, carePlanEvent, error) in
                    if error != nil {
                        print("Failed " + error!.description)
                    } else {
                        print("Symptom Event Details\n")
                        print("Occurence: " + String(carePlanEvent!.occurrenceIndexOfDay))
                        print("Days Since Start: " + String(carePlanEvent!.numberOfDaysSinceStart))
                        print("Date: " + String(carePlanEvent!.date))
                        print("Activity: " + String(carePlanEvent!.activity.title))
                        print("State: " + String(carePlanEvent!.state.rawValue))
                        print("Result Value: " + String(result.valueString))
                        print("Result Unit: " + String(result.unitString))
                        print("Result Creation: " + String(result.creationDate))
                    }
                }
            }
        }
    }
}
