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

import AsyncAlgorithms
import Foundation
import Synchronization

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
public final class OCKStoreCoordinator: OCKAnyStoreProtocol, OCKStoreCoordinatorDelegate {

    struct State {
        weak var delegate: OCKStoreCoordinatorDelegate?
        var readOnlyPatientStores = [OCKAnyReadOnlyPatientStore]()
        var readOnlyPlanStores = [OCKAnyReadOnlyCarePlanStore]()
        var readOnlyContactStores = [OCKAnyReadOnlyContactStore]()
        var readOnlyEventStores = [OCKAnyReadOnlyEventStore]()
        var patientStores = [OCKAnyPatientStore]()
        var planStores = [OCKAnyCarePlanStore]()
        var contactStores = [OCKAnyContactStore]()
        var eventStores = [OCKAnyEventStore]()
    }


    @available(*, unavailable, message: "OCKSynchronizedStoreManager and its related types are no longer available as a mechanism to synchronize with the CareKit store. As a replacement, see the asynchronous streams available directly on a CareKit store. For example, to monitor changes to tasks, see `OCKStore.tasks(query:)`.")
    public weak var patientDelegate: OCKPatientStoreDelegate? {
        fatalError("Property is unavailable")
    }

    @available(*, unavailable, message: "OCKSynchronizedStoreManager and its related types are no longer available as a mechanism to synchronize with the CareKit store. As a replacement, see the asynchronous streams available directly on a CareKit store. For example, to monitor changes to tasks, see `OCKStore.tasks(query:)`.")
    public weak var carePlanDelegate: OCKCarePlanStoreDelegate? {
        fatalError("Property is unavailable")
    }

    @available(*, unavailable, message: "OCKSynchronizedStoreManager and its related types are no longer available as a mechanism to synchronize with the CareKit store. As a replacement, see the asynchronous streams available directly on a CareKit store. For example, to monitor changes to tasks, see `OCKStore.tasks(query:)`.")
    public weak var contactDelegate: OCKContactStoreDelegate? {
        fatalError("Property is unavailable")
    }

    @available(*, unavailable, message: "OCKSynchronizedStoreManager and its related types are no longer available as a mechanism to synchronize with the CareKit store. As a replacement, see the asynchronous streams available directly on a CareKit store. For example, to monitor changes to tasks, see `OCKStore.tasks(query:)`.")
    public weak var taskDelegate: OCKTaskStoreDelegate? {
        fatalError("Property is unavailable")
    }

    @available(*, unavailable, message: "OCKSynchronizedStoreManager and its related types are no longer available as a mechanism to synchronize with the CareKit store. As a replacement, see the asynchronous streams available directly on a CareKit store. For example, to monitor changes to tasks, see `OCKStore.tasks(query:)`.")
    public weak var outcomeDelegate: OCKOutcomeStoreDelegate? {
        fatalError("Property is unavailable")
    }

    @available(*, unavailable, message: "OCKSynchronizedStoreManager and its related types are no longer available as a mechanism to synchronize with the CareKit store. As a replacement, see the asynchronous streams available directly on a CareKit store. For example, to monitor changes to tasks, see `OCKStore.tasks(query:)`.")
    public weak var resetDelegate: OCKResetDelegate? {
        fatalError("Property is unavailable")
    }

    public var delegate: OCKStoreCoordinatorDelegate? {
        get {
            return state.withLock { $0.delegate }
        } set {
            state.withLock { $0.delegate = newValue }
        }
    }

    let state = Mutex(State())


    public init() {
        state.withLock { [weak self] state in
            state.delegate = self
        }
    }

    public func reset() throws {

        try state.withLock { state in

            try state.readOnlyPatientStores.forEach { try $0.reset() }
            try state.readOnlyPlanStores.forEach { try $0.reset() }
            try state.readOnlyContactStores.forEach { try $0.reset() }
            try state.readOnlyEventStores.forEach { try $0.reset() }

            try state.patientStores.forEach { try $0.reset() }
            try state.planStores.forEach { try $0.reset() }
            try state.contactStores.forEach { try $0.reset() }
            try state.eventStores.forEach { try $0.reset() }
        }
    }

    /// Attaches a new store. The new store must be capable of handling reading and writing to all object types.
    ///
    /// - Parameter store: Any store that conforms to `OCKAnyStoreProtocol`.
    /// - Note: The order is which stores are attached is important.
    /// - SeeAlso: `OCKStoreCoordinator`
    public func attach(store: OCKAnyStoreProtocol) {
        state.withLock { state in
            state.patientStores.append(store)
            state.planStores.append(store)
            state.contactStores.append(store)
            state.eventStores.append(store)
        }
    }

