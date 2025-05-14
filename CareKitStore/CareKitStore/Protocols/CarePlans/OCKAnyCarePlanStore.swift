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

import Foundation

/// A store that allows for reading care plans.
public protocol OCKAnyReadOnlyCarePlanStore: OCKAnyResettableStore {

    /// A continuous stream of care plans that exist in the store.
    ///
    /// The stream yields a new value whenever the result changes, and yields an error if there's an issue
    /// accessing the store or fetching results.
    ///
    /// Supply a query that'll be used to match care plans in the store. If the query doesn't contain a date
    /// interval, the result contains every version of a care plan. Multiple versions of the same care plan
    /// have the same ``OCKAnyCarePlan/id`` but a different UUID. If the query does contain a date
    /// interval, the result contains the newest version of a care plan that exists in the interval.
    ///
    /// - Parameter query: Used to match care plans in the store.
    func anyCarePlans(matching query: OCKCarePlanQuery) -> CareStoreQueryResults<OCKAnyCarePlan>

    /// A continuous stream of care plans that exist in the store. The stream yields a new value whenever
    /// the result changes and yields an error if there's an issue accessing the store or fetching results.
    ///
    /// Supply a query that'll be used to match care plans in the store. If the query doesn't contain a date
    /// interval, the result contains every version of a care plan. Multiple versions of the same care plan
    /// have the same ``OCKAnyCarePlan/id`` but a different UUID. If the query does contain a date
    /// interval, the result contains the newest version of a care plan that exists in the interval.
    ///
    ///
    /// - Parameters:
    ///   - query: A query that constrains care plans the method fetches.
    ///   - callbackQueue: The queue that the method calls the completion closure on. In most cases this is the main queue.
    ///   - completion: A callback that executes on the provided callback queue.
    func fetchAnyCarePlans(query: OCKCarePlanQuery, callbackQueue: DispatchQueue,
                           completion: @escaping OCKResultClosure<[OCKAnyCarePlan]>)

    // MARK: Singular Methods - Implementation Provided

    /// Asynchronously retrieves a single care plan from the store.
    ///
    /// - Parameters:
    ///   - id: The identifier of the fetched item.
    ///   - callbackQueue: The queue that the method calls the completion closure on. In most cases this is the main queue.
    ///   - completion: A callback that executes on the provided callback queue.
    func fetchAnyCarePlan(withID id: String, callbackQueue: DispatchQueue, completion: @escaping OCKResultClosure<OCKAnyCarePlan>)

}

/// A protocol that enforces conformance to a care plan store.
///
/// Any store that can write to one more types conforming to `OCKAnyCarePlan` is considered an `OCKAnyCarePlanStore`.
public protocol OCKAnyCarePlanStore: OCKAnyReadOnlyCarePlanStore {

    /// Asynchronously adds an array of care plans to the store.
    ///
    /// - Parameters:
    ///   - plans: An array of plans to add to the store.
    ///   - callbackQueue: The queue that the method calls the completion closure on. In most cases this is the main queue.
    ///   - completion: A callback that executes on the provided callback queue.
    func addAnyCarePlans(_ plans: [OCKAnyCarePlan], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyCarePlan]>?)

    /// Asynchronously updates an array of care plans in the store.
    ///
    /// - Parameters:
    ///   - plans: An array of care plans to update in the store. The care plans must already exist in the store.
    ///   - callbackQueue: The queue that the method calls the completion closure on. In most cases this is the main queue.
    ///   - completion: A callback that executes on the provided callback queue.
    func updateAnyCarePlans(_ plans: [OCKAnyCarePlan], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyCarePlan]>?)

    /// Asynchronously deletes an array of care plans from the store.
    ///
    /// - Parameters:
    ///   - plans: An array of care plans to delete. The care plans must exist in the store.
    ///   - callbackQueue: The queue that the method calls the completion closure on. In most cases this is the main queue.
    ///   - completion: A callback that executes on the provided callback queue.
    func deleteAnyCarePlans(_ plans: [OCKAnyCarePlan], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyCarePlan]>?)

    // MARK: Singular Methods - Implementation Provided

    /// Asynchronously adds a single care plan to the store.
    ///
    /// - Parameters:
    ///   - plan: A single plan to add to the store.
    ///   - callbackQueue: The queue that the method calls the completion closure on. In most cases this is the main queue.
    ///   - completion: A callback that executes on the provided callback queue.
    func addAnyCarePlan(_ plan: OCKAnyCarePlan, callbackQueue: DispatchQueue, completion: OCKResultClosure<OCKAnyCarePlan>?)

    /// Asynchronously updates a single care plan in the store.
    ///
    /// - Parameters:
    ///   - plan: A single care plan to update. The care plans must already exist in the store.
    ///   - callbackQueue: The queue that the method calls the completion closure on. In most cases this is the main queue.
    ///   - completion: A callback that executes on the provided callback queue.
    func updateAnyCarePlan(_ plan: OCKAnyCarePlan, callbackQueue: DispatchQueue, completion: OCKResultClosure<OCKAnyCarePlan>?)

    /// Asynchronously deletes a single care plan from the store.
    ///
    /// - Parameters:
    ///   - plan: A single care plan to delete. The care plans must exist in the store.
    ///   - callbackQueue: The queue that the method calls the completion closure on. In most cases this is the main queue.
    ///   - completion: A callback that executes on the provided callback queue.
    func deleteAnyCarePlan(_ plan: OCKAnyCarePlan, callbackQueue: DispatchQueue, completion: OCKResultClosure<OCKAnyCarePlan>?)
}

