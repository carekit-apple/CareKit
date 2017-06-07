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

class CarePlanStoreManager: NSObject {
    // MARK: Static Properties
    
    static var sharedCarePlanStoreManager = CarePlanStoreManager()
    
    // MARK: Properties
    
    weak var delegate: CarePlanStoreManagerDelegate?
    
    let store: OCKCarePlanStore
    
    var insights: [OCKInsightItem] {
        return insightsBuilder.insights
    }
    
    fileprivate let insightsBuilder: InsightsBuilder

    // MARK: Initialization
    
    fileprivate override init() {
        // Determine the file URL for the store.
        let searchPaths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        let applicationSupportPath = searchPaths[0]
        let persistenceDirectoryURL = URL(fileURLWithPath: applicationSupportPath)
        
        if !FileManager.default.fileExists(atPath: persistenceDirectoryURL.absoluteString, isDirectory: nil) {
            try! FileManager.default.createDirectory(at: persistenceDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        // Create the store.
        store = OCKCarePlanStore(persistenceDirectoryURL: persistenceDirectoryURL)
        
        /*
            Create an `InsightsBuilder` to build insights based on the data in
            the store.
        */
        insightsBuilder = InsightsBuilder(carePlanStore: store)
        
        super.init()

        // Register this object as the store's delegate to be notified of changes.
        store.delegate = self
        
        // Start to build the initial array of insights.
        updateInsights()
    }
    
    
    func updateInsights() {
        insightsBuilder.updateInsights { [weak self] completed, newInsights in
            // If new insights have been created, notifiy the delegate.
            guard let storeManager = self, let newInsights = newInsights , completed else { return }
            storeManager.delegate?.carePlanStoreManager(storeManager, didUpdateInsights: newInsights)
        }
    }
}


extension CarePlanStoreManager: OCKCarePlanStoreDelegate {
    func carePlanStoreActivityListDidChange(_ store: OCKCarePlanStore) {
        updateInsights()
    }
    
    func carePlanStore(_ store: OCKCarePlanStore, didReceiveUpdateOf event: OCKCarePlanEvent) {
        updateInsights()
        
        let triggeredThresholds = event.evaluateNumericThresholds()
        if triggeredThresholds.count != 0 {
            for thresholdArray in triggeredThresholds {
                for threshold in thresholdArray {
                    NSLog("Threshold triggered on event \(event.occurrenceIndexOfDay) of \(event.date) for activity \(event.activity.identifier) with title:\n\(threshold.title!)")
                }
            }
        }
        
    }
}


protocol CarePlanStoreManagerDelegate: class {
    
    func carePlanStoreManager(_ manager: CarePlanStoreManager, didUpdateInsights insights: [OCKInsightItem])
    
}
