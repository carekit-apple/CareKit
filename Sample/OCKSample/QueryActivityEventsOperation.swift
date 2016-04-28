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

class QueryActivityEventsOperation: NSOperation {
    // MARK: Properties
    
    private let store: OCKCarePlanStore
    
    private let activityIdentifier: String
    
    private let startDate: NSDateComponents
    
    private let endDate: NSDateComponents
    
    private(set) var dailyEvents: DailyEvents?
    
    // MARK: Initialization
    
    init(store: OCKCarePlanStore, activityIdentifier: String, startDate: NSDateComponents, endDate: NSDateComponents) {
        self.store = store
        self.activityIdentifier = activityIdentifier
        self.startDate = startDate
        self.endDate = endDate
    }
    
    // MARK: NSOperation
    
    override func main() {
        // Do nothing if the operation has been cancelled.
        guard !cancelled else { return }
        
        // Find the activity with the specified identifier in the store.
        guard let activity = findActivity() else { return }

        /*
            Create a semaphore to wait for the asynchronous call to `enumerateEventsOfActivity`
            to complete.
        */
        let semaphore = dispatch_semaphore_create(0)

        // Query for events for the activity between the requested dates.
        self.dailyEvents = DailyEvents()
        
        dispatch_async(dispatch_get_main_queue()) { // <rdar://problem/25528295> [CK] OCKCarePlanStore query methods crash if not called on the main thread
            self.store.enumerateEventsOfActivity(activity, startDate: self.startDate, endDate: self.endDate, handler: { event, _ in
                if let event = event {
                    self.dailyEvents?[event.date].append(event)
                }
            }, completion: { _, _ in
                // Use the semaphore to signal that the query is complete.
                dispatch_semaphore_signal(semaphore)
            })
        }
        
        // Wait for the semaphore to be signalled.
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }
    
    // MARK: Convenience
    
    private func findActivity() -> OCKCarePlanActivity? {
        /*
             Create a semaphore to wait for the asynchronous call to `activityForIdentifier`
             to complete.
         */
        let semaphore = dispatch_semaphore_create(0)
        
        var activity: OCKCarePlanActivity?
        
        dispatch_async(dispatch_get_main_queue()) { // <rdar://problem/25528295> [CK] OCKCarePlanStore query methods crash if not called on the main thread
            self.store.activityForIdentifier(self.activityIdentifier) { success, foundActivity, error in
                activity = foundActivity
                if !success {
                    print(error?.localizedDescription)
                }
                
                // Use the semaphore to signal that the query is complete.
                dispatch_semaphore_signal(semaphore)
            }
        }
        
        // Wait for the semaphore to be signalled.
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        
        return activity
    }
}



struct DailyEvents {
    // MARK: Properties
    
    private var mappedEvents: [NSDateComponents: [OCKCarePlanEvent]]
    
    var allEvents: [OCKCarePlanEvent] {
        return Array(mappedEvents.values.flatten())
    }
    
    var allDays: [NSDateComponents] {
        return Array(mappedEvents.keys)
    }
    
    subscript(day: NSDateComponents) -> [OCKCarePlanEvent] {
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
