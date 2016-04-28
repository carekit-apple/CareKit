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

class CarePlanStoreManager: NSObject {
    // MARK: Static Properties
    
    static var sharedCarePlanStoreManager = CarePlanStoreManager()
    
    // MARK: Properties
    
    weak var delegate: CarePlanStoreManagerDelegate?
    
    let store: OCKCarePlanStore
    
    var insights: [OCKInsightItem] {
        return insightsBuilder.insights
    }
    
    private let insightsBuilder: InsightsBuilder

    // MARK: Initialization
    
    private override init() {
        // Determine the file URL for the store.
        let searchPaths = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true)
        let applicationSupportPath = searchPaths[0]
        let persistenceDirectoryURL = NSURL(fileURLWithPath: applicationSupportPath)
        
        if !NSFileManager.defaultManager().fileExistsAtPath(persistenceDirectoryURL.absoluteString, isDirectory: nil) {
            try! NSFileManager.defaultManager().createDirectoryAtURL(persistenceDirectoryURL, withIntermediateDirectories: true, attributes: nil)
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
            guard let storeManager = self, newInsights = newInsights where completed else { return }
            storeManager.delegate?.carePlanStoreManager(storeManager, didUpdateInsights: newInsights)
        }
    }
}



extension CarePlanStoreManager: OCKCarePlanStoreDelegate {
    func carePlanStoreActivityListDidChange(store: OCKCarePlanStore) {
        updateInsights()
    }
    
    func carePlanStore(store: OCKCarePlanStore, didReceiveUpdateOfEvent event: OCKCarePlanEvent) {
        updateInsights()
    }
}



protocol CarePlanStoreManagerDelegate: class {
    
    func carePlanStoreManager(manager: CarePlanStoreManager, didUpdateInsights insights: [OCKInsightItem])
    
}