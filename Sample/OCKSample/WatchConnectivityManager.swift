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
import WatchConnectivity

class WatchConnectivityManager : NSObject {
    
    // MARK: Properties
    var store : OCKCarePlanStore
    var session : WCSession
    var glyphType: String = "Image Unavailable"
    var customGlyphImage: UIImage = UIImage()
    var glyphTintColor: [CGFloat] = [239.0, 68.0, 91.0, 0.0]
    var glyphImageName: String = "Heart"

    var eventUpdatesFromWatch = [String]()
    
    // MARK: Initialization
    
    init(withStore store : OCKCarePlanStore) {
        self.store = store
        self.session = WCSession.default()

        super.init()
        
        session.delegate = self
        
        if (WCSession.isSupported()) {
            session.activate()
        }
    }
}

// MARK: Outgoing messages

extension WatchConnectivityManager : OCKCarePlanStoreDelegate {
    
    func carePlanStore(_ store: OCKCarePlanStore, didReceiveUpdateOf event: OCKCarePlanEvent) {
        
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        
        let today = calendar.dateComponents([.day, .month, .year, .era], from: Date())
        let eventIsToday = (today.day == event.date.day && today.month == event.date.month && today.year == event.date.year && today.era == event.date.era)
        
        let eventUpdateString = hashEventUpdate(event.activity.identifier, eventIndex: event.occurrenceIndexOfDay, state: event.state)
        if let hashIndex = eventUpdatesFromWatch.index(of: eventUpdateString) {
            eventUpdatesFromWatch.remove(at: hashIndex)
            
            return
        }
        
        self.session.transferCurrentComplicationUserInfo(["glyphType" : self.glyphType,
                                                          "glyphTintColor" : self.glyphTintColor,
                                                          "glyphImageName" : self.glyphImageName])
        try? self.session.updateApplicationContext(["glyphType" : self.glyphType])
        
        if eventIsToday {
            
            weak var weakSelf = self
            self.store.events(onDate: today, type: .intervention, completion: { (allInterventionsArray, errorOrNil) in
                let interventionsCompleted = allInterventionsArray.map({$0.filter({$0.state == OCKCarePlanEventState.completed && !$0.activity.optional}).count}).reduce(0, +)
                let totalInterventions = allInterventionsArray.map({$0.filter({!$0.activity.optional}).count}).reduce(0, +)
                
                if let strongSelf = weakSelf {
                    strongSelf.store.events(onDate: today, type: .assessment, completion: { (allAssessmentsArray, errorOrNil) in
                        let assessmentsCompleted = allAssessmentsArray.map({$0.filter({$0.state == OCKCarePlanEventState.completed && !$0.activity.optional}).count}).reduce(0, +)
                        let totalAssessments = allAssessmentsArray.map({$0.filter({!$0.activity.optional}).count}).reduce(0, +)
                        let eventsCompleted = interventionsCompleted + assessmentsCompleted
                        let totalEvents = totalInterventions + totalAssessments
                        let completionPercentage = round(Float(eventsCompleted) * 100.0 / Float(totalEvents))
                        if strongSelf.session.isReachable {
                            let data = NSMutableData()
                            let encoder = NSKeyedArchiver(forWritingWith: data)
                            
                            encoder.encode("updateEvent", forKey: "type")
                            encoder.encode(strongSelf.parseEventToDictionary(event), forKey: "event")
                            encoder.encode(Int64(completionPercentage), forKey: "currentCompletionPercentage")
                            
                            encoder.finishEncoding()
                            strongSelf.session.sendMessageData(data as Data, replyHandler: nil, errorHandler: nil)
                        } else {
                            strongSelf.session.transferCurrentComplicationUserInfo(["glyphType" : strongSelf.glyphType,
                                                                              "glyphTintColor" : strongSelf.glyphTintColor,
                                                                              "glyphImageName" : strongSelf.glyphImageName])
                            try? strongSelf.session.updateApplicationContext(["glyphType" : strongSelf.glyphType,"currentCompletionPercentage" : completionPercentage, "eventsRemaining" : totalEvents - eventsCompleted])
                        }
                    })
                }
            })
        }
    }
    
