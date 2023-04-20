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

import AsyncAlgorithms
import Foundation

/// `OCKStoreCoordinator` is a special kind of pass through store that forwards to a group of other stores.
/// It has different behavior during **read** and **write** operations.
///
/// When objects are **fetched** from an `OCKStoreCoordinator`, the `OCKStoreCoordinator`
/// will transparently query all of the stores it knows about and return the aggregated results.
///
/// When objects are **added**, **updated**, or **deleted**, a `OCKStoreCoordinator` will attempt to find a single store
/// that can accept responsibility for all the objects that need to be written, and direct the work to that store. If the objects do not all
/// belong to a single store, then the write operation will fail. This is to ensure that write operations are transactional.
///
/// - Note: The order in which stores are registered on an `OCKStoreCoordinator` is important. If two or more stores are
///  capable of writing an object, the one that was registered first will be given precedence.
open class OCKStoreCoordinator: OCKAnyStoreProtocol {

    private (set) var readOnlyPatientStores = [OCKAnyReadOnlyPatientStore]()
    private (set) var readOnlyPlanStores = [OCKAnyReadOnlyCarePlanStore]()
    private (set) var readOnlyContactStores = [OCKAnyReadOnlyContactStore]()
    private (set) var readOnlyEventStores = [OCKAnyReadOnlyEventStore]()

    private (set) var patientStores = [OCKAnyPatientStore]()
    private (set) var planStores = [OCKAnyCarePlanStore]()
    private (set) var contactStores = [OCKAnyContactStore]()
    private (set) var eventStores = [OCKAnyEventStore]()


    @available(*, unavailable, message: "OCKSynchronizedStoreManager and its related types are no longer available as a mechanism to synchronize with the CareKit store. As a replacement, see the asynchronous streams available directly on a CareKit store. For example, to monitor changes to tasks, see `OCKStore.tasks(query:)`.")
    public weak var patientDelegate: OCKPatientStoreDelegate?

    @available(*, unavailable, message: "OCKSynchronizedStoreManager and its related types are no longer available as a mechanism to synchronize with the CareKit store. As a replacement, see the asynchronous streams available directly on a CareKit store. For example, to monitor changes to tasks, see `OCKStore.tasks(query:)`.")
    public weak var carePlanDelegate: OCKCarePlanStoreDelegate?

    @available(*, unavailable, message: "OCKSynchronizedStoreManager and its related types are no longer available as a mechanism to synchronize with the CareKit store. As a replacement, see the asynchronous streams available directly on a CareKit store. For example, to monitor changes to tasks, see `OCKStore.tasks(query:)`.")
    public weak var contactDelegate: OCKContactStoreDelegate?

    @available(*, unavailable, message: "OCKSynchronizedStoreManager and its related types are no longer available as a mechanism to synchronize with the CareKit store. As a replacement, see the asynchronous streams available directly on a CareKit store. For example, to monitor changes to tasks, see `OCKStore.tasks(query:)`.")
    public weak var taskDelegate: OCKTaskStoreDelegate?

    @available(*, unavailable, message: "OCKSynchronizedStoreManager and its related types are no longer available as a mechanism to synchronize with the CareKit store. As a replacement, see the asynchronous streams available directly on a CareKit store. For example, to monitor changes to tasks, see `OCKStore.tasks(query:)`.")
    public weak var outcomeDelegate: OCKOutcomeStoreDelegate?

    @available(*, unavailable, message: "OCKSynchronizedStoreManager and its related types are no longer available as a mechanism to synchronize with the CareKit store. As a replacement, see the asynchronous streams available directly on a CareKit store. For example, to monitor changes to tasks, see `OCKStore.tasks(query:)`.")
    public weak var resetDelegate: OCKResetDelegate?


    public init() {}

    public func reset() throws {
        try readOnlyPatientStores.forEach { try $0.reset() }
        try readOnlyPlanStores.forEach { try $0.reset() }
        try readOnlyContactStores.forEach { try $0.reset() }
        try readOnlyEventStores.forEach { try $0.reset() }

        try patientStores.forEach { try $0.reset() }
        try planStores.forEach { try $0.reset() }
        try contactStores.forEach { try $0.reset() }
        try eventStores.forEach { try $0.reset() }
    }

