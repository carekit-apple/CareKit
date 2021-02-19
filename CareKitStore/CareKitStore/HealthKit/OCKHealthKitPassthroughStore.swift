/*
 Copyright (c) 2019, Apple Inc. All rights reserved.
 
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
#if os(iOS)

import CoreData
import Foundation
import HealthKit
import os.log

/// A specialized store that transparently manipulates outcomes in HealthKit.
public final class OCKHealthKitPassthroughStore: OCKEventStore {
    public typealias Task = OCKHealthKitTask
    public typealias Outcome = OCKHealthKitOutcome

    public weak var outcomeDelegate: OCKOutcomeStoreDelegate?

    public var taskDelegate: OCKTaskStoreDelegate? {
        get { store.taskDelegate }
        set { store.taskDelegate = newValue }
    }

    public var resetDelegate: OCKResetDelegate? {
        get { store.resetDelegate }
        set { store.resetDelegate = newValue }
    }

    let store: OCKStore

    let healthStore = HKHealthStore()

    let proxy: OCKHealthKitProxy

    public init(store: OCKStore) {
        self.store = store
        self.proxy = OCKHealthKitProxy()
        beginObservingAllTasks()
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

    deinit {
        stopObservingAllTasks()
    }

    // MARK: Observing
    private var activeObserverQueries: [HKSampleType: HKObserverQuery] = [:]

    internal func startObservingHealthKit(task: OCKHealthKitTask) {
        let sampleType = HKSampleType.quantityType(forIdentifier: task.healthKitLinkage.quantityIdentifier)!
        guard !activeObserverQueries.keys.contains(sampleType) else { return }

        let observationStartDate = Date()
        let predicate = HKQuery.predicateForSamples(withStart: observationStartDate, end: nil, options: .strictStartDate)
        let updateHandler = makeObserverQueryHandler(task: task, predicate: predicate)
        let query = HKObserverQuery(sampleType: sampleType, predicate: predicate, updateHandler: updateHandler)

        activeObserverQueries[sampleType] = query
        healthStore.execute(query)
    }

    internal func stopObservingHealthKit(task: OCKHealthKitTask) {
        guard
            let sampleType = HKSampleType.quantityType(forIdentifier: task.healthKitLinkage.quantityIdentifier),
            let query = activeObserverQueries[sampleType]
        else { // No query was running to begin with
            return
        }
        healthStore.stop(query)
        activeObserverQueries[sampleType] = nil
    }

    private func beginObservingAllTasks() {
        do {
            let allTasks = try store.fetchHealthKitTasks(query: OCKTaskQuery())
            let group = DispatchGroup()
            var observeError: Error?

            for task in allTasks {
                group.enter()
                let sampleType = HKSampleType.quantityType(forIdentifier: task.healthKitLinkage.quantityIdentifier)!
                healthStore.enableBackgroundDelivery(for: sampleType, frequency: .immediate) { _, error in
                    if let error = error {
                        observeError = error
                    }
                    group.leave()
                }

                group.notify(queue: .main) { [weak self] in
                    if let error = observeError {
                        os_log("Failed to enable background delivery. %{private}@",
                               log: .store, type: .error, error.localizedDescription)
                        return
                    }

                    allTasks.forEach { self?.startObservingHealthKit(task: $0) }
                }
            }
        } catch {
            os_log("Failed to observe HealthKit. %{private}@",
                   log: .store, type: .error, error.localizedDescription)
        }
    }

    private func stopObservingAllTasks() {
        healthStore.disableAllBackgroundDelivery { _, error in
            if let error = error {
                os_log("Failed to stop observing some HealthKit types. %{private}@",
                       log: .store, type: .error, error.localizedDescription)
            }
        }
    }

    private typealias ObserverQueryHandler = (HKObserverQuery, @escaping HKObserverQueryCompletionHandler, Error?) -> Void

    private func makeObserverQueryHandler(task: OCKHealthKitTask, predicate: NSPredicate) -> ObserverQueryHandler {
        return { [weak self] _, backgroundCompletionHandler, error in
            let sampleType = HKSampleType.quantityType(forIdentifier: task.healthKitLinkage.quantityIdentifier)!

            if let error = error {
                backgroundCompletionHandler()
                os_log("Failed to observe HealthKit sample type. %{private}@",
                       log: .store, type: .error, error.localizedDescription)
                return
            }

            // The observer query does not provide enough context to know what changed, only that something did. We must follow up with an
            // anchored query to get an array of samples that have been modified.
            var anchor: HKQueryAnchor?
            let anchorQuery = HKAnchoredObjectQuery(
                type: sampleType,
                predicate: predicate,
                anchor: anchor,
                limit: HKObjectQueryNoLimit) { [weak self] _, additions, deletions, queryAnchor, error in

                if let error = error {
                    backgroundCompletionHandler()
                    os_log("Failed to fetch HealthKit sample type. %{private}@",
                           log: .store, type: .error, error.localizedDescription)
                    return
                }

                // Update the anchor so that the same results aren't returned the next time we query
                anchor = queryAnchor

                // HealthKit doesn't provide a way to know the date of deleted samples, so we just tell the
                // delegate that something unknown happened.
                //
                // If performance becomes a concern, we could create a lookup table that maps
                // HKSample's UUID to outcomes and use that to do more targeted invalidations.
                if let deletedSamples = deletions, !deletedSamples.isEmpty {
                    if let store = self, let delegate = store.outcomeDelegate {
                        delegate.outcomeStore(store, didEncounterUnknownChange: "HKStore deleted \(deletedSamples)")
                    }
                    backgroundCompletionHandler()
                    return
                }

                guard let samples = additions, !samples.isEmpty else {
                    // There are some cases when the anchor query fires but both additions and deletions are empty.
                    // This can happen when healthd restarts and should not be considered an error. It might be safe
                    // to assume that nothing has changed, but to be safe we alert the delegate anyway. There may be
                    // an optimization hiding in here as well, but we're erring on the side of caution to make sure
                    // no updates are missed.
                    if let store = self, let delegate = store.outcomeDelegate {
                        delegate.outcomeStore(store, didEncounterUnknownChange: "HKStore untracked modification")
                    }
                    backgroundCompletionHandler()
                    return
                }

                self?.handleHealthKitDataCreatedOrUpdated(task: task, samples: samples) { result in
                    switch result {
                    case .failure(let error):
                        os_log("Failed to handle HealthKit update. %{private}@",
                               log: .store, type: .error, error.localizedDescription)
                    case .success: break
                    }
                    backgroundCompletionHandler()
                }
            }
            self?.healthStore.execute(anchorQuery)
        }
    }

    // For each sample we need to fetch definition of the task that is valid when the sample was recorded.
    // We then attempt to determine if the sample lines up with any events for that version of the task's schedule.
    private func handleHealthKitDataCreatedOrUpdated(task: OCKHealthKitTask, samples: [HKSample], completion: @escaping OCKResultClosure<Void>) {
        let group = DispatchGroup()
        var fetchError: OCKStoreError?

        for sample in samples {
            var taskQuery = OCKTaskQuery(dateInterval: DateInterval(start: sample.startDate, end: sample.endDate))
            taskQuery.ids = [task.id]

            group.enter()
            fetchTasks(query: taskQuery, callbackQueue: .main) { result in
                switch result {
                case .failure(let error):
                    fetchError = error
                    group.leave()
                case .success(let tasks):
                    guard
                        let task = tasks.first,
                        let event = task.schedule.events(from: sample.startDate, to: sample.endDate).first
                    else {
                        group.leave()
                        return
                    }

                    self.fetchEvent(forTask: task, occurrence: event.occurrence) { [weak self] result in
                        switch result {
                        case .failure(let error):
                            fetchError = error
                            group.leave()
                        case .success(let event):
                            guard
                                let store = self,
                                let delegate = store.outcomeDelegate,
                                let outcome = event.outcome
                            else {
                                group.leave()
                                return
                            }

                            delegate.outcomeStore(store, didAddOutcomes: [outcome])
                            group.leave()
                        }
                    }
                }
            }
        }

        group.notify(queue: .main) {
            if let error = fetchError {
                completion(.failure(error))
            }
            completion(.success(()))
        }
    }
}
#endif