    /// Attaches a new store. The new store must be capable of reading and writing patients.
    ///
    /// - Parameter patientStore: Any store that conforms to `OCKAnyPatientStore`.
    /// - Note: The order is which stores are attached is important.
    /// - SeeAlso: `OCKStoreCoordinator`
    public func attach(patientStore: OCKAnyPatientStore) {
        state.withLock { state in
            state.patientStores.append(patientStore)
        }
    }

    /// Attaches a new store. The new store must be capable of reading and writing care plans.
    /// - Parameter planStore: Any store that conforms to `OCKAnyCarePlanStore`.
    /// - Note: The order is which stores are attached is important.
    /// - SeeAlso: `OCKStoreCoordinator`
    public func attach(planStore: OCKAnyCarePlanStore) {
        state.withLock { state in
            state.planStores.append(planStore)
        }
    }

    /// Attaches a new store. The new store must be capable of reading and writing contacts.
    /// - Parameter contactStore: Any store that conforms to `OCKAnyContactStore`.
    /// - Note: The order is which stores are attached is important.
    /// - SeeAlso: `OCKStoreCoordinator`
    public func attach(contactStore: OCKAnyContactStore) {
        state.withLock { state in
            state.contactStores.append(contactStore)
        }
    }

    /// Attaches a new store. The new store must be capable of reading and writing tasks and outcomes.
    /// - Parameter eventStore: Any store that conforms to `OCKAnyEventStore`.
    /// - Note: The order is which stores are attached is important.
    /// - SeeAlso: `OCKStoreCoordinator`
    public func attach(eventStore: OCKAnyEventStore) {
        state.withLock { state in
            state.eventStores.append(eventStore)
        }
    }

    /// Attaches a new store. The new store must be capable of reading patients.
    ///
    /// - Parameter patientStore: Any store that conforms to `OCKAnyReadOnlyPatientStore`.
    /// - Note: The order is which stores are attached is important.
    /// - SeeAlso: `OCKStoreCoordinator`
    public func attachReadOnly(patientStore: OCKAnyReadOnlyPatientStore) {
        state.withLock { state in
            state.readOnlyPatientStores.append(patientStore)
        }
    }

    /// Attaches a new store. The new store must be capable of reading care plans.
    ///
    /// - Parameter carePlanStore: Any store that conforms to `OCKAnyReadOnlyCarePlanStore`.
    /// - Note: The order is which stores are attached is important.
    /// - SeeAlso: `OCKStoreCoordinator`
    public func attachReadOnly(carePlanStore: OCKAnyReadOnlyCarePlanStore) {
        state.withLock { state in
            state.readOnlyPlanStores.append(carePlanStore)
        }
    }

    /// Attaches a new store. The new store must be capable of reading contacts.
    ///
    /// - Parameter contactStore: Any store that conforms to `OCKAnyReadOnlyContactStore`.
    /// - Note: The order is which stores are attached is important.
    /// - SeeAlso: `OCKStoreCoordinator`
    public func attachReadOnly(contactStore: OCKAnyReadOnlyContactStore) {
        state.withLock { state in
            state.readOnlyContactStores.append(contactStore)
        }
    }

    /// Attaches a new store. The new store must be capable of reading events.
    /// 
    /// - Parameter eventStore: Any store that conforms to `OCKAnyReadOnlyEventStore`.
    /// - Note: The order is which stores are attached is important.
    /// - SeeAlso: `OCKStoreCoordinator`
    public func attachReadOnly(eventStore: OCKAnyReadOnlyEventStore) {
        state.withLock { state in
            state.readOnlyEventStores.append(eventStore)
        }
    }

    func combineMany<T: Sendable>(
        sequences: [CareStoreQueryResults<T>],
        makeSortDescriptors: @escaping @Sendable () -> [NSSortDescriptor] // NSSortDescriptor is not sendable, so creating a layer of indirection here
    ) -> CareStoreQueryResults<T> {

        combineMany(sequences: sequences) { combinedValues in

            let nsValues = combinedValues as NSArray
            let sortDescriptors = makeSortDescriptors()

            let sortedValues = nsValues.sortedArray(using: sortDescriptors) as! [T]

            return sortedValues
        }
    }

    func combineMany<T: Sendable>(
        sequences: [CareStoreQueryResults<T>],
        sort: @escaping @Sendable (_ combinedValues: [T]) -> [T]
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
}