    /// Attaches a new store. The new store must be capable of handling reading and writing to all object types.
    ///
    /// - Parameter store: Any store that conforms to `OCKAnyStoreProtocol`.
    /// - Note: The order is which stores are attached is important.
    /// - SeeAlso: `OCKStoreCoordinator`
    open func attach(store: OCKAnyStoreProtocol) {
        attach(patientStore: store)
        attach(planStore: store)
        attach(contactStore: store)
        attach(eventStore: store)
    }

    /// Attaches a new store. The new store must be capable of reading and writing patients.
    ///
    /// - Parameter patientStore: Any store that conforms to `OCKAnyPatientStore`.
    /// - Note: The order is which stores are attached is important.
    /// - SeeAlso: `OCKStoreCoordinator`
    open func attach(patientStore: OCKAnyPatientStore) {
        patientStores.append(patientStore)
    }

    /// Attaches a new store. The new store must be capable of reading and writing care plans.
    /// - Parameter planStore: Any store that conforms to `OCKAnyCarePlanStore`.
    /// - Note: The order is which stores are attached is important.
    /// - SeeAlso: `OCKStoreCoordinator`
    open func attach(planStore: OCKAnyCarePlanStore) {
        planStores.append(planStore)
    }

    /// Attaches a new store. The new store must be capable of reading and writing contacts.
    /// - Parameter contactStore: Any store that conforms to `OCKAnyContactStore`.
    /// - Note: The order is which stores are attached is important.
    /// - SeeAlso: `OCKStoreCoordinator`
    open func attach(contactStore: OCKAnyContactStore) {
        contactStores.append(contactStore)
    }

    /// Attaches a new store. The new store must be capable of reading and writing tasks and outcomes.
    /// - Parameter eventStore: Any store that conforms to `OCKAnyEventStore`.
    /// - Note: The order is which stores are attached is important.
    /// - SeeAlso: `OCKStoreCoordinator`
    open func attach(eventStore: OCKAnyEventStore) {
        eventStores.append(eventStore)
    }

    /// Attaches a new store. The new store must be capable of reading patients.
    ///
    /// - Parameter patientStore: Any store that conforms to `OCKAnyReadOnlyPatientStore`.
    /// - Note: The order is which stores are attached is important.
    /// - SeeAlso: `OCKStoreCoordinator`
    open func attachReadOnly(patientStore: OCKAnyReadOnlyPatientStore) {
        readOnlyPatientStores.append(patientStore)
    }

    /// Attaches a new store. The new store must be capable of reading care plans.
    ///
    /// - Parameter carePlanStore: Any store that conforms to `OCKAnyReadOnlyCarePlanStore`.
    /// - Note: The order is which stores are attached is important.
    /// - SeeAlso: `OCKStoreCoordinator`
    open func attachReadOnly(carePlanStore: OCKAnyReadOnlyCarePlanStore) {
        readOnlyPlanStores.append(carePlanStore)
    }

    /// Attaches a new store. The new store must be capable of reading contacts.
    ///
    /// - Parameter contactStore: Any store that conforms to `OCKAnyReadOnlyContactStore`.
    /// - Note: The order is which stores are attached is important.
    /// - SeeAlso: `OCKStoreCoordinator`
    open func attachReadOnly(contactStore: OCKAnyReadOnlyContactStore) {
        readOnlyContactStores.append(contactStore)
    }

    /// Attaches a new store. The new store must be capable of reading events.
    /// 
    /// - Parameter eventStore: Any store that conforms to `OCKAnyReadOnlyEventStore`.
    /// - Note: The order is which stores are attached is important.
    /// - SeeAlso: `OCKStoreCoordinator`
    open func attachReadOnly(eventStore: OCKAnyReadOnlyEventStore) {
        readOnlyEventStores.append(eventStore)
    }