// MARK: Singular Methods for OCKAnyReadOnlyCarePlanStore

public extension OCKAnyReadOnlyCarePlanStore {
    func fetchAnyCarePlan(withID id: String, callbackQueue: DispatchQueue = .main,
                          completion: @escaping OCKResultClosure<OCKAnyCarePlan>) {
        var query = OCKCarePlanQuery(for: Date())
        query.limit = 1
        query.sortDescriptors = [.effectiveDate(ascending: false)]
        query.ids = [id]

        fetchAnyCarePlans(query: query, callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .fetchFailed(reason: "No care plan with matching ID")))
    }
}

// MARK: Singular Methods for OCKAnyCarePlanStore

public extension OCKAnyCarePlanStore {
    func addAnyCarePlan(_ plan: OCKAnyCarePlan, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<OCKAnyCarePlan>? = nil) {
        addAnyCarePlans([plan], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .addFailed(reason: "Failed to add care plan")))
    }

    func updateAnyCarePlan(_ plan: OCKAnyCarePlan, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<OCKAnyCarePlan>? = nil) {
        updateAnyCarePlans([plan], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .updateFailed(reason: "Failed to update care plan")))
    }

    func deleteAnyCarePlan(_ plan: OCKAnyCarePlan, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<OCKAnyCarePlan>? = nil) {
        deleteAnyCarePlans([plan], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .deleteFailed(reason: "Failed to delete care plan")))
    }
}

// MARK: Async methods for OCKAnyReadOnlyCarePlanStore

public extension OCKAnyReadOnlyCarePlanStore {

    /// Aynchronously retrieves an array of care plans from the store.
    ///
    /// - Parameters:
    ///   - query: A query that constrains the values that the method fetches.
    func fetchAnyCarePlans(query: OCKCarePlanQuery) async throws -> [OCKAnyCarePlan] {
        try await withCheckedThrowingContinuation { continuation in
            fetchAnyCarePlans(query: query, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }

    // MARK: Singular Methods - Implementation Provided

    /// Asynchronously retrieves a single care plans from the store.
    ///
    /// - Parameters:
    ///   - id: The identifier of the item the method fetches.
    func fetchAnyCarePlan(withID id: String) async throws -> OCKAnyCarePlan {
        try await withCheckedThrowingContinuation { continuation in
            fetchAnyCarePlan(withID: id, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }
}

// MARK: Async methods for OCKAnyCarePlanStore

public extension OCKAnyCarePlanStore {

    /// Asynchronously adds an array of care plans to the store.
    ///
    /// - Parameters:
    ///   - plans: An array of plans to add to the store.
    func addAnyCarePlans(_ plans: [OCKAnyCarePlan]) async throws -> [OCKAnyCarePlan] {
        try await withCheckedThrowingContinuation { continuation in
            addAnyCarePlans(plans, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }

    /// Aynchronously updates an array of care plans in the store.
    ///
    /// - Parameters:
    ///   - plans: An array of care plans to update. The care plans must already exist in the store.
    func updateAnyCarePlans(_ plans: [OCKAnyCarePlan]) async throws -> [OCKAnyCarePlan] {
        try await withCheckedThrowingContinuation { continuation in
            updateAnyCarePlans(plans, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }

    /// Asynchronously deletes an array of care plans from the store.
    ///
    /// - Parameters:
    ///   - plans: An array of care plans to delete. The care plans must exist in the store.
    func deleteAnyCarePlans(_ plans: [OCKAnyCarePlan]) async throws -> [OCKAnyCarePlan] {
        try await withCheckedThrowingContinuation { continuation in
            deleteAnyCarePlans(plans, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }

    // MARK: Singular Methods - Implementation Provided

    /// Asynchronously adds a single care plan to the store.
    ///
    /// - Parameters:
    ///   - plan: A single plan to add to the store.
    func addAnyCarePlan(_ plan: OCKAnyCarePlan) async throws -> OCKAnyCarePlan {
        try await withCheckedThrowingContinuation { continuation in
            addAnyCarePlan(plan, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }

    /// Asynchronously updates a single care plan in the store.
    ///
    /// - Parameters:
    ///   - plan: A single care plan to update. The care plans must already exist in the store.
    func updateAnyCarePlan(_ plan: OCKAnyCarePlan) async throws -> OCKAnyCarePlan {
        try await withCheckedThrowingContinuation { continuation in
            updateAnyCarePlan(plan, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }

    /// Asynchronously deletes a single care plan from the store.
    ///
    /// - Parameters:
    ///   - plan: A single care plan to delete. The care plans must exist in the store.
    func deleteAnyCarePlan(_ plan: OCKAnyCarePlan) async throws -> OCKAnyCarePlan {
        try await withCheckedThrowingContinuation { continuation in
            deleteAnyCarePlan(plan, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }
}