    func carePlanStoreActivityListDidChange(_ store: OCKCarePlanStore) {
        if session.isReachable == true {
            // Only update watch if the watch app is reachable ("paired and active Apple Watch is in range and the associated Watch app is running in the foreground")
            parseEntireStore({_ in })
        } else {
            // If not reachable, send background user info to update complications
            let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
            let today = calendar.dateComponents([.day, .month, .year, .era], from: Date())
            
            weak var weakSelf = self
            self.store.events(onDate: today, type: .intervention, completion: { (allInterventionsArray, errorOrNil) in
                let interventionsCompleted = allInterventionsArray.map({$0.filter({$0.state == OCKCarePlanEventState.completed && !$0.activity.optional}).count}).reduce(0, +)
                let totalInterventions = allInterventionsArray.map({$0.filter({!$0.activity.optional}).count}).reduce(0, +)
                
                if let strongSelf = weakSelf {
                    strongSelf.store.events(onDate: today, type: .assessment, completion: { (allAssessmentsArray, errorOrNil) in
                        let assessmentsCompleted = allAssessmentsArray.map({$0.filter({$0.state == OCKCarePlanEventState.completed && !$0.activity.optional}).count}).reduce(0, +)
                        let totalAssessments = allAssessmentsArray.map({$0.filter({!$0.activity.optional}).count}).reduce(0, +)
                        let eventsCompleted = interventionsCompleted + assessmentsCompleted
                        let totalEvents = totalInterventions + totalAssessments
                        let completionPercentage = round(Float(eventsCompleted) * 100.0 / Float(totalEvents))
                        
                        try? self.session.updateApplicationContext(["glyphType" : self.glyphType, "currentCompletionPercentage" : completionPercentage, "eventsRemaining" : totalEvents - eventsCompleted])
                        self.session.transferCurrentComplicationUserInfo(["glyphType" : self.glyphType,
                                                                          "glyphTintColor" : self.glyphTintColor,
                                                                          "glyphImageName" : self.glyphImageName])
                    })
                }
            })
        }
    }
    
    // transfer glyph type and tint color
    func sendGlyphType(glyphType: String, glyphTintColor: [CGFloat]) {
        
        if self.session.isReachable {
            let data = NSMutableData()
            let encoder = NSKeyedArchiver(forWritingWith: data)
            
            encoder.encode(glyphType, forKey: "glyphType")
            encoder.finishEncoding()
            
            self.session.sendMessageData(data as Data, replyHandler: nil, errorHandler: nil)
        } else {
            self.session.transferCurrentComplicationUserInfo(["glyphType" : glyphType, "glyphTintColor" : glyphTintColor])
            try? self.session.updateApplicationContext(["glyphType" : glyphType])
        }
    }
    
    // transfer glyph type, tint color and image it is a custom glyph image type
    func sendGlyphType(glyphType: String, glyphTintColor: [CGFloat], glyphImageName: String) {
        
        if self.session.isReachable {
            let data = NSMutableData()
            let encoder = NSKeyedArchiver(forWritingWith: data)
            
            encoder.encode(glyphType, forKey: "glyphType")
            encoder.finishEncoding()
            
            self.session.sendMessageData(data as Data, replyHandler: nil, errorHandler: nil)
        } else {
            self.session.transferCurrentComplicationUserInfo(["glyphType" : glyphType,
                                                              "glyphTintColor" : glyphTintColor,
                                                              "glyphImageName" : glyphImageName])
            try? self.session.updateApplicationContext(["glyphType" : glyphType])
        }
    }
}

// MARK: Incoming messages