    func combineMany<T>(
        sequences: [CareStoreQueryResults<T>],
        sortingElementsUsing sortDescriptors: [NSSortDescriptor]
    ) -> CareStoreQueryResults<T> {

        combineMany(sequences: sequences) { combinedValues in

            let nsValues = combinedValues as NSArray

            let sortedValues = nsValues.sortedArray(using: sortDescriptors) as! [T]

            return sortedValues
        }
    }

    func combineMany<T>(
        sequences: [CareStoreQueryResults<T>],
        sort: @escaping (_ combinedValues: [T]) -> [T]
    ) -> CareStoreQueryResults<T> {

        // If there are no streams to merge, return an empty stream
        guard sequences.isEmpty == false else {

            let emptyResult = AsyncStream<[T]> { nil }
            let wrappedEmptyResult = CareStoreQueryResults(wrapping: emptyResult)
            return wrappedEmptyResult
        }

        // Combine each stream into one another one by one. The result is a single combined
        // stream hat has been built up like a Russian doll. At the moment we have to combine
        // many streams like this because there is no async algorithm to combine a dynamic
        // number of async sequences.
        //
        // Combining is preferred over merging here. Merging will produce results that
        // trickle through the stream one at a time. By instead combining the results,
        // a single combined result is sent through the stream.

        // Create a stream that outputs a single empty result
        let initialResults: AsyncSyncSequence<[[T]]> = [[]].async
        let wrappedInitialResults = CareStoreQueryResults(wrapping: initialResults)

        let combinedResults = sequences.reduce(wrappedInitialResults) { partiallyCombinedResults, nextResults in

            // Combine the result from both streams
            let combinedResults = combineLatest(partiallyCombinedResults, nextResults)

            // Merge the combined result from each of the two streams into a single result
            let mergedResults = combinedResults.map { resultA, resultB -> [T] in
                let mergedResult = resultA + resultB
                return mergedResult
            }

            // Wrap the merged result to simplify the stream type
            let wrappedMergedResults = CareStoreQueryResults(wrapping: mergedResults)
            return wrappedMergedResults
        }

        // Sort the final combined result
        let sortedResults = combinedResults.map { sort($0) }

        let wrappedSortedResults = CareStoreQueryResults(wrapping: sortedResults)
        return wrappedSortedResults
    }

    // MARK: Handler Routing

    /// Determines whether or not a store is intended to handle a given query. If true is returned, the persistent store coordinator
    /// will execute the query against the store and include the result together with results from any other stores that also respond
    /// to this query.
    ///
    /// - Parameter store: A candidate store that should or should not handle the query.
    /// - Parameter query: The query that is about to be executed.
    open func patientStore(_ store: OCKAnyReadOnlyPatientStore, shouldHandleQuery query: OCKPatientQuery) -> Bool {
        true
    }

    /// Determines whether or not a store is intended to handle a certain write operation. The persistent store coordinator will call this method
    /// against all its stores in the order they were registered and execute the write on the first store that returns true for this method.
    ///
    /// - Parameters:
    ///   - store: A candidate store that should or should not handle writing.
    ///   - patient: The patient that needs to be written.
    open func patientStore(_ store: OCKAnyPatientStore, shouldHandleWritingPatient patient: OCKAnyPatient) -> Bool {
        true
    }

    /// Determines whether or not a store is intended to handle a given query. If true is returned, the persistent store coordinator
    /// will execute the query against the store and include the result together with results from any other stores that also respond
    /// to this query.
    ///
    /// - Parameter store: A candidate store that should or should not handle the query.
    /// - Parameter query: The query that is about to be executed.
    open func carePlanStore(_ store: OCKAnyReadOnlyCarePlanStore, shouldHandleQuery query: OCKCarePlanQuery) -> Bool {
        true
    }

