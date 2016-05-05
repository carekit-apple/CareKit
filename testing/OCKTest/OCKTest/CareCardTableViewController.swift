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


class CareCardTableViewController: UITableViewController, OCKCarePlanStoreDelegate, OCKCareCardViewControllerDelegate {

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 8
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("cell") {
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Many Activities, Many Schedules"
            case 1:
                cell.textLabel?.text = "With Delegate & Images"
            case 2:
                cell.textLabel?.text = "No Activities"
            case 3:
                cell.textLabel?.text = "Auto-Complete, No Edges"
            case 4:
                cell.textLabel?.text = "Activities don't complete"
            case 5:
                cell.textLabel?.text = "Custom Details (Run 'With Delegate' first)"
            case 6:
                cell.textLabel?.text = "Save an Image"
            case 7:
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
            
            // Many Activities, Many Schedules
          
            let startDateComponents = NSDateComponents.init()
            startDateComponents.day = 20
            startDateComponents.month = 2
            startDateComponents.year = 2015
            
            let dailySchedule:OCKCareSchedule = OCKCareSchedule.dailyScheduleWithStartDate(startDateComponents, occurrencesPerDay: 2)
            let weeklySchedule = OCKCareSchedule.weeklyScheduleWithStartDate(startDateComponents, occurrencesOnEachDay:[4, 0, 4, 0, 4, 0, 4])
            let alternateWeeklySchedule = OCKCareSchedule.weeklyScheduleWithStartDate(startDateComponents, occurrencesOnEachDay: [0, 1, 0, 0, 0, 0, 0], weeksToSkip: 1, endDate: nil)
            let skipDaysSchedule = OCKCareSchedule.dailyScheduleWithStartDate(startDateComponents, occurrencesPerDay: 5, daysToSkip: 2, endDate: nil)
            
            var carePlanActivities = [OCKCarePlanActivity]()
            let firstGroupId = "Group I1"
            carePlanActivities.append(OCKCarePlanActivity.init(identifier: "Intervention Activity #1", groupIdentifier: firstGroupId, type: OCKCarePlanActivityType.Intervention, title: "Daily Intervention Activity Title 1", text: "Read the instructions about this task", tintColor: nil, instructions: "Perform the described task and report the results. Talk to your doctor if you need help", imageURL: nil, schedule: dailySchedule, resultResettable: true, userInfo: ["Key1":"Value1","Key2":"Value2"]))
            
            carePlanActivities.append(OCKCarePlanActivity.init(identifier: "Intervention Activity #2", groupIdentifier: firstGroupId, type: OCKCarePlanActivityType.Intervention, title: "Alternate-Day Intervention Activity Title 2", text: "Complete this activity ASAP. No Instructions!", tintColor: UIColor.brownColor(), instructions: nil, imageURL: nil, schedule: weeklySchedule, resultResettable: true, userInfo: ["Key1":"Value1", "Key2":"Value2"]))
            
            carePlanActivities.append(OCKCarePlanActivity.init(identifier: "Intervention Activity 3", groupIdentifier: firstGroupId, type: OCKCarePlanActivityType.Intervention, title: "Repeats Every Three Days", text: "This is a long line of text. It describes the Activity in detail", tintColor: UIColor.redColor(), instructions: LoremIpsum, imageURL: nil, schedule: skipDaysSchedule, resultResettable: false, userInfo:nil))
            
            carePlanActivities.append(OCKCarePlanActivity.init(identifier: "Intervention Activity #4", groupIdentifier: firstGroupId, type: OCKCarePlanActivityType.Intervention, title: "Every other-Monday", text: "I am activity #4", tintColor: UIColor.greenColor(), instructions: nil, imageURL: nil, schedule: alternateWeeklySchedule, resultResettable: false, userInfo: nil))
            
            carePlanActivities.append(OCKCarePlanActivity.init(identifier: "Intervention Activity #5", groupIdentifier: firstGroupId, type: OCKCarePlanActivityType.Intervention, title: "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa.", text: "This is the text", tintColor: nil, instructions: "Take pain medication", imageURL: nil, schedule: dailySchedule, resultResettable: false, userInfo: nil))
            
            let activity6 = OCKCarePlanActivity.init(identifier: "Intervention Activity #6", groupIdentifier: firstGroupId, type: OCKCarePlanActivityType.Intervention, title: "Activity Ended Yesterday", text: LoremIpsum, tintColor: UIColor.grayColor(), instructions: LoremIpsum, imageURL: nil, schedule: dailySchedule, resultResettable: true, userInfo: nil)
            carePlanActivities.append(activity6)
            
            carePlanActivities.append(OCKCarePlanActivity.interventionWithIdentifier("Intervention Activity #7", groupIdentifier: nil, title: "No Group, No Text Activity", text: nil, tintColor: nil, instructions: nil, imageURL: nil, schedule: dailySchedule, userInfo: nil))
            
            carePlanActivities.append(OCKCarePlanActivity.interventionWithIdentifier("Intervention Activity #8", groupIdentifier: nil, title: "", text: "Missing Title", tintColor: UIColor.purpleColor(), instructions: "Some Instructions", imageURL: nil, schedule: dailySchedule, userInfo: ["":""]))
            
            let carePlanStore = OCKCarePlanStore.init(persistenceDirectoryURL: NSURL.init(string: documentsDirectory[0])!)
            
            for carePlanActivity in carePlanActivities {
                carePlanStore.addActivity(carePlanActivity, completion: { (boolVal, error) in
                    assert(boolVal, (error?.description)!)
                })
            }
            
            carePlanStore.setEndDate(NSDateComponents.init(date: NSDate().dateByAddingTimeInterval(-86400.0), calendar: NSCalendar.currentCalendar()), forActivity: activity6, completion: { (boolVal, activity, error) in
                
            })

            let careCardController = OCKCareCardViewController.init(carePlanStore: carePlanStore)
            careCardController.showEdgeIndicators = true
            self.navigationController?.pushViewController(careCardController, animated: true)
            
        } else if indexPath.row == 1 {
            
            // With Delegate & Images
            
            let dateComponents = NSDateComponents.init(year: 2015, month: 2, day: 20)
            let schedule = OCKCareSchedule.dailyScheduleWithStartDate(dateComponents, occurrencesPerDay: 6)
            
            let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
            let imageFileURL = documentsURL.URLByAppendingPathComponent("Triangles.jpg")
            let secondGroupId = "Group I2"
            
            let carePlanActivity1 = OCKCarePlanActivity.init(identifier: "Intervention Activity 1", groupIdentifier: secondGroupId, type: OCKCarePlanActivityType.Intervention, title: "1. This is the first Intervention Activity", text: "", tintColor: UIColor.redColor(), instructions: "No instructions required", imageURL: imageFileURL, schedule: schedule, resultResettable: true, userInfo: ["Key1":"Value1","Key2":"Value2"])
            
            let carePlanActivity2 = OCKCarePlanActivity.init(identifier: "Intervention Activity 2", groupIdentifier: secondGroupId, type: OCKCarePlanActivityType.Intervention, title: "2. Another Intervention Activity", text: "Complete this activity ASAP. No Instructions!", tintColor: nil, instructions: nil, imageURL: imageFileURL, schedule: schedule, resultResettable: true, userInfo: nil)
            
            let carePlanActivity3 = OCKCarePlanActivity.interventionWithIdentifier("Intervention Activity 3", groupIdentifier: secondGroupId, title: "3. Activity #3 is the last one", text: "Some Text", tintColor: UIColor.purpleColor(), instructions: "Some Instructions", imageURL: imageFileURL, schedule: schedule, userInfo: ["Key":"Val"])
            
            let dataPath = documentsDirectory[0].stringByAppendingString("/CarePlan2")
            if !NSFileManager.defaultManager().fileExistsAtPath(dataPath) {
                do {
                    try NSFileManager.defaultManager().createDirectoryAtPath(dataPath, withIntermediateDirectories: false, attributes: nil)
                } catch(_) {
                    assertionFailure("Unable to Create Directory for CarePlan2")
                }
            }
            
            let carePlanStore = OCKCarePlanStore.init(persistenceDirectoryURL: NSURL.init(string: dataPath)!)
            carePlanStore.delegate = self
            carePlanStore.addActivity(carePlanActivity1, completion: { (boolVal, error) in
                assert(boolVal, (error?.description)!)
            })
            carePlanStore.addActivity(carePlanActivity2, completion: { (boolVal, error) in
                assert(boolVal, (error?.description)!)
            })
            carePlanStore.addActivity(carePlanActivity3, completion: { (boolVal, error) in
                assert(boolVal, (error?.description)!)
                
            })
            
            let careCardController = OCKCareCardViewController.init(carePlanStore: carePlanStore)
            careCardController.maskImage = UIImage.init(named: "Stars")
            careCardController.smallMaskImage = UIImage.init(named: "Triangles.jpg")
            careCardController.maskImageTintColor = UIColor.cyanColor()
            careCardController.showEdgeIndicators = true
            self.navigationController?.pushViewController(careCardController, animated: true)
            
        } else if indexPath.row == 2 {
            
            // No Activities
            
            let dataPath = documentsDirectory[0].stringByAppendingString("/EmptyCarePlan")
            if !NSFileManager.defaultManager().fileExistsAtPath(dataPath) {
                do {
                    try NSFileManager.defaultManager().createDirectoryAtPath(dataPath, withIntermediateDirectories: false, attributes: nil)
                } catch(_) {
                    assertionFailure("Unable to Create Directory for EmptyCarePlan")
                }
            }
            
            let carePlanStore = OCKCarePlanStore.init(persistenceDirectoryURL: NSURL.init(string: dataPath)!)
            let careCardController = OCKCareCardViewController.init(carePlanStore: carePlanStore)
            careCardController.maskImageTintColor = UIColor.orangeColor()
            self.navigationController?.pushViewController(careCardController, animated: true)
      
        } else if indexPath.row == 3 {
            
            // Auto-Complete, No Edges
            
            let startDateComponents = NSDateComponents.init(year: 2012, month: 12, day: 12)
            let endDateComponents = NSDateComponents.init(year: 3000, month: 03, day: 30)
            let schedule = OCKCareSchedule.dailyScheduleWithStartDate(startDateComponents, occurrencesPerDay: 5, daysToSkip: 0, endDate: endDateComponents)
            
            let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
            let imageFileURL = documentsURL.URLByAppendingPathComponent("Triangles.jpg")
            
            let dataPath = documentsDirectory[0].stringByAppendingString("/CarePlanAuto")
            if !NSFileManager.defaultManager().fileExistsAtPath(dataPath) {
                do {
                    try NSFileManager.defaultManager().createDirectoryAtPath(dataPath, withIntermediateDirectories: false, attributes: nil)
                } catch(_) {
                    assertionFailure("Unable to Create Directory for CarePlanAuto")
                }
            }
            
            let carePlanStore = OCKCarePlanStore.init(persistenceDirectoryURL: NSURL.init(string: dataPath)!)
            
            for index in 1...30 {
                let carePlanActivity = OCKCarePlanActivity.init(identifier: "Intervention Activity" + String(index), groupIdentifier: "Group I2", type: OCKCarePlanActivityType.Intervention, title: "Activity Title"+String(index), text: "Text Text Text" + String(index), tintColor: UIColor.init(red: 0.2, green: 0.4, blue: 0.9, alpha: 0.4), instructions: "This is a set of instructions for activity #" + String(index), imageURL: imageFileURL, schedule: schedule, resultResettable: true, userInfo: nil)
                carePlanStore.addActivity(carePlanActivity, completion: { (boolVal, error) in
                    assert(boolVal, (error?.description)!)
                })
            }

            carePlanStore.eventsOnDate(NSDateComponents.init(date: NSDate(), calendar: NSCalendar.currentCalendar()), type: OCKCarePlanActivityType.Intervention, completion: { (allEventsArray, error) in
                for activityEvents in allEventsArray {
                    for event in activityEvents {
                            carePlanStore.updateEvent(event, withResult: nil, state: OCKCarePlanEventState.Completed, completion: { (boolVal, event, error) in
                        })
                    }
                }
            })

            
            let careCardController = OCKCareCardViewController.init(carePlanStore: carePlanStore)
            careCardController.maskImageTintColor = UIColor.init(red: 0.2, green: 0.4, blue: 0.9, alpha: 0.4)
            self.navigationController?.pushViewController(careCardController, animated: true)
            
        } else if indexPath.row == 4 {
            
            // Activities don't complete

            let dateComponents = NSDateComponents.init(year: 2015, month: 2, day: 20)
            let schedule = OCKCareSchedule.dailyScheduleWithStartDate(dateComponents, occurrencesPerDay: 14)
            let fourthGroupId = "Group I4"
            let carePlanActivity1 = OCKCarePlanActivity.init(identifier: "ActivityDoesntComplete1", groupIdentifier: fourthGroupId, type: OCKCarePlanActivityType.Intervention, title: "Does not Complete", text: "Tint color changes on tap", tintColor: UIColor.blueColor(), instructions: "No instructions required", imageURL: nil, schedule: schedule, resultResettable: true, userInfo:nil)
            let carePlanActivity2 = OCKCarePlanActivity.init(identifier: "ActivityDoesntComplete2", groupIdentifier: fourthGroupId, type: OCKCarePlanActivityType.Intervention, title: "Does not Complete", text: "Tint color changes on tap", tintColor: UIColor.purpleColor(), instructions: "", imageURL: nil, schedule: schedule, resultResettable: true, userInfo:nil)
            
            let dataPath = documentsDirectory[0].stringByAppendingString("/CarePlanIncomplete")
            
            if !NSFileManager.defaultManager().fileExistsAtPath(dataPath) {
                do {
                    try NSFileManager.defaultManager().createDirectoryAtPath(dataPath, withIntermediateDirectories: false, attributes: nil)
                } catch(_) {
                    assertionFailure("Unable to Create Directory for CarePlanIncomplete")
                }
            }
            
            let carePlanStore = OCKCarePlanStore.init(persistenceDirectoryURL: NSURL.init(string: dataPath)!)
            carePlanStore.delegate = self
            carePlanStore.addActivity(carePlanActivity1, completion: { (boolVal, error) in
                assert(boolVal, (error?.description)!)
            })
            carePlanStore.addActivity(carePlanActivity2, completion: { (boolVal, error) in
                assert(boolVal, (error?.description)!)
            })

            let careCardController = OCKCareCardViewController.init(carePlanStore: carePlanStore)
            careCardController.delegate = self
            careCardController.smallMaskImage = UIImage.init(named: "Stars")
            careCardController.showEdgeIndicators = true
            self.navigationController?.pushViewController(careCardController, animated: true)
            
        }  else if indexPath.row == 5 {
            
            // Custom Details for Activities

            let dataPath = documentsDirectory[0].stringByAppendingString("/CarePlan2")
            if !NSFileManager.defaultManager().fileExistsAtPath(dataPath) {
                return
            }
            let carePlanStore = OCKCarePlanStore.init(persistenceDirectoryURL: NSURL.init(string: dataPath)!)
            let careCardController = OCKCareCardViewController.init(carePlanStore: carePlanStore)
            careCardController.delegate = self
            careCardController.showEdgeIndicators = true
            self.navigationController?.pushViewController(careCardController, animated: true)
            
        } else if indexPath.row == 6 {
            
            // Save an Image
            
            let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
            if let image = UIImage.init(named: "Triangles.jpg") {
                let imageFileURL = documentsURL.URLByAppendingPathComponent("Triangles.jpg")
                if let jpgImageData = UIImageJPEGRepresentation(image,0.5) {
                    jpgImageData.writeToURL(imageFileURL, atomically: false)
                }
            }
            tableView.cellForRowAtIndexPath(indexPath)?.textLabel?.textColor = UIColor.greenColor()
            tableView.cellForRowAtIndexPath(indexPath)?.selected = false
            
        } else if indexPath.row == 7 {
            
            // Delete all Activites
            
            tableView.cellForRowAtIndexPath(indexPath)?.selected = false
            
            let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
            let store = OCKCarePlanStore.init(persistenceDirectoryURL: NSURL.init(string: paths[0])!)
            store.activitiesWithType(OCKCarePlanActivityType.Intervention, completion: { (boolVal, activities, error) in
                for activity:OCKCarePlanActivity in activities {
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
        
            
            if NSFileManager.defaultManager().fileExistsAtPath(paths[0].stringByAppendingString("/CarePlan2")) {
                let dataPath = NSURL.init(string:paths[0].stringByAppendingString("/CarePlan2"))
                let store2 = OCKCarePlanStore.init(persistenceDirectoryURL: dataPath!)
                store2.activitiesWithGroupIdentifier("Group I2", completion: { (boolVal, activities, error) in
                    for activity:OCKCarePlanActivity in activities {
                        store2.removeActivity(activity, completion: { (bool, error) in
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
            
            if NSFileManager.defaultManager().fileExistsAtPath(paths[0].stringByAppendingString("/CarePlanAuto")) {
                let dataPath = NSURL.init(string:paths[0].stringByAppendingString("/CarePlanAuto"))
                let store3 = OCKCarePlanStore.init(persistenceDirectoryURL: dataPath!)
                store3.activitiesWithCompletion({ (boolVal, activities, error) in
                    for activity in activities
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
            
            if NSFileManager.defaultManager().fileExistsAtPath(paths[0].stringByAppendingString("/CarePlanIncomplete")) {
                let dataPath = NSURL.init(string:paths[0].stringByAppendingString("/CarePlanIncomplete"))
                let store4 = OCKCarePlanStore.init(persistenceDirectoryURL: dataPath!)
                store4.activitiesWithCompletion({ (boolVal, activities, error) in
                    for activity in activities {
                        store4.removeActivity(activity, completion: { (boolVal, error) in
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
    
    func careCardViewController(viewController: OCKCareCardViewController, shouldHandleEventCompletionForActivity interventionActivity: OCKCarePlanActivity) -> Bool {
        if interventionActivity.groupIdentifier == "Group I4" {
            return false
        }
        return true
    }
    
    func careCardViewController(viewController: OCKCareCardViewController, didSelectButtonWithInterventionEvent interventionEvent: OCKCarePlanEvent) {
        if interventionEvent.activity.groupIdentifier == "Group I4" {
            viewController.maskImageTintColor = interventionEvent.activity.tintColor
        }
    }
    
    func careCardViewController(viewController: OCKCareCardViewController, didSelectRowWithInterventionActivity interventionActivity: OCKCarePlanActivity) {
        if interventionActivity.groupIdentifier == "Group I2" {
            let detailsViewController = UIViewController.init()
            detailsViewController.view.backgroundColor = UIColor.grayColor()
            let textView = UITextView.init(frame: CGRectMake(30, 100, 300, 400))
            textView.backgroundColor = UIColor.whiteColor()
            textView.editable = false
            var text = interventionActivity.title + "\n"
            
            viewController.store.enumerateEventsOfActivity(interventionActivity, startDate: NSDateComponents.init(date: NSDate(), calendar: NSCalendar.currentCalendar()), endDate: NSDateComponents.init(date: NSDate(), calendar: NSCalendar.currentCalendar()), handler:
                { (event, stop) in
                    text = text.stringByAppendingString("Occurence #" + String(event!.occurrenceIndexOfDay))
                    text = text.stringByAppendingString(" : State " + String(event!.state.rawValue) + "\n")
                
                }, completion: { (completed, error) in
                    if completed == true {
                        dispatch_async(dispatch_get_main_queue()){
                            textView.text = text
                            detailsViewController.view.addSubview(textView)
                            viewController.navigationController?.pushViewController(detailsViewController, animated: true)
                        }
                    } else {
                        assert(completed, (error?.description)!)
                    }
            })
        }
    }
    
    func carePlanStoreActivityListDidChange(store: OCKCarePlanStore) {
       print("carePlanStoreActivityListDidChange")
    }
    
    func carePlanStore(store: OCKCarePlanStore, didReceiveUpdateOfEvent event: OCKCarePlanEvent) {
        
        print("Care Event Details\n")
        print("Occurence: " + String(event.occurrenceIndexOfDay))
        print("Days Since Start: " + String(event.numberOfDaysSinceStart))
        print("Date: " + String(event.date))
        print("Activity: " + String(event.activity.title))
        print("State: " + String(event.state.rawValue))
        print("Result: " + String(event.result))

    }
}