extension WatchConnectivityManager : WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            store.watchDelegate = self
        } else {
            store.watchDelegate = nil
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default().activate()
    }
   
    func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
        let decoder = NSKeyedUnarchiver(forReadingWith: messageData)
        defer {
            decoder.finishDecoding()
        }
        
        let type = decoder.decodeObject(forKey: "type") as! String
        
        switch type {
        case "getAllData":
            parseEntireStore({ (storeDictionary) in
                replyHandler(storeDictionary)
            })
            
        case "updateEventState":
            let activityIdentifier = decoder.decodeObject(forKey: "activityIdentifier") as! String
            let eventIndex = UInt(decoder.decodeInt64(forKey: "eventIndex"))
            let completed = decoder.decodeBool(forKey: "completedState")
            
            var updatedEvent : OCKCarePlanEvent?
            
            let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
            
            let today = calendar.dateComponents([.day, .month, .year, .era], from: Date())
            
            store.events(onDate: today, type: .intervention, completion: { (allEventsArray, errorOrNil) in
                for activityGroup in allEventsArray {
                    if !activityGroup.isEmpty && activityGroup[0].activity.identifier == activityIdentifier {
                        for event in activityGroup {
                            if event.occurrenceIndexOfDay == eventIndex {
                                updatedEvent = event
                                break
                            }
                        }
                    }
                }
                
                guard let newEvent = updatedEvent else {
                    self.parseEntireStore({ _ in })
                    return
                }
                
                self.store.update(newEvent,
                    with: nil,
                    state: completed ? .completed : .notCompleted,
                    completion: { (success, event, errorOrNil) in
                        let replyData = NSMutableData()
                        let encoder = NSKeyedArchiver(forWritingWith: replyData)
                        encoder.encode("updateEventResponse", forKey: "type")
                        encoder.encode(success, forKey: "success")
                        
                        encoder.finishEncoding()
                        replyHandler(replyData as Data)
                        if success {
                            self.eventUpdatesFromWatch.append(self.hashEventUpdate(activityIdentifier, eventIndex: eventIndex, state: completed ? .completed : .notCompleted))
                        }
                })
            })
        
        default:
            replyHandler(Data())
        }
    }
   
    // MARK: Data parsing
    
    func parseEntireStore(_ initialCompletion: @escaping (Data) -> Void) {
        let data = NSMutableData()
        let encoder = NSKeyedArchiver(forWritingWith: data)
        encoder.encode("allData", forKey: "type")
        
        var activitiesArray = [[String : Any]]()
        var masterEventsArray = [String : [[String : Any]]]()
        
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let today = calendar.dateComponents([.day, .month, .year, .era], from: Date())
        
        weak var weakSelf = self
        
        self.store.events(onDate: today, type: .intervention, completion: { (allInterventionsArray, errorOrNil) in
            // allEventsArray is grouped by activity.
            var order = [String]()
            var interventionsParsed = 0
            for interventionActivityGroup in allInterventionsArray {
                if interventionActivityGroup.count == 0 {
                    continue
                }
                
                var interventionEventArray = [[String : Any]]()
                activitiesArray.append(self.parseActivityToDictionary(interventionActivityGroup[0].activity, numberOfEventsForToday: UInt(interventionActivityGroup.count)))
                for event in interventionActivityGroup {
                    interventionEventArray.append(self.parseEventToDictionary(event))
                }
                masterEventsArray[interventionActivityGroup[0].activity.identifier] = interventionEventArray
                order.append(interventionActivityGroup[0].activity.identifier)
                
                interventionsParsed += 1
                if interventionsParsed == 2 {
                    let initialReplyData = NSMutableData()
                    let initialEncoder = NSKeyedArchiver(forWritingWith: initialReplyData)
                    initialEncoder.encode("allDataInitial", forKey: "type")
                    initialEncoder.encode(order, forKey: "activityOrder")
                    initialEncoder.encode(activitiesArray, forKey: "activities")
                    initialEncoder.encode(masterEventsArray, forKey: "events")
                    
                    initialEncoder.finishEncoding()
                    initialCompletion(initialReplyData as Data)
                }
            }
            
            if let strongSelf = weakSelf {
                strongSelf.store.events(onDate: today, type: .assessment, completion: { (allAssessmentsArray, errorOrNil) in
                    var assessmentsParsed = 0
                    for assessmentActivityGroup in allAssessmentsArray {
                        if assessmentActivityGroup.count == 0 {
                            continue
                        }
                        
                        var assessmentEventArray = [[String : Any]]()
                        activitiesArray.append(self.parseActivityToDictionary(assessmentActivityGroup[0].activity, numberOfEventsForToday: UInt(1)))
                        
                        assessmentEventArray.append(self.parseEventToDictionary(assessmentActivityGroup.first!))
                        
                        masterEventsArray[assessmentActivityGroup[0].activity.identifier] = assessmentEventArray
                        order.append(assessmentActivityGroup[0].activity.identifier)
                        
                        assessmentsParsed += 1
                        if assessmentsParsed == 2 {
                            let initialReplyData = NSMutableData()
                            let initialEncoder = NSKeyedArchiver(forWritingWith: initialReplyData)
                            initialEncoder.encode("allDataInitial", forKey: "type")
                            initialEncoder.encode(order, forKey: "activityOrder")
                            initialEncoder.encode(activitiesArray, forKey: "activities")
                            initialEncoder.encode(masterEventsArray, forKey: "events")
                            
                            initialEncoder.finishEncoding()
                            initialCompletion(initialReplyData as Data)
                        }
                    }
                    encoder.encode(order, forKey: "activityOrder")
                    encoder.encode(activitiesArray, forKey: "activities")
                    encoder.encode(masterEventsArray, forKey: "events")
                    
                    encoder.finishEncoding()
                    self.session.sendMessageData(data as Data, replyHandler: nil, errorHandler: nil)
                })
            }
        })
        
    }
    
    func parseActivityToDictionary(_ activity: OCKCarePlanActivity, numberOfEventsForToday: UInt) -> [String : Any] {
        var activityDictionary = [String: Any]()
        activityDictionary["identifier"] = activity.identifier
        activityDictionary["title"] = activity.title
        activityDictionary["isOptional"] = activity.optional
        
        if activity.type == .intervention {
            activityDictionary["isIntervention"] = true
        }
        else {
            activityDictionary["isIntervention"] = false
        }
        
        if activity.text != nil {
            activityDictionary["text"] = activity.text
        }
        
        if activity.tintColor != nil {
            let colorsArray = activity.tintColor?.cgColor.components
            if colorsArray != nil {
                activityDictionary["tintColor"] = [colorsArray![0], colorsArray![1], colorsArray![2], colorsArray![3]]
            }
        }
        
        activityDictionary["numberOfEventsForToday"] = numberOfEventsForToday
        
        return activityDictionary
    }
    
    func parseEventToDictionary(_ event: OCKCarePlanEvent) -> [String : Any] {
        var eventDictionary = [String: Any]()
        eventDictionary["occurenceIndexOfDay"] = event.occurrenceIndexOfDay
        eventDictionary["activityIdentifier"] = event.activity.identifier
        eventDictionary["state"] = event.state.rawValue
        return eventDictionary
    }
    
    // MARK: Handling concurency with watch
    
    func hashEventUpdate(_ activityIdentifier : String, eventIndex : UInt, state : OCKCarePlanEventState) -> String {
        return "\(activityIdentifier);\(eventIndex);\(state.rawValue)"
    }
    
}