    /// Determines whether or not a store is intended to handle a certain write operation. The persistent store coordinator will call this method
    /// against all its stores in the order they were registered and execute the write on the first store that returns true for this method.
    ///
    /// - Parameters:
    ///   - store: A candidate store that should or should not handle writing.
    ///   - plan: The plan that needs to be written.
    open func carePlanStore(_ store: OCKAnyCarePlanStore, shouldHandleWritingCarePlan plan: OCKAnyCarePlan) -> Bool {
        true
    }

    /// Determines whether or not a store is intended to handle a given query. If true is returned, the persistent store coordinator
    /// will execute the query against the store and include the result together with results from any other stores that also respond
    /// to this query.
    ///
    /// - Parameter store: A candidate store that should or should not handle the query.
    /// - Parameter query: The query that is about to be executed.
    open func contactStore(_ store: OCKAnyReadOnlyContactStore, shouldHandleQuery query: OCKContactQuery) -> Bool {
        true
    }

    /// Determines whether or not a store is intended to handle a certain write operation. The persistent store coordinator will call this method
    /// against all its stores in the order they were registered and execute the write on the first store that returns true for this method.
    ///
    /// - Parameters:
    ///   - store: A candidate store that should or should not handle writing.
    ///   - contact: The contact that needs to be written.
    open func contactStore(_ store: OCKAnyReadOnlyContactStore, shouldHandleWritingContact contact: OCKAnyContact) -> Bool {
        return true
    }

    /// Determines whether or not a store is intended to handle a given query. If true is returned, the persistent store coordinator
    /// will execute the query against the store and include the result together with results from any other stores that also respond
    /// to this query.
    ///
    /// - Parameter store: A candidate store that should or should not handle the query.
    /// - Parameter query: The query that is about to be executed.
    open func taskStore(_ store: OCKAnyReadOnlyTaskStore, shouldHandleQuery query: OCKTaskQuery) -> Bool {
        true
    }

    /// Determines whether or not a store is intended to handle a certain write operation. The persistent store coordinator will call this method
    /// against all its stores in the order they were registered and execute the write on the first store that returns true for this method.
    ///
    /// - Parameters:
    ///   - store: A candidate store that should or should not handle writing.
    ///   - task: The task that needs to be written.
    open func taskStore(_ store: OCKAnyReadOnlyTaskStore, shouldHandleWritingTask task: OCKAnyTask) -> Bool {

        #if os(iOS)
        if #available(iOS 15, watchOS 8, *) {

            // HealthKit stores should only respond to HealthKit tasks
            if store is OCKHealthKitPassthroughStore && !(task is OCKHealthKitTask) { return false }
        }
        #endif

        // OCKStore should not respond to HealthKit tasks
        #if os(iOS)
        if store is OCKStore && task is OCKHealthKitTask { return false }
        #endif

        return true
    }

    /// Determines whether or not a store is intended to handle a given query. If true is returned, the persistent store coordinator
    /// will execute the query against the store and include the result together with results from any other stores that also respond
    /// to this query.
    ///
    /// - Parameter store: A candidate store that should or should not handle the query.
    /// - Parameter query: The query that is about to be executed.
    open func outcomeStore(_ store: OCKAnyReadOnlyOutcomeStore, shouldHandleQuery query: OCKOutcomeQuery) -> Bool {
        true
    }

    /// Determines whether or not a store is intended to handle a certain write operation. The persistent store coordinator will call this method
    /// against all its stores in the order they were registered and execute the write on the first store that returns true for this method.
    ///
    /// - Parameters:
    ///   - store: A candidate store that should or should not handle writing.
    ///   - outcome: The outcome that needs to be written.
    open func outcomeStore(_ store: OCKAnyReadOnlyOutcomeStore, shouldHandleWritingOutcome outcome: OCKAnyOutcome) -> Bool {

        #if os(iOS)
        if #available(iOS 15, watchOS 8, *) {
            // Only the HK passthrough store should handle HK outcomes
            if outcome is OCKHealthKitOutcome || store is OCKHealthKitPassthroughStore {
                return store is OCKHealthKitPassthroughStore && outcome is OCKHealthKitOutcome
            }
        }
        #endif
        return true
    }
}
