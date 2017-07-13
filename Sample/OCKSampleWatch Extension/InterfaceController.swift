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

import WatchKit
import Foundation
import WatchConnectivity
import ClockKit


class InterfaceController: WKInterfaceController {
    
    // MARK: Properties
    
    static let watchTintColor = UIColor.init(red: 239.0/255.0, green: 68.0/255.0, blue: 91.0/255.0, alpha: 1.0)
    
    @IBOutlet var loaderGroup: WKInterfaceGroup!
    @IBOutlet var loaderImage: WKInterfaceImage!
    @IBOutlet var loaderLabel: WKInterfaceLabel!
    
    @IBOutlet var tableView: WKInterfaceTable!
        
    let session = WCSession.default
    var activities = [String : WCKActivity]()
    var activityOrder = [String]()
    var activityRowIndices = [String : Int]()
    
    // MARK: Initialization
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        session().delegate = self
        session().activate()
    }
    
    override func willActivate() {
        self.setTitle("")

        if session().activationState != .activated {
            session().activate()
        } else {
            loadData()
        }
    }
    
    func loadData() {
        self.setTitle("")
        loaderGroup.setHidden(false)
        loaderImage.startAnimating()
        loaderLabel.setText("Loading\nCare Contents")
        activities.removeAll()
        activityOrder.removeAll()
        activityRowIndices.removeAll()
        tableView.setHidden(false)
        tableView.removeRows(at: IndexSet.init(integersIn: 0..<tableView.numberOfRows))
        
        getAllData()
    }
    
    func didLosePhoneConnection() {
        guard session().activationState != .activated else {
            return
        }
        
        self.setTitle("")
        loaderGroup.setHidden(false)
        loaderImage.stopAnimating()
        loaderLabel.setText("Please connect your phone")
        
        activities.removeAll()
        activityOrder.removeAll()
        activityRowIndices.removeAll()
        tableView.removeRows(at: IndexSet.init(integersIn: 0..<tableView.numberOfRows))
        tableView.setHidden(true)
        updateComplications(withCompletionPercentage: nil)
        updateComplications(withComplicationGlyphType: "Image Unavailable")
    }
    
    
    // MARK: Rendering the UI
    
    func setupTable() {
        tableView.setNumberOfRows(0, withRowType: "ActivityRow")
        
        for identifier in activityOrder {
            let activity = self.activities[identifier]!
            
            appendActivityToTable(activity)
        }
    }
    
    func appendActivityToTable(_ activity : WCKActivity) {
        tableView.setHidden(false)
        var rowIndex = tableView.numberOfRows
        
        guard !activityRowIndices.keys.contains(activity.identifier) else {
            return
        }
        
        tableView.insertRows(at: IndexSet.init(integer: rowIndex), withRowType: "ActivityRow")
        if let row = tableView.rowController(at: rowIndex) as? ActivityRow {
            row.load(fromActivity: activity)
            activityRowIndices[activity.identifier] = rowIndex
            rowIndex += 1
        }
        
        let activityChildEvents = activity.eventsForToday
        let activityEventRows = getRowIndex(ofEventIndex: activityChildEvents.count - 1) + 1
        
        tableView.insertRows(at: IndexSet.init(integersIn: NSMakeRange(rowIndex, activityEventRows).toRange() ?? 0..<0) , withRowType: "EventRow")
        
        for childRowIndex in 0..<activityEventRows {
            if let row = tableView.rowController(at: rowIndex + childRowIndex) as? EventRow {
                row.load(fromActivity: activity, withRowIndex: childRowIndex, parent: self)
            }
        }
    }
    
    func updateEventButton(forActivityIdentifier activityIdentifier: String, eventIndex: Int) {
        
        if (activities.keys.contains(activityIdentifier) && (activities[activityIdentifier]?.type == .intervention)) {
        let eventRowIndex = activityRowIndices[activityIdentifier]! + 1 + getRowIndex(ofEventIndex: eventIndex)
        let eventState = activities[activityIdentifier]!.eventsForToday[eventIndex]!.state
        
        if let row = tableView.rowController(at: eventRowIndex) as? EventRow {
            row.updateButton(withEventIndex: eventIndex, toState: eventState)
        }
        }
    }
        func updateAllEventButtons() {
        for (identifier, activity) in activities {
            for rowIndex in 0...getRowIndex(ofEventIndex: activity.eventsForToday.count - 1) {
                if let row = tableView.rowController(at: activityRowIndices[identifier]! + 1 + rowIndex) as? EventRow {
                    var columnIndex = 0
                    while 3 * rowIndex + columnIndex < activity.eventsForToday.count {
                        row.updateButton(withColumnIndex: columnIndex, toState: activity.eventsForToday[3 * rowIndex + columnIndex]!.state)
                        columnIndex += 1
                    }

                }
            }
        }
    }
    
    func updateTitleLabel(withCompletionPercentage completionPercentage : Int?) {
        let percentageToDispaly = (completionPercentage == nil) ? getCompletionPercentage() : completionPercentage!
        self.setTitle("\(percentageToDispaly)%")
    }
    
    func updateComplications(withCompletionPercentage completionPercentage : Int?) {
        let eventsComplete = self.activities.values.map({$0.getNumberOfCompletedEvents()}).reduce(0, +)
        let eventsTotal = self.activities.values.map({$0.eventsForToday.count}).reduce(0, +)
        let defaults = UserDefaults.standard
        
        if completionPercentage != nil {
            defaults.set(completionPercentage!, forKey: "currentCompletionPercentage")
        } else {
            if eventsTotal != 0 {
                defaults.set(Int(round(Float(eventsComplete) * 100.0 / Float(eventsTotal))), forKey: "currentCompletionPercentage")
            } else {
                defaults.set(-1, forKey: "currentCompletionPercentage")
            }
        }
        defaults.set(eventsTotal - eventsComplete, forKey: "eventsRemaining")
        
        let server = CLKComplicationServer.sharedInstance()
        for complication in server.activeComplications! {
            server.reloadTimeline(for: complication)
        }
    }
    
    func updateComplications(withComplicationGlyphType glyphType: String) {
        let defaults = UserDefaults.standard
        if (glyphType != "Image Unavailable") {
            defaults.set(glyphType, forKey: "glyphType")
        }
        let server = CLKComplicationServer.sharedInstance()
        for complication in server.activeComplications! {
            server.reloadTimeline(for: complication)
        }
    }
    
    func getCompletionPercentage() -> Int {
        let eventsComplete = self.activities.values.filter({!$0.isOptional!}).map({$0.getNumberOfCompletedEvents()}).reduce(0, +)
        let eventsTotal = self.activities.values.filter({!$0.isOptional!}).map({$0.eventsForToday.count}).reduce(0, +)
        
        if eventsTotal == 0 {
            return 0
        }
        
        return Int(round(Float(eventsComplete) * 100.0 / Float(eventsTotal)))
    }
    
    
    // MARK: Table Navigation
    
    func getRowIndex(ofEventIndex eventIndex : Int) -> Int {
        return Int(floor(Float(eventIndex) / 3.0))
    }
    
    
    // MARK: Sending Updates
    
    func updateDataStoreEvent(withActivityIdentifier activityIdentifier : String, atIndex eventIndex : Int, toCompletedState completedState : Bool) {
        
        if !session().isReachable {
            didLosePhoneConnection()
            return
        }
        
        let data = NSMutableData()
        let encoder = NSKeyedArchiver(forWritingWith: data)
        encoder.encode("updateEventState", forKey: "type")
        encoder.encode(activityIdentifier, forKey: "activityIdentifier")
        encoder.encode(Int64(eventIndex), forKey: "eventIndex")
        encoder.encode(completedState, forKey: "completedState")
        
        self.activities[activityIdentifier]?.eventsForToday[eventIndex]!.state = completedState ? .completed : .notCompleted
        updateTitleLabel(withCompletionPercentage: nil)
        updateComplications(withCompletionPercentage: nil)
        
        encoder.finishEncoding()
        session().sendMessageData(data as Data, replyHandler: {data in
            let decoder = NSKeyedUnarchiver(forReadingWith: data)
            if decoder.decodeBool(forKey: "success") {
            } else {
                self.activities[activityIdentifier]?.eventsForToday[eventIndex]!.state = completedState ? .notCompleted : .completed
                self.updateEventButton(forActivityIdentifier: activityIdentifier, eventIndex: eventIndex)
                self.updateTitleLabel(withCompletionPercentage: nil)
                self.updateComplications(withCompletionPercentage: nil)
                self.alertUserForFailedEventUpdate()
            }
            }, errorHandler: {(error) in
                self.alertUserForFailedEventUpdate()
                self.messagingErrorHandler(error as NSError)})
    }
    
    func messagingErrorHandler(_ error : Error) {
        NSLog("error: \(error)\nsession reachable = \(session().isReachable)")
        if session().activationState != .activated {
            didLosePhoneConnection()
        } else {
            loadData()
        }
    }
    
    func alertUserForFailedEventUpdate() {
        presentAlert(withTitle: "Lost Connection", message: "Event could not be updated", preferredStyle: .alert, actions: [WKAlertAction(title: "Dismiss", style: .default, handler: {})])
    }
    
 
    // MARK: Fetching Data
    
    func getAllData() {
        if session().activationState == .activated {
            let data = NSMutableData()
            let encoder = NSKeyedArchiver(forWritingWith: data)
            encoder.encode("getAllData", forKey: "type")
            encoder.finishEncoding()
            session().sendMessageData(data as Data, replyHandler: {(data) in
                let decoder = NSKeyedUnarchiver(forReadingWith: data)
                defer {
                    decoder.finishDecoding()
                }
                
                let type = decoder.decodeObject(forKey: "type") as! String
                guard type == "allDataInitial" else {
                    NSLog("Bad message recieved")
                    return
                }
                
                if self.activities.isEmpty {
                    self.loadAllData(fromData: decoder, isFullData: false)
                }
                
                }, errorHandler: messagingErrorHandler)
        } else {
            didLosePhoneConnection()
        }
    }
    
}


    // MARK: Handling Updates

