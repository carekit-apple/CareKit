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

class QueryActivityEventsOperation: Operation {
    // MARK: Properties
    
    fileprivate let store: OCKCarePlanStore
    
    fileprivate let activityIdentifier: String
    
    fileprivate let startDate: DateComponents
    
    fileprivate let endDate: DateComponents
    
    fileprivate(set) var dailyEvents: DailyEvents?
    
    // MARK: Initialization
    
    init(store: OCKCarePlanStore, activityIdentifier: String, startDate: DateComponents, endDate: DateComponents) {
        self.store = store
        self.activityIdentifier = activityIdentifier
        self.startDate = startDate
        self.endDate = endDate
    }
    
    // MARK: NSOperation
    
    override func main() {
        // Do nothing if the operation has been cancelled.
        guard !isCancelled else { return }
        
        // Find the activity with the specified identifier in the store.
        guard let activity = findActivity() else { return }

        /*
            Create a semaphore to wait for the asynchronous call to `enumerateEventsOfActivity`
            to complete.
        */
        let semaphore = DispatchSemaphore(value: 0)

        // Query for events for the activity between the requested dates.
        self.dailyEvents = DailyEvents()

        DispatchQueue.main.async {
            self.store.enumerateEvents(of: activity, startDate: self.startDate as DateComponents, endDate: self.endDate as DateComponents, handler: { event, _ in
                if let event = event {
                    self.dailyEvents?[event.date].append(event)
                }
            }, completion: { _, _ in
                // Use the semaphore to signal that the query is complete.
                semaphore.signal()
            })
        }
        
        // Wait for the semaphore to be signalled.
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    }
    
    // MARK: Convenience
    
    fileprivate func findActivity() -> OCKCarePlanActivity? {
        /*
             Create a semaphore to wait for the asynchronous call to `activityForIdentifier`
             to complete.
         */
        let semaphore = DispatchSemaphore(value: 0)
        
        var activity: OCKCarePlanActivity?
        
        store.activity(forIdentifier: activityIdentifier) { success, foundActivity, error in
            activity = foundActivity
            if !success {
                print(error?.localizedDescription as Any)
            }
            
            // Use the semaphore to signal that the query is complete.
            semaphore.signal()
        }
        
        // Wait for the semaphore to be signalled.
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        
        return activity
    }
}



struct DailyEvents {
    // MARK: Properties
    
    fileprivate var mappedEvents: [DateComponents: [OCKCarePlanEvent]]
    
    var allEvents: [OCKCarePlanEvent] {
        return Array(mappedEvents.values.joined())
    }
    
    var allDays: [DateComponents] {
        return Array(mappedEvents.keys)
    }
    
    subscript(day: DateComponents) -> [OCKCarePlanEvent] {
        get {
            if let events = mappedEvents[day] {
                return events
            }
            else {
                return []
            }
        }
        
        set(newValue) {
            mappedEvents[day] = newValue
        }
    }
    
    // MARK: Initialization
    
    init() {
        mappedEvents = [:]
    }
}
