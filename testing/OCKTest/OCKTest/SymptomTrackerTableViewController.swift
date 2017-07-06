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

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "cell") {
            switch (indexPath as NSIndexPath).row {
            case 0:
                cell.textLabel?.text = "No Delegate, No Edges"
            case 1:
                cell.textLabel?.text = "No Activities"
            case 2:
                cell.textLabel?.text = "With Delegate"
            case 3:
                cell.textLabel?.text = "Track Health Data"
                if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad {
                    cell.textLabel?.textColor = UIColor.gray
                    cell.isUserInteractionEnabled = false
                }
            case 4:
                cell.textLabel?.text = "Delete all Activites"
            case 5:
                cell.textLabel?.text = "Custom Image"
            default:
                cell.textLabel?.text = nil
            }
            return cell
        } else {
            return UITableViewCell.init()
        }
        
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        
        if (indexPath as NSIndexPath).row == 0 {
            
            // No Delegate, No Edges
            var startDateComponents = DateComponents.init()
            startDateComponents.day = 20
            startDateComponents.month = 3
            startDateComponents.year = 2000
            let schedule = OCKCareSchedule.dailySchedule(withStartDate: startDateComponents, occurrencesPerDay: 1)
            let firstGroupId = "Group A1"
            let carePlanActivity1 = OCKCarePlanActivity.init(identifier: "Assessment Activity #1", groupIdentifier: firstGroupId, type: OCKCarePlanActivityType.assessment, title: "Assessment Activity Title 1", text: "Read the instructions about this task", tintColor: UIColor.red, instructions: "Perform the described task and report the results. Talk to your doctor if you need help", imageURL: nil, schedule: schedule, resultResettable: true, userInfo: nil)

            let carePlanActivity2 = OCKCarePlanActivity.init(identifier: "Assessment Activity #2", groupIdentifier: firstGroupId, type: OCKCarePlanActivityType.assessment, title: "Assessment Activity Title 2", text: "Complete this activity ASAP", tintColor: UIColor.orange, instructions: nil, imageURL: nil, schedule: schedule, resultResettable: true, userInfo: nil)

            let carePlanStore = OCKCarePlanStore.init(persistenceDirectoryURL: URL.init(string: documentsDirectory[0])!)
            carePlanStore .add(carePlanActivity1, completion: { (boolVal, error) in
                assert(boolVal, (error?.localizedDescription)!)
            })
            carePlanStore .add(carePlanActivity2, completion: { (boolVal, error) in
                assert(boolVal, (error?.localizedDescription)!)
            })
            let symptomTracker = OCKSymptomTrackerViewController.init(carePlanStore: carePlanStore)
            self.navigationController?.pushViewController(symptomTracker, animated: true)
            
        } else if (indexPath as NSIndexPath).row == 1 {
            
            // No Activities

            let dataPath = documentsDirectory[0] + "/EmptyAssessmentPlan"
            if !FileManager.default.fileExists(atPath: dataPath) {
                do {
                    try FileManager.default.createDirectory(atPath: dataPath, withIntermediateDirectories: false, attributes: nil)
                } catch(_) {
                    assertionFailure("Unable to Create Directory for EmptyAssessmentPlan")
                }
            }
            
            let carePlanStore = OCKCarePlanStore.init(persistenceDirectoryURL: URL.init(string: dataPath)!)

            let symptomTracker = OCKSymptomTrackerViewController.init(carePlanStore: carePlanStore)
            self.navigationController?.pushViewController(symptomTracker, animated: true)
       
        } else if (indexPath as NSIndexPath).row == 2 {
            
            // With Delegate
            
            var startDateComponents = DateComponents.init()
            startDateComponents.day = 20
            startDateComponents.month = 3
            startDateComponents.year = 0010
            
            let endDate = Date().addingTimeInterval(-86400.0)
            let endDateComponents = NSCalendar.current.dateComponents([.day, .month, .year], from: endDate)
            
            let schedule1 = OCKCareSchedule.weeklySchedule(withStartDate: startDateComponents, occurrencesOnEachDay: [1, 2, 3, 4, 5, 6, 7], weeksToSkip: 0, endDate: endDateComponents)
            let schedule2 = OCKCareSchedule.dailySchedule(withStartDate: startDateComponents, occurrencesPerDay: 1, daysToSkip: 0, endDate: nil)
            let secondGroupId = "Group A2"
            let carePlanActivity1 = OCKCarePlanActivity.init(identifier: "Assessment Activity #1", groupIdentifier: secondGroupId, type: OCKCarePlanActivityType.assessment, title: "Activity that ended yesterday ", text: "Read the instructions about this task", tintColor: nil, instructions: "Perform the described task and report the results. Talk to your doctor if you need help", imageURL: nil, schedule: schedule1, resultResettable: false, userInfo: nil)
            
            let carePlanActivity2 = OCKCarePlanActivity.assessment(withIdentifier: "Assessment Activity #2", groupIdentifier: secondGroupId, title: "A Daily Activity is one that repeats every day", text: "This is an assessment. Be careful. You are being evaluated every single day.", tintColor: UIColor.purple, resultResettable: false, schedule: schedule2, userInfo: nil, thresholds:nil, optional:false)
            
            let dataPath = documentsDirectory[0] + "/CarePlan2"
            if !FileManager.default.fileExists(atPath: dataPath) {
                do {
                    try FileManager.default.createDirectory(atPath: dataPath, withIntermediateDirectories: false, attributes: nil)
                } catch(_) {
                    assertionFailure("Unable to Create Directory for CarePlan2")
                }
            }
    
            let carePlanStore = OCKCarePlanStore.init(persistenceDirectoryURL: URL.init(string: dataPath)!)
            carePlanStore.add(carePlanActivity1, completion: { (boolVal, error) in
                assert(boolVal, (error?.localizedDescription)!)
            })
            carePlanStore.add(carePlanActivity2, completion: { (boolVal, error) in
                assert(boolVal, (error?.localizedDescription)!)
            })
            
            let symptomTracker = OCKSymptomTrackerViewController.init(carePlanStore: carePlanStore)
            symptomTracker.glyphTintColor = UIColor.magenta
            symptomTracker.delegate = self
            self.navigationController?.pushViewController(symptomTracker, animated: true)
     
        } else if (indexPath as NSIndexPath).row == 3 {
            
            // Track Health Data
            self.authorizeHealthKit(completion: { (success, error) in
                assert(success, (error?.localizedDescription)!)
                DispatchQueue.main.async {
                    self.saveHKSamples()
                }
            })
            
            let startDateComponents = DateComponents.init(year: 1, month: 1, day: 1)
            let schedule = OCKCareSchedule.weeklySchedule(withStartDate: startDateComponents, occurrencesOnEachDay: [1, 1, 1, 1, 1, 1, 1])
            
            let dataPath = documentsDirectory[0] + "/CarePlanHealth"
            if !FileManager.default.fileExists(atPath: dataPath) {
                do {
                    try FileManager.default.createDirectory(atPath: dataPath, withIntermediateDirectories: false, attributes: nil)
                } catch(_) {
                    assertionFailure("Unable to Create Directory for CarePlanHealth")
                }
            }
            
            let carePlanStore = OCKCarePlanStore.init(persistenceDirectoryURL: URL.init(string: dataPath)!)
            let thirdGroupId = "Group A3"
            let carePlanActivity1 = OCKCarePlanActivity.assessment(withIdentifier: "Step Count", groupIdentifier: thirdGroupId, title: "Step Count", text: "Get steps from Health app", tintColor: UIColor.init(red: 0.3, green: 0.2, blue: 0.9, alpha: 0.4), resultResettable: true, schedule: schedule, userInfo: ["Type":"Steps"], thresholds:nil, optional:false)
            carePlanStore.add(carePlanActivity1, completion: { (boolVal, error) in
                assert(boolVal, (error?.localizedDescription)!)
            })
            let carePlanActivity2 = OCKCarePlanActivity.assessment(withIdentifier: "Body Fat", groupIdentifier: thirdGroupId, title: "Body Fat", text: "Get Body Fat from Health app", tintColor: UIColor.init(red: 0.3, green: 0.2, blue: 0.9, alpha: 0.4), resultResettable: true, schedule: schedule, userInfo:  ["Type":"BodyFat"], thresholds:nil, optional:false)
            carePlanStore.add(carePlanActivity2, completion: { (boolVal, error) in
                assert(boolVal, (error?.localizedDescription)!)
            })
            let carePlanActivity3 = OCKCarePlanActivity.assessment(withIdentifier: "Sleep Analysis", groupIdentifier: thirdGroupId, title: "Sleep Analysis", text: "Get Sleep Data from Health app", tintColor: UIColor.init(red: 0.3, green: 0.2, blue: 0.9, alpha: 0.4), resultResettable: true, schedule: schedule, userInfo: ["Type":"Sleep"], thresholds:nil, optional:false)
            carePlanStore.add(carePlanActivity3, completion: { (boolVal, error) in
                assert(boolVal, (error?.localizedDescription)!)
            })
            let carePlanActivity4 = OCKCarePlanActivity.assessment(withIdentifier: "Ovulation", groupIdentifier: thirdGroupId, title: "Ovulation", text: "Get Ovulation Data from Health app", tintColor: UIColor.init(red: 0.3, green: 0.2, blue: 0.9, alpha: 0.4), resultResettable: true, schedule: schedule, userInfo: ["Type":"Ovulation"], thresholds:nil, optional:false)
            carePlanStore.add(carePlanActivity4, completion: { (boolVal, error) in
                assert(boolVal, (error?.localizedDescription)!)
            })
            
            let carePlanActivity5 = OCKCarePlanActivity.assessment(withIdentifier: "Blood Pressure", groupIdentifier: thirdGroupId, title: "Blood Pressure", text: "Get Blood Pressure from Health app", tintColor: UIColor.init(red: 0.3, green: 0.2, blue: 0.9, alpha: 0.4), resultResettable: true, schedule: schedule, userInfo: ["Type":"Blood Pressure"], thresholds:nil, optional:false)
            carePlanStore.add(carePlanActivity5, completion: { (boolVal, error) in
                assert(boolVal, (error?.localizedDescription)!)
            })
            
            let symptomTracker = OCKSymptomTrackerViewController.init(carePlanStore: carePlanStore)
            symptomTracker.delegate = self
            symptomTracker.glyphTintColor = UIColor.init(red: 0.3, green: 0.2, blue: 0.9, alpha: 0.4)
            self.navigationController?.pushViewController(symptomTracker, animated: true)

        } else if (indexPath as NSIndexPath).row == 4 {
            
            // Delete all Activites
            
            tableView.cellForRow(at: indexPath)?.isSelected = false
            let store = OCKCarePlanStore.init(persistenceDirectoryURL: URL.init(string: documentsDirectory[0])!)
            
            store.activities(withGroupIdentifier: "Group A1", completion: { (boolVal, activities, error) in
                for activity:OCKCarePlanActivity in activities
                {
                    store.remove(activity, completion: { (boolVal, error) in
                        if boolVal == true {
                            tableView.cellForRow(at: indexPath)?.textLabel?.textColor = UIColor.green
                        } else {
                            tableView.cellForRow(at: indexPath)?.textLabel?.textColor = UIColor.red
                        }
                        assert(boolVal, (error?.localizedDescription)!)
                    })
                }
            })
            
            if FileManager.default.fileExists(atPath: documentsDirectory[0] + "/CarePlan2") {
                let dataPath = URL.init(string:documentsDirectory[0] + "/CarePlan2")
                let store2 = OCKCarePlanStore.init(persistenceDirectoryURL: dataPath!)
                store2.activities(withGroupIdentifier: "Group A2", completion: { (boolVal, activities, error) in
                    for activity:OCKCarePlanActivity in activities
                    {
                        store2.remove(activity, completion: { (boolVal, error) in
                            if boolVal == true {
                                tableView.cellForRow(at: indexPath)?.textLabel?.textColor = UIColor.green
                            } else {
                                tableView.cellForRow(at: indexPath)?.textLabel?.textColor = UIColor.red
                            }
                            assert(boolVal, (error?.localizedDescription)!)
                        })
                    }
                })
            }
            
            if FileManager.default.fileExists(atPath: documentsDirectory[0] + "/CarePlanHealth") {
                let dataPath = URL.init(string:documentsDirectory[0] + "/CarePlanHealth")
                let store3 = OCKCarePlanStore.init(persistenceDirectoryURL:dataPath!)
                store3.activities(withGroupIdentifier: "Group A3", completion: { (boolVal, activities, error) in
                    for activity:OCKCarePlanActivity in activities
                    {
                        store3.remove(activity, completion: { (boolVal, error) in
                            if boolVal == true {
                                tableView.cellForRow(at: indexPath)?.textLabel?.textColor = UIColor.green
                            } else {
                                tableView.cellForRow(at: indexPath)?.textLabel?.textColor = UIColor.red
                            }
                            assert(boolVal, (error?.localizedDescription)!)
                        })
                    }
                })
            }
        } else if (indexPath as NSIndexPath).row == 5 {            
            let carePlanStore = OCKCarePlanStore.init(persistenceDirectoryURL: URL.init(string: documentsDirectory[0])!)
           
            let symptomTracker = OCKSymptomTrackerViewController.init(carePlanStore: carePlanStore)
            symptomTracker.glyphType = .infantCare
            symptomTracker.glyphTintColor = UIColor.yellow
            self.navigationController?.pushViewController(symptomTracker, animated: true)
        }
    }
    
    func authorizeHealthKit(completion: ((_ success:Bool, _ error:Error?) -> Void)!) {
        healthKitStore = HKHealthStore()
        let typesSet : Set<HKSampleType> = [HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!, HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier.ovulationTestResult)!, HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!, HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyFatPercentage)!, HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureSystolic)!, HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureDiastolic)!]
        
        healthKitStore?.requestAuthorization(toShare: typesSet, read: typesSet, completion: completion)
    }
    
    func readHKSample(_ sampleType:HKSampleType , completion: ((HKSample?, Error?) -> Void)!) {
        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
        let limit = 1
        let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: nil, limit: limit, sortDescriptors: [sortDescriptor])
        { (sampleQuery, results, error ) -> Void in
            
            if let failureDescription = error?.localizedDescription { assertionFailure(failureDescription) }
            
            let mostRecentSample = results!.first
            if completion != nil {
                completion(mostRecentSample,nil)
            }
        }
        healthKitStore!.execute(sampleQuery)
    }
    
    func saveHKSamples() {
        
        let stepCountType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        let numSteps = HKQuantity(unit: HKUnit.count(), doubleValue: 10000)
        let stepsSample = HKQuantitySample(type: stepCountType, quantity: numSteps, start: Date(), end: Date())

        let bodyFatType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyFatPercentage)!
        let bodyFatPercentage = HKQuantity(unit: HKUnit.percent(), doubleValue: 0.25)
        let bodyFatSample = HKQuantitySample(type: bodyFatType, quantity: bodyFatPercentage, start: Date(), end: Date())
        
        let sleepType = HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!
        let sleepSample = HKCategorySample(type: sleepType, value: 1, start: Date(), end: Date())
      
        let ovulationType = HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier.ovulationTestResult)!
        let ovulationSample = HKCategorySample(type: ovulationType, value: 1, start: Date(), end: Date())
        
        let diastolicBPType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureDiastolic)!
        let diastolicBP = HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: 80)
        let diastolicBPSample = HKQuantitySample(type: diastolicBPType, quantity: diastolicBP, start: Date(), end: Date())

        let systolicBPType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureSystolic)!
        let systolicBP = HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: 120)
        let systolicBPSample = HKQuantitySample(type: systolicBPType, quantity: systolicBP, start: Date(), end: Date())
        
        let bpSample = HKCorrelation(type: HKCorrelationType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.bloodPressure)!, start: Date(), end: Date(), objects: [systolicBPSample, diastolicBPSample])
        
        healthKitStore?.save([stepsSample, bodyFatSample, sleepSample, ovulationSample, bpSample], withCompletion: { (success, error) in
            if success == false {
                print("Error saving Health Samples: \(error?.localizedDescription ?? "")")
            } else {
                print("Health data saved successfully!")
            }
        })
    }

    func symptomTrackerViewController(_ viewController: OCKSymptomTrackerViewController, didSelectRowWithAssessmentEvent assessmentEvent: OCKCarePlanEvent) {

        if viewController.glyphTintColor == UIColor.init(red: 0.3, green: 0.2, blue: 0.9, alpha: 0.4)
        {
            if String(describing: assessmentEvent.activity.userInfo!["Type"]!) == "Steps" {
                if (healthKitStore?.authorizationStatus(for: HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!)) == HKAuthorizationStatus.sharingAuthorized {
                    self.readHKSample(HKQuantityType.quantityType(
                        forIdentifier: HKQuantityTypeIdentifier.stepCount)!, completion: { (sample, error) in
                            let qResult = OCKCarePlanEventResult.init(quantitySample: sample as! HKQuantitySample, quantityStringFormatter: nil, unitStringKeys: [HKUnit.count():"Steps Today"], userInfo: nil)
                            viewController.store.update(assessmentEvent, with: qResult, state: OCKCarePlanEventState.completed, completion: { (boolVal, event, error) in
                                
                            })
                    })
                }
            } else if String(describing: assessmentEvent.activity.userInfo!["Type"]!) == "BodyFat" {
                if (healthKitStore?.authorizationStatus(for: HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyFatPercentage)!)) == HKAuthorizationStatus.sharingAuthorized {
                    self.readHKSample(HKQuantityType.quantityType(
                        forIdentifier: HKQuantityTypeIdentifier.bodyFatPercentage)!, completion: { (sample, error) in
                            let qResult = OCKCarePlanEventResult.init(quantitySample: sample as! HKQuantitySample, quantityStringFormatter: nil, display: HKUnit.percent(), displayUnitStringKey: "X100 %", userInfo: nil)
                            viewController.store.update(assessmentEvent, with: qResult, state: OCKCarePlanEventState.completed, completion: { (boolVal, event, error) in
                                assert(boolVal, (error?.localizedDescription)!)
                            })
                    })
                }
            } else if String(describing: assessmentEvent.activity.userInfo!["Type"]!) == "Sleep" {
                if (healthKitStore?.authorizationStatus(for: HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!)) == HKAuthorizationStatus.sharingAuthorized {
                    self.readHKSample(HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!, completion: { (sample, error) in
                        let catResult = OCKCarePlanEventResult.init(categorySample: sample as! HKCategorySample, categoryValueStringKeys: [0 : "In Bed", 1 : "Asleep"], userInfo: nil)
                            viewController.store.update(assessmentEvent, with: catResult, state: OCKCarePlanEventState.completed, completion: { (boolVal, event, error) in
                                assert(boolVal, (error?.localizedDescription)!)
                            })
                    })
                }
            } else if String(describing: assessmentEvent.activity.userInfo!["Type"]!) == "Ovulation" {
                if (healthKitStore?.authorizationStatus(for: HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier.ovulationTestResult)!)) == HKAuthorizationStatus.sharingAuthorized {
                    self.readHKSample(HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier.ovulationTestResult)!, completion: { (sample, error) in
                        let catResult = OCKCarePlanEventResult.init(categorySample: sample as! HKCategorySample, categoryValueStringKeys: [1 : "Negative", 2 : "Positive", 3 : "Intermediate"], userInfo: nil)
                        viewController.store.update(assessmentEvent, with: catResult, state: OCKCarePlanEventState.completed, completion: { (boolVal, event, error) in
                            assert(boolVal, (error?.localizedDescription)!)
                        })
                    })
                }
            } else if String(describing: assessmentEvent.activity.userInfo!["Type"]!) == "Blood Pressure" {
                if (healthKitStore?.authorizationStatus(for: HKCorrelationType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.bloodPressure)!)) == HKAuthorizationStatus.sharingAuthorized {
                    self.readHKSample(HKCorrelationType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.bloodPressure)!, completion: { (sample, error) in
                        let correlationResult = OCKCarePlanEventResult.init(correlation: sample as! HKCorrelation, quantityStringFormatter: nil, display: HKUnit.millimeterOfMercury(), unitStringKeys: [HKUnit.millimeterOfMercury():"mmHg"], userInfo: nil)
                        viewController.store.update(assessmentEvent, with: correlationResult, state: OCKCarePlanEventState.completed, completion: { (boolVal, event, error) in
                            assert(boolVal, (error?.localizedDescription)!)
                        })
                    })
                }
            }
        } else {
            if assessmentEvent.state == OCKCarePlanEventState.initial || assessmentEvent.state == OCKCarePlanEventState.notCompleted {
                let result = OCKCarePlanEventResult.init(valueString: "Value", unitString: "200g", userInfo: nil)
                viewController.store.update(assessmentEvent, with: result, state: OCKCarePlanEventState.completed) { (boolVal, carePlanEvent, error) in
                        if error != nil {
                            print("Failed "+error!.localizedDescription)
                        } else {
                            print("Symptom Event Details\n")
                            print("Occurence: " + String(carePlanEvent!.occurrenceIndexOfDay))
                            print("Days Since Start: " + String(carePlanEvent!.numberOfDaysSinceStart))
                            print("Date: " + String(describing: carePlanEvent!.date))
                            print("Activity: " + String(carePlanEvent!.activity.title))
                            print("State: " + String(carePlanEvent!.state.rawValue))
                            print("Result Value: " + String(result.valueString))
                            print("Result Unit: " + String(describing: result.unitString))
                            print("Result Creation: " + String(describing: result.creationDate))
                        }
                    }
            } else {
                let result = OCKCarePlanEventResult.init(valueString: "", unitString: nil, userInfo: nil)
                viewController.store.update(assessmentEvent, with: result, state: OCKCarePlanEventState.notCompleted) { (boolVal, carePlanEvent, error) in
                    if error != nil {
                        print("Failed " + error!.localizedDescription)
                    } else {
                        print("Symptom Event Details\n")
                        print("Occurence: " + String(carePlanEvent!.occurrenceIndexOfDay))
                        print("Days Since Start: " + String(carePlanEvent!.numberOfDaysSinceStart))
                        print("Date: " + String(describing: carePlanEvent!.date))
                        print("Activity: " + String(carePlanEvent!.activity.title))
                        print("State: " + String(carePlanEvent!.state.rawValue))
                        print("Result Value: " + String(result.valueString))
                        print("Result Unit: " + String(describing: result.unitString))
                        print("Result Creation: " + String(describing: result.creationDate))
                    }
                }
            }
        }
    }
}
