/*
 Copyright (c) 2017, Apple Inc. All rights reserved.
 
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

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "cell") {
            switch (indexPath as NSIndexPath).row {
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
            case 8:
                cell.textLabel?.text = "Trying different glyphType"
            case 9:
                cell.textLabel?.text = "Trying different Tint Color"
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
            
            // Many Activities, Many Schedules
          
            var startDateComponents = DateComponents.init()
            startDateComponents.day = 20
            startDateComponents.month = 2
            startDateComponents.year = 2015
            
            let dailySchedule:OCKCareSchedule = OCKCareSchedule.dailySchedule(withStartDate: startDateComponents, occurrencesPerDay: 2)
            let weeklySchedule = OCKCareSchedule.weeklySchedule(withStartDate: startDateComponents, occurrencesOnEachDay:[4, 0, 4, 0, 4, 0, 4])
            let alternateWeeklySchedule = OCKCareSchedule.weeklySchedule(withStartDate: startDateComponents, occurrencesOnEachDay: [0, 1, 0, 0, 0, 0, 0], weeksToSkip: 1, endDate: nil)
            let skipDaysSchedule = OCKCareSchedule.dailySchedule(withStartDate: startDateComponents, occurrencesPerDay: 5, daysToSkip: 2, endDate: nil)
            
            var carePlanActivities = [OCKCarePlanActivity]()
            let firstGroupId = "Group I1"
            carePlanActivities.append(OCKCarePlanActivity.init(identifier: "Intervention Activity #1", groupIdentifier: firstGroupId, type: OCKCarePlanActivityType.intervention, title: "Daily Intervention Activity Title 1", text: "Read the instructions about this task", tintColor: nil, instructions: "Perform the described task and report the results. Talk to your doctor if you need help", imageURL: nil, schedule: dailySchedule, resultResettable: true, userInfo: ["Key1":"Value1" as NSCoding,"Key2":"Value2" as NSCoding]))
            
            carePlanActivities.append(OCKCarePlanActivity.init(identifier: "Intervention Activity #2", groupIdentifier: firstGroupId, type: OCKCarePlanActivityType.intervention, title: "Alternate-Day Intervention Activity Title 2", text: "Complete this activity ASAP. No Instructions!", tintColor: UIColor.brown, instructions: nil, imageURL: nil, schedule: weeklySchedule, resultResettable: true, userInfo: ["Key1":"Value1" as NSCoding, "Key2":"Value2" as NSCoding]))
            
            carePlanActivities.append(OCKCarePlanActivity.init(identifier: "Intervention Activity 3", groupIdentifier: firstGroupId, type: OCKCarePlanActivityType.intervention, title: "Repeats Every Three Days", text: "This is a long line of text. It describes the Activity in detail", tintColor: UIColor.red, instructions: LoremIpsum, imageURL: nil, schedule: skipDaysSchedule, resultResettable: false, userInfo:nil))
            
            carePlanActivities.append(OCKCarePlanActivity.init(identifier: "Intervention Activity #4", groupIdentifier: firstGroupId, type: OCKCarePlanActivityType.intervention, title: "Every other-Monday", text: "I am activity #4", tintColor: UIColor.green, instructions: nil, imageURL: nil, schedule: alternateWeeklySchedule, resultResettable: false, userInfo: nil))
            
            carePlanActivities.append(OCKCarePlanActivity.init(identifier: "Intervention Activity #5", groupIdentifier: firstGroupId, type: OCKCarePlanActivityType.intervention, title: "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa.", text: "This is the text", tintColor: nil, instructions: "Take pain medication", imageURL: nil, schedule: dailySchedule, resultResettable: false, userInfo: nil))
            
            let activity6 = OCKCarePlanActivity.init(identifier: "Intervention Activity #6", groupIdentifier: firstGroupId, type: OCKCarePlanActivityType.intervention, title: "Activity Ended Yesterday", text: LoremIpsum, tintColor: UIColor.gray, instructions: LoremIpsum, imageURL: nil, schedule: dailySchedule, resultResettable: true, userInfo: nil)
            carePlanActivities.append(activity6)
            
            carePlanActivities.append(OCKCarePlanActivity.intervention(withIdentifier: "Intervention Activity #7", groupIdentifier: nil, title: "No Group, No Text Activity", text: nil, tintColor: nil, instructions: nil, imageURL: nil, schedule: dailySchedule, userInfo: nil, optional: false))
            
            carePlanActivities.append(OCKCarePlanActivity.intervention(withIdentifier: "Intervention Activity #8", groupIdentifier: nil, title: "", text: "Missing Title", tintColor: UIColor.purple, instructions: "Some Instructions", imageURL: nil, schedule: dailySchedule, userInfo: ["":""], optional: false))
            
            let carePlanStore = OCKCarePlanStore.init(persistenceDirectoryURL: URL.init(string: documentsDirectory[0])!)
            
            for carePlanActivity in carePlanActivities {
                carePlanStore.add(carePlanActivity, completion: { (boolVal, error) in
                    assert(boolVal, (error?.localizedDescription)!)
                })
            }
            
            let dateComponents = NSCalendar.current.dateComponents([.year, .month, .day, .era], from: Date().addingTimeInterval(-86400.0))
            carePlanStore.setEndDate(dateComponents, for: activity6, completion: { (boolVal, activity, error) in
                
            })

            let careCardController = OCKCareCardViewController.init(carePlanStore: carePlanStore)
            self.navigationController?.pushViewController(careCardController, animated: true)
            
        } else if (indexPath as NSIndexPath).row == 1 {
            
            // With Delegate & Images
            
            let dateComponents = DateComponents.init(year: 2015, month: 2, day: 20)
            let schedule = OCKCareSchedule.dailySchedule(withStartDate: dateComponents, occurrencesPerDay: 6)
            
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let imageFileURL = documentsURL.appendingPathComponent("Triangles.jpg")
            let secondGroupId = "Group I2"
            
            let carePlanActivity1 = OCKCarePlanActivity.init(identifier: "Intervention Activity 1", groupIdentifier: secondGroupId, type: OCKCarePlanActivityType.intervention, title: "1. This is the first Intervention Activity", text: "", tintColor: UIColor.red, instructions: "No instructions required", imageURL: imageFileURL, schedule: schedule, resultResettable: true, userInfo: ["Key1":"Value1" as NSCoding,"Key2":"Value2" as NSCoding])
            
            let carePlanActivity2 = OCKCarePlanActivity.init(identifier: "Intervention Activity 2", groupIdentifier: secondGroupId, type: OCKCarePlanActivityType.intervention, title: "2. Another Intervention Activity", text: "Complete this activity ASAP. No Instructions!", tintColor: nil, instructions: nil, imageURL: imageFileURL, schedule: schedule, resultResettable: true, userInfo: nil)
            
            let carePlanActivity3 = OCKCarePlanActivity.intervention(withIdentifier: "Intervention Activity 3", groupIdentifier: secondGroupId, title: "3. Activity #3 is the last one", text: "Some Text", tintColor: UIColor.purple, instructions: "Some Instructions", imageURL: imageFileURL, schedule: schedule, userInfo: ["Key":"Val"], optional:false)
            
            let dataPath = documentsDirectory[0] + "/CarePlan2"
            if !FileManager.default.fileExists(atPath: dataPath) {
                do {
                    try FileManager.default.createDirectory(atPath: dataPath, withIntermediateDirectories: false, attributes: nil)
                } catch(_) {
                    assertionFailure("Unable to Create Directory for CarePlan2")
                }
            }
            
            let carePlanStore = OCKCarePlanStore.init(persistenceDirectoryURL: URL.init(string: dataPath)!)
            carePlanStore.delegate = self
            carePlanStore.add(carePlanActivity1, completion: { (boolVal, error) in
                assert(boolVal, (error?.localizedDescription)!)
            })
            carePlanStore.add(carePlanActivity2, completion: { (boolVal, error) in
                assert(boolVal, (error?.localizedDescription)!)
            })
            carePlanStore.add(carePlanActivity3, completion: { (boolVal, error) in
                assert(boolVal, (error?.localizedDescription)!)
                
            })
            
            let careCardController = OCKCareCardViewController.init(carePlanStore: carePlanStore)
            careCardController.glyphType = .accessibility
            careCardController.glyphTintColor = UIColor.cyan
            self.navigationController?.pushViewController(careCardController, animated: true)
            
        } else if (indexPath as NSIndexPath).row == 2 {
            
            // No Activities
            
            let dataPath = documentsDirectory[0] + "/EmptyCarePlan"
            if !FileManager.default.fileExists(atPath: dataPath) {
                do {
                    try FileManager.default.createDirectory(atPath: dataPath, withIntermediateDirectories: false, attributes: nil)
                } catch(_) {
                    assertionFailure("Unable to Create Directory for EmptyCarePlan")
                }
            }
            
            let carePlanStore = OCKCarePlanStore.init(persistenceDirectoryURL: URL.init(string: dataPath)!)
            let careCardController = OCKCareCardViewController.init(carePlanStore: carePlanStore)
            careCardController.glyphTintColor = UIColor.orange
            self.navigationController?.pushViewController(careCardController, animated: true)
      
        } else if (indexPath as NSIndexPath).row == 3 {
            
            // Auto-Complete, No Edges
            
            let startDateComponents = DateComponents.init(year: 2012, month: 12, day: 12)
            let endDateComponents = DateComponents.init(year: 3000, month: 03, day: 30)
            let schedule = OCKCareSchedule.dailySchedule(withStartDate: startDateComponents, occurrencesPerDay: 5, daysToSkip: 0, endDate: endDateComponents)
            
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let imageFileURL = documentsURL.appendingPathComponent("Triangles.jpg")
            
            let dataPath = documentsDirectory[0] + "/CarePlanAuto"
            if !FileManager.default.fileExists(atPath: dataPath) {
                do {
                    try FileManager.default.createDirectory(atPath: dataPath, withIntermediateDirectories: false, attributes: nil)
                } catch(_) {
                    assertionFailure("Unable to Create Directory for CarePlanAuto")
                }
            }
            
            let carePlanStore = OCKCarePlanStore.init(persistenceDirectoryURL: URL.init(string: dataPath)!)
            
            for index in 1...30 {
                let carePlanActivity = OCKCarePlanActivity.init(identifier: "Intervention Activity" + String(index), groupIdentifier: "Group I2", type: OCKCarePlanActivityType.intervention, title: "Activity Title"+String(index), text: "Text Text Text" + String(index), tintColor: UIColor.init(red: 0.2, green: 0.4, blue: 0.9, alpha: 0.4), instructions: "This is a set of instructions for activity #" + String(index), imageURL: imageFileURL, schedule: schedule, resultResettable: true, userInfo: nil)
                carePlanStore.add(carePlanActivity, completion: { (boolVal, error) in
                    assert(boolVal, (error?.localizedDescription)!)
                })
            }

            let dateComponents = NSCalendar.current.dateComponents([.year, .month, .day, .era], from: Date())
            carePlanStore.events(onDate: dateComponents, type: OCKCarePlanActivityType.intervention, completion: { (allEventsArray, error) in
                for activityEvents in allEventsArray {
                    for event in activityEvents {
                            carePlanStore.update(event, with: nil, state: OCKCarePlanEventState.completed, completion: { (boolVal, event, error) in
                        })
                    }
                }
            })

            
            let careCardController = OCKCareCardViewController.init(carePlanStore: carePlanStore)
            careCardController.glyphTintColor = UIColor.init(red: 0.2, green: 0.4, blue: 0.9, alpha: 0.4)
            self.navigationController?.pushViewController(careCardController, animated: true)
            
        } else if (indexPath as NSIndexPath).row == 4 {
            
            // Activities don't complete

            let dateComponents = DateComponents.init(year: 2015, month: 2, day: 20)
            let schedule = OCKCareSchedule.dailySchedule(withStartDate: dateComponents, occurrencesPerDay: 14)
            let fourthGroupId = "Group I4"
            let carePlanActivity1 = OCKCarePlanActivity.init(identifier: "ActivityDoesntComplete1", groupIdentifier: fourthGroupId, type: OCKCarePlanActivityType.intervention, title: "Does not Complete", text: "Tint color changes on tap", tintColor: UIColor.blue, instructions: "No instructions required", imageURL: nil, schedule: schedule, resultResettable: true, userInfo:nil)
            let carePlanActivity2 = OCKCarePlanActivity.init(identifier: "ActivityDoesntComplete2", groupIdentifier: fourthGroupId, type: OCKCarePlanActivityType.intervention, title: "Does not Complete", text: "Tint color changes on tap", tintColor: UIColor.purple, instructions: "", imageURL: nil, schedule: schedule, resultResettable: true, userInfo:nil)
            
            let dataPath = documentsDirectory[0] + "/CarePlanIncomplete"
            
            if !FileManager.default.fileExists(atPath: dataPath) {
                do {
                    try FileManager.default.createDirectory(atPath: dataPath, withIntermediateDirectories: false, attributes: nil)
                } catch(_) {
                    assertionFailure("Unable to Create Directory for CarePlanIncomplete")
                }
            }
            
            let carePlanStore = OCKCarePlanStore.init(persistenceDirectoryURL: URL.init(string: dataPath)!)
            carePlanStore.delegate = self
            carePlanStore.add(carePlanActivity1, completion: { (boolVal, error) in
                assert(boolVal, (error?.localizedDescription)!)
            })
            carePlanStore.add(carePlanActivity2, completion: { (boolVal, error) in
                assert(boolVal, (error?.localizedDescription)!)
            })

            let careCardController = OCKCareCardViewController.init(carePlanStore: carePlanStore)
            careCardController.delegate = self
            self.navigationController?.pushViewController(careCardController, animated: true)
            
        }  else if (indexPath as NSIndexPath).row == 5 {
            
            // Custom Details for Activities

            let dataPath = documentsDirectory[0] + "/CarePlan2"
            if !FileManager.default.fileExists(atPath: dataPath) {
                return
            }
            let carePlanStore = OCKCarePlanStore.init(persistenceDirectoryURL: URL.init(string: dataPath)!)
            let careCardController = OCKCareCardViewController.init(carePlanStore: carePlanStore)
            careCardController.delegate = self
            self.navigationController?.pushViewController(careCardController, animated: true)
            
        } else if (indexPath as NSIndexPath).row == 6 {
            
            // Save an Image
            
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            if let image = UIImage.init(named: "Triangles.jpg") {
                let imageFileURL = documentsURL.appendingPathComponent("Triangles.jpg")
                if let jpgImageData = UIImageJPEGRepresentation(image,0.5) {
                    try? jpgImageData.write(to: imageFileURL, options: [])
                }
            }
            tableView.cellForRow(at: indexPath)?.textLabel?.textColor = UIColor.green
            tableView.cellForRow(at: indexPath)?.isSelected = false
            
        } else if (indexPath as NSIndexPath).row == 7 {
            // No Activities
            
            let dataPath = documentsDirectory[0] + "/EmptyCarePlan"
            if !FileManager.default.fileExists(atPath: dataPath) {
                do {
                    try FileManager.default.createDirectory(atPath: dataPath, withIntermediateDirectories: false, attributes: nil)
                } catch(_) {
                    assertionFailure("Unable to Create Directory for EmptyCarePlan")
                }
            }
            
            let carePlanStore = OCKCarePlanStore.init(persistenceDirectoryURL: URL.init(string: dataPath)!)
            let careCardController = OCKCareCardViewController.init(carePlanStore: carePlanStore)
            careCardController.glyphTintColor = UIColor.orange
            self.navigationController?.pushViewController(careCardController, animated: true)
        } else if (indexPath as NSIndexPath).row == 8 {
            // No Activities
            
            let dataPath = documentsDirectory[0] + "/EmptyCarePlan"
            if !FileManager.default.fileExists(atPath: dataPath) {
                do {
                    try FileManager.default.createDirectory(atPath: dataPath, withIntermediateDirectories: false, attributes: nil)
                } catch(_) {
                    assertionFailure("Unable to Create Directory for EmptyCarePlan")
                }
            }
            
            let carePlanStore = OCKCarePlanStore.init(persistenceDirectoryURL: URL.init(string: dataPath)!)
            let careCardController = OCKCareCardViewController.init(carePlanStore: carePlanStore)
            careCardController.glyphType = .accessibility
            careCardController.glyphTintColor = UIColor.orange
            self.navigationController?.pushViewController(careCardController, animated: true)
        } else if (indexPath as NSIndexPath).row == 9 {
            // No Activities
            
            let dataPath = documentsDirectory[0] + "/EmptyCarePlan"
            if !FileManager.default.fileExists(atPath: dataPath) {
                do {
                    try FileManager.default.createDirectory(atPath: dataPath, withIntermediateDirectories: false, attributes: nil)
                } catch(_) {
                    assertionFailure("Unable to Create Directory for EmptyCarePlan")
                }
            }
            
            let carePlanStore = OCKCarePlanStore.init(persistenceDirectoryURL: URL.init(string: dataPath)!)
            let careCardController = OCKCareCardViewController.init(carePlanStore: carePlanStore)
            careCardController.glyphTintColor = UIColor.magenta
            self.navigationController?.pushViewController(careCardController, animated: true)
        }
    }
    
    func careCardViewController(_ viewController: OCKCareCardViewController, shouldHandleEventCompletionFor interventionActivity: OCKCarePlanActivity) -> Bool {
        if interventionActivity.groupIdentifier == "Group I4" {
            return false
        }
        return true
    }
    
    func careCardViewController(_ viewController: OCKCareCardViewController, didSelectButtonWithInterventionEvent interventionEvent: OCKCarePlanEvent) {
        if interventionEvent.activity.groupIdentifier == "Group I4" {
            viewController.glyphTintColor = interventionEvent.activity.tintColor
        }
    }
    
    func careCardViewController(_ viewController: OCKCareCardViewController, didSelectRowWithInterventionActivity interventionActivity: OCKCarePlanActivity) {
        if interventionActivity.groupIdentifier == "Group I2" {
            let detailsViewController = UIViewController.init()
            detailsViewController.view.backgroundColor = UIColor.gray
            let textView = UITextView.init(frame: CGRect(x: 30, y: 100, width: 300, height: 400))
            textView.backgroundColor = UIColor.white
            textView.isEditable = false
            var text = interventionActivity.title + "\n"
            
            let dateComponents = NSCalendar.current.dateComponents([.year, .month, .day, .era], from: Date())
            viewController.store.enumerateEvents(of: interventionActivity, startDate: dateComponents, endDate: dateComponents, handler:
                { (event, stop) in
                    text = text + ("Occurence #" + String(event!.occurrenceIndexOfDay))
                    text = text + (" : State " + String(event!.state.rawValue) + "\n")
                
                }, completion: { (completed, error) in
                    if completed == true {
                        DispatchQueue.main.async{
                            textView.text = text
                            detailsViewController.view.addSubview(textView)
                            viewController.navigationController?.pushViewController(detailsViewController, animated: true)
                        }
                    } else {
                        assert(completed, (error?.localizedDescription)!)
                    }
            })
        }
    }
    
    func carePlanStoreActivityListDidChange(_ store: OCKCarePlanStore) {
       print("carePlanStoreActivityListDidChange")
    }
    
    func carePlanStore(_ store: OCKCarePlanStore, didReceiveUpdateOf event: OCKCarePlanEvent) {
        
        print("Care Event Details\n")
        print("Occurence: " + String(event.occurrenceIndexOfDay))
        print("Days Since Start: " + String(event.numberOfDaysSinceStart))
        print("Date: " + String(describing: event.date))
        print("Activity: " + String(event.activity.title))
        print("State: " + String(event.state.rawValue))
        print("Result: " + String(describing: event.result))

    }
}