extension InterfaceController: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            loadData()
        } else {
            didLosePhoneConnection()
        }
    }
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        let decoder = NSKeyedUnarchiver(forReadingWith: messageData)
        defer {
            decoder.finishDecoding()
        }
        
        let type = decoder.decodeObject(forKey: "type") as! String
        
        switch type {
        case "updateEvent":
            updateEventHandler(fromDictionary: decoder.decodeObject(forKey: "event") as! [String : AnyObject],
                               completionPercentage: Int(decoder.decodeInt64(forKey: "currentCompletionPercentage")))
        
        case "allData":
            self.loadAllData(fromData: decoder, isFullData: true)
            self.loaderImage.stopAnimating()
            self.loaderGroup.setHidden(true)
            self.updateTitleLabel(withCompletionPercentage: nil)
            self.updateComplications(withCompletionPercentage: nil)
            
        default:
            NSLog("Invalid message data type recieved")
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        guard let completionPercentage = applicationContext["currentCompletionPercentage"] as? Int else {
            return
        }
        
        guard let eventsRemaining = applicationContext["eventsRemaining"] as? Int else {
            return
        }
        
        guard let glyphType = applicationContext["glyphType"] as? String else {
            return
        }
        
        let defaults = UserDefaults.standard
        defaults.set(completionPercentage, forKey: "currentCompletionPercentage")
        defaults.set(eventsRemaining, forKey: "eventsRemaining")
        defaults.set(glyphType, forKey: "glyphType")
        
        let server = CLKComplicationServer.sharedInstance()
        for complication in server.activeComplications! {
            server.reloadTimeline(for: complication)
        }
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        guard let glyphType = userInfo["glyphType"] as? String else{
            return
        }
        
        guard let glyphTintColor = userInfo["glyphTintColor"] as? [CGFloat] else {
            return
        }
        
        guard let glyphImageName = userInfo["glyphImageName"] as? String else {
            return
        }
        
        let defaults = UserDefaults.standard
        defaults.set(glyphType, forKey: "glyphType")
        defaults.set(glyphTintColor, forKey: "glyphTintColor")
        
        if (glyphType == "Custom") {
            defaults.set(glyphImageName, forKey: "glyphImageName")
        }
        
        let server = CLKComplicationServer.sharedInstance()
        for complication in server.activeComplications! {
            server.reloadTimeline(for: complication)
        }
    }
    
    func updateEventHandler(fromDictionary eventDictionary : [String : AnyObject], completionPercentage : Int) {
        let didUpdateEvent = loadEvent(fromDictionary: eventDictionary, updateDisplay: true)
        if didUpdateEvent {
            updateTitleLabel(withCompletionPercentage: completionPercentage)
            updateComplications(withCompletionPercentage: completionPercentage)
        }
    }
    
    // MARK: Loading Data
    
    func loadAllData(fromData decoder: NSKeyedUnarchiver, isFullData : Bool) {
        var newActivities = [String]()
        if isFullData || activityOrder.isEmpty {
            activityOrder = decoder.decodeObject(forKey: "activityOrder") as! [String]
        }
        
        let activitiesArray = decoder.decodeObject(forKey: "activities") as! [[String : AnyObject]]
        for activityDictionary in activitiesArray {
            if self.loadActivity(fromDictionary: activityDictionary) {
                newActivities.append(activityDictionary["identifier"] as! String)
            }
        }
        
        let masterEventsArray = decoder.decodeObject(forKey: "events") as! [String : [[String : AnyObject]]]
        for (activityIdentifier, eventActivityGroup) in masterEventsArray {
            if newActivities.contains(activityIdentifier) {
                for eventDictionary in eventActivityGroup {
                    _ = self.loadEvent(fromDictionary: eventDictionary, updateDisplay: false)
                }
            }
        }
        
        for newIdentifier in newActivities {
            if (self.activities[newIdentifier]!.type == .intervention) {
            appendActivityToTable(self.activities[newIdentifier]!)
            }
        }
    }
    
    func loadActivity(fromDictionary activityDictionary: [String : AnyObject]) -> Bool {
        var tintColor : UIColor?
        if activityDictionary["tintColor"] != nil {
            let colorComponents = activityDictionary["tintColor"] as! [CGFloat]
            tintColor = UIColor.init(red: colorComponents[0],
                                     green: colorComponents[1],
                                     blue: colorComponents[2],
                                     alpha: colorComponents[3])
        }
        
        let newActivity = WCKActivity.init(interventionWithIdentifier: activityDictionary["identifier"] as! String,
                                           title: activityDictionary["title"] as! String,
                                           text: activityDictionary["text"] as? String,
                                           isIntervention: activityDictionary["isIntervention"] as? Bool,
                                           tintColor: tintColor,
                                           isOptional: activityDictionary["isOptional"] as? Bool,
                                           numberOfEventsForToday: activityDictionary["numberOfEventsForToday"] as! UInt)
        
        let new = !self.activities.keys.contains(newActivity!.identifier)
        if new {
            self.activities[newActivity!.identifier] = newActivity!
        }
        return new
    }
    
    func loadEvent(fromDictionary eventDictionary: [String : AnyObject], updateDisplay : Bool) -> Bool {
        // Must be called after activity loaded.
        let occurenceIndexOfDay = Int(eventDictionary["occurenceIndexOfDay"] as! UInt)
        let activityIdentifier = eventDictionary["activityIdentifier"] as! String
        var didChange = false
        
        if occurenceIndexOfDay >= 14 {
            NSLog("Only 14 events displayed for a given activity")
            return false
        }
        
        if self.activities[activityIdentifier]?.eventsForToday[Int(occurenceIndexOfDay)] != nil {
            let newState = WCKEventState(rawValue: eventDictionary["state"] as! Int)!
            if self.activities[activityIdentifier]?.eventsForToday[Int(occurenceIndexOfDay)]!.state != newState {
                self.activities[activityIdentifier]?.eventsForToday[Int(occurenceIndexOfDay)]!.state = WCKEventState(rawValue: eventDictionary["state"] as! Int)!
                didChange = true
            }
        } else {
            let newEvent = WCKEvent(occurenceIndexOfDay: occurenceIndexOfDay,
                                    activityIdentifier: activityIdentifier,
                                    state: WCKEventState(rawValue: eventDictionary["state"] as! Int)!)
            self.activities[activityIdentifier]?.eventsForToday[Int(occurenceIndexOfDay)] = newEvent
            didChange = true
        }
        
        if updateDisplay && didChange {
            updateEventButton(forActivityIdentifier: activityIdentifier, eventIndex: Int(occurenceIndexOfDay))
        }
        
        return didChange
    }
}
