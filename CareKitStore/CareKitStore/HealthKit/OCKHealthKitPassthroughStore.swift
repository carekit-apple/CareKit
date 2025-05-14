/*
 Copyright (c) 2016-2025, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3. Neither the name of the copyright holder(s) nor the names of any contributors
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

import CoreData
import Foundation
import HealthKit
import os.log

/// A specialized store that transparently manipulates outcomes in HealthKit.
@available(iOS 15, watchOS 8, macOS 13.0, *)
public final class OCKHealthKitPassthroughStore: OCKEventStore {
    public typealias Task = OCKHealthKitTask
    public typealias Outcome = OCKHealthKitOutcome


    @available(*, unavailable, message: "OCKSynchronizedStoreManager and its related types are no longer available as a mechanism to synchronize with the CareKit store. As a replacement, see the asynchronous streams available directly on a CareKit store. For example, to monitor changes to tasks, see `OCKStore.tasks(query:)`.")
    public weak var outcomeDelegate: OCKOutcomeStoreDelegate? {
        fatalError("Property is unavailable")
    }

    @available(*, unavailable, message: "OCKSynchronizedStoreManager and its related types are no longer available as a mechanism to synchronize with the CareKit store. As a replacement, see the asynchronous streams available directly on a CareKit store. For example, to monitor changes to tasks, see `OCKStore.tasks(query:)`.")
    public var taskDelegate: OCKTaskStoreDelegate? {
        fatalError("Property is unavailable")
    }

    @available(*, unavailable, message: "OCKSynchronizedStoreManager and its related types are no longer available as a mechanism to synchronize with the CareKit store. As a replacement, see the asynchronous streams available directly on a CareKit store. For example, to monitor changes to tasks, see `OCKStore.tasks(query:)`.")
    public var resetDelegate: OCKResetDelegate? {
        fatalError("Property is unavailable")
    }


    let store: OCKStore

    let healthStore = HKHealthStore()

    let proxy: OCKHealthKitProxy

    let workQueue = DispatchQueue(label: "OCKHealthKitPassthroughStore.WorkQueue")

    public init(store: OCKStore) {
        self.store = store
        self.proxy = OCKHealthKitProxy()
    }

    /// Deletes the contents of the store, resetting it to its initial state.
    public func reset() throws {
        try store.reset()
    }

    /// Presents a standard HealthKit permission sheet prompting the user to grant permission for
    /// all data types required to read and write outcomes for the tasks in this store.
    /// - Parameter completion:
    public func requestHealthKitPermissionsForAllTasksInStore(completion: @escaping (Error?) -> Void = { _ in }) {
        do {
            let tasks = try store.fetchHealthKitTasks(query: OCKTaskQuery())
            let quantities = tasks.map { HKQuantityType.quantityType(forIdentifier: $0.healthKitLinkage.quantityIdentifier)! }
            proxy.requestPermissionIfNecessary(writeTypes: Set(quantities)) { error in
                completion(error)
            }
        } catch {
            completion(OCKStoreError.invalidValue(
                reason: "Failed HealthKit permission check: Error: \(error.localizedDescription)"))
        }
    }

    // MARK: - Test seams

    var _now: Date?

    var now: Date {
        return _now ?? Date()
    }
}
