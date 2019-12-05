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
import Foundation

/// Any store from which a single type conforming to `OCKAnyCarePlan` can be queried is considered `OCKAnyReadOnlyCarePlanStore`.
public protocol OCKReadableCarePlanStore: OCKAnyReadOnlyCarePlanStore {
    associatedtype Plan: OCKAnyCarePlan & Equatable & Identifiable
    associatedtype PlanQuery: OCKAnyCarePlanQuery

    /// `fetchCarePlans` asynchronously retrieves an array of care plans from the store.
    ///
    /// - Parameters:
    ///   - query: A query used to constrain the values that will be fetched.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func fetchCarePlans(query: PlanQuery, callbackQueue: DispatchQueue, completion: @escaping OCKResultClosure<[Plan]>)

    // MARK: Implementation Provided

    /// `fetchCarePlan` asynchronously retrieves a care plan from the store using its user-defined unique identifier. If a care plan with the
    /// specified identifier is not found, the completion handler will be called with an error.
    ///
    /// - Parameters:
    ///   - id: A unique user-defined identifier
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func fetchCarePlan(withID id: String, callbackQueue: DispatchQueue, completion: @escaping OCKResultClosure<Plan>)
}

/// Any store that can perform read and write operations on a single type conforming to `OCKAnyCarePlan` is considered an `OCKCarePlanStore`.
public protocol OCKCarePlanStore: OCKReadableCarePlanStore, OCKAnyCarePlanStore {

    /// `addCarePlans` asynchronously adds an array of care plans to the store.
    ///
    /// - Parameters:
    ///   - plans: An array of plans to be added to the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func addCarePlans(_ plans: [Plan], callbackQueue: DispatchQueue, completion: OCKResultClosure<[Plan]>?)

    /// `updateCarePlans` asynchronously updates an array of care plans in the store.
    ///
    /// - Parameters:
    ///   - plans: An array of care plans to be updated. The care plans must already exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func updateCarePlans(_ plans: [Plan], callbackQueue: DispatchQueue, completion: OCKResultClosure<[Plan]>?)

    /// `deleteCarePlans` asynchronously deletes an array of care plans from the store.
    ///
    /// - Parameters:
    ///   - plans: An array of care plans to be deleted. The care plans must exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func deleteCarePlans(_ plans: [Plan], callbackQueue: DispatchQueue, completion: OCKResultClosure<[Plan]>?)

    // MARK: Implementation Provided

    /// `addCarePlan` asynchronously adds a care plans to the store.
    ///
    /// - Parameters:
    ///   - plan: A care plan to be added to the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func addCarePlan(_ plan: Plan, callbackQueue: DispatchQueue, completion: OCKResultClosure<Plan>?)

    /// `updateCarePlan` asynchronously updates a care plan in the store.
    ///
    /// - Parameters:
    ///   - plan: A care plan to be updated. The care plan must already exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func updateCarePlan(_ plan: Plan, callbackQueue: DispatchQueue, completion: OCKResultClosure<Plan>?)

    /// `deleteCarePlan` asynchronously deletes a care plan from the store.
    ///
    /// - Parameters:
    ///   - plan: A care plan to be deleted. The care plan must exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func deleteCarePlan(_ plan: Plan, callbackQueue: DispatchQueue, completion: OCKResultClosure<Plan>?)
}

// MARK: Singular Methods for OCKReadableCarePlanStore

public extension OCKReadableCarePlanStore {
    func fetchCarePlan(withID id: String, callbackQueue: DispatchQueue = .main, completion: @escaping OCKResultClosure<Plan>) {
        var query = OCKCarePlanQuery(for: Date())
        query.limit = 1
        query.extendedSortDescriptors = [.effectiveDate(ascending: true)]
        query.ids = [id]

        fetchCarePlans(query: PlanQuery(query), callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .fetchFailed(reason: "No care plan with ID: \(id)")))
    }
}

// MARK: Singular Methods for OCKCarePlanStoreProtocol

public extension OCKCarePlanStore {

    func addCarePlan(_ plan: Plan, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<Plan>? = nil) {
        addCarePlans([plan], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .addFailed(reason: "Failed to add care plan: \(plan)")))
    }

    func updateCarePlan(_ plan: Plan, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<Plan>? = nil) {
        updateCarePlans([plan], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .updateFailed(reason: "Failed to update care plan: \(plan)")))
    }

    func deleteCarePlan(_ plan: Plan, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<Plan>? = nil) {
        deleteCarePlans([plan], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .deleteFailed(reason: "Failed to delete care plan: \(plan)")))
    }
}

// MARK: OCKAnyReadOnlyCarePlanStore conformance for OCKReadableCarePlanStore

public extension OCKReadableCarePlanStore {
    func fetchAnyCarePlans(query: OCKAnyCarePlanQuery, callbackQueue: DispatchQueue,
                           completion: @escaping OCKResultClosure<[OCKAnyCarePlan]>) {
        let planQuery = PlanQuery(query)
        fetchCarePlans(query: planQuery, callbackQueue: callbackQueue) { completion($0.map { $0.map { $0 as OCKAnyCarePlan } }) }
    }
}

// MARK: OCKAnyCarePlanStore conformance for OCKCarePlanStore

public extension OCKCarePlanStore {
    func addAnyCarePlans(_ plans: [OCKAnyCarePlan], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyCarePlan]>?) {
        guard let plans = plans as? [Plan] else {
            let message = "Failed to add plans. Not all plans were of the correct type: \(Plan.self)."
            callbackQueue.async { completion?(.failure(.addFailed(reason: message))) }
            return
        }
        addCarePlans(plans, callbackQueue: callbackQueue) { completion?($0.map { $0.map { $0 as OCKAnyCarePlan } }) }
    }

    func updateAnyCarePlans(_ plans: [OCKAnyCarePlan], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyCarePlan]>?) {
        guard let plans = plans as? [Plan] else {
            let message = "Failed to update plans. Not all plans were of the correct type: \(Plan.self)."
            callbackQueue.async { completion?(.failure(.updateFailed(reason: message))) }
            return
        }
        updateCarePlans(plans, callbackQueue: callbackQueue) { completion?($0.map { $0.map { $0 as OCKAnyCarePlan } }) }
    }

    func deleteAnyCarePlans(_ plans: [OCKAnyCarePlan], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyCarePlan]>?) {
        guard let plans = plans as? [Plan] else {
            let message = "Failed to delete plans. Not all plans were of the correct type: \(Plan.self)."
            callbackQueue.async { completion?(.failure(.deleteFailed(reason: message))) }
            return
        }
        deleteCarePlans(plans, callbackQueue: callbackQueue) { completion?($0.map { $0.map { $0 as OCKAnyCarePlan } }) }
    }
}
