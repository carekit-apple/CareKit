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

/// Any store from which types conforming to `OCKAnyCarePlan` can be queried is considered `OCKAnyReadOnlyCarePlanStore`.
public protocol OCKAnyReadOnlyCarePlanStore: AnyObject {

    /// The delegate receives callbacks when the contents of the care plan store are modified.
    /// In `CareKit` apps, the delegate will be set automatically, and it should not be modified.
    var carePlanDelegate: OCKCarePlanStoreDelegate? { get set }

    /// `fetchCarePlans` asynchronously retrieves an array of care plans from the store.
    ///
    /// - Parameters:
    ///   - query: A query used to constrain the values that will be fetched.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func fetchAnyCarePlans(query: OCKAnyCarePlanQuery, callbackQueue: DispatchQueue,
                           completion: @escaping OCKResultClosure<[OCKAnyCarePlan]>)

    // MARK: Singular Methods - Implementation Provided

    /// `fetchCarePlan` asynchronously retrieves a single care plans from the store.
    ///
    /// - Parameters:
    ///   - id: The identifier of the item to be fetched.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func fetchAnyCarePlan(withID id: String, callbackQueue: DispatchQueue, completion: @escaping OCKResultClosure<OCKAnyCarePlan>)

}

/// Any store able to write to one ore more types conforming to `OCKAnyCarePlan` is considered an `OCKAnyCarePlanStore`.
public protocol OCKAnyCarePlanStore: OCKAnyReadOnlyCarePlanStore {

    /// `addCarePlans` asynchronously adds an array of care plans to the store.
    ///
    /// - Parameters:
    ///   - plans: An array of plans to be added to the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func addAnyCarePlans(_ plans: [OCKAnyCarePlan], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyCarePlan]>?)

    /// `updateCarePlans` asynchronously updates an array of care plans in the store.
    ///
    /// - Parameters:
    ///   - plans: An array of care plans to be updated. The care plans must already exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func updateAnyCarePlans(_ plans: [OCKAnyCarePlan], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyCarePlan]>?)

    /// `deleteCarePlans` asynchronously deletes an array of care plans from the store.
    ///
    /// - Parameters:
    ///   - plans: An array of care plans to be deleted. The care plans must exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func deleteAnyCarePlans(_ plans: [OCKAnyCarePlan], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyCarePlan]>?)

    // MARK: Singular Methods - Implementation Provided

    /// `addAnyCarePlan` asynchronously adds a single care plan to the store.
    ///
    /// - Parameters:
    ///   - plan: A single plan to be added to the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func addAnyCarePlan(_ plan: OCKAnyCarePlan, callbackQueue: DispatchQueue, completion: OCKResultClosure<OCKAnyCarePlan>?)

    /// `updateCarePlan` asynchronously updates a single care plan in the store.
    ///
    /// - Parameters:
    ///   - plan: A single care plan to be updated. The care plans must already exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func updateAnyCarePlan(_ plan: OCKAnyCarePlan, callbackQueue: DispatchQueue, completion: OCKResultClosure<OCKAnyCarePlan>?)

    /// `deleteCarePlan` asynchronously deletes a single care plan from the store.
    ///
    /// - Parameters:
    ///   - plans: An single care plan to be deleted. The care plans must exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func deleteAnyCarePlan(_ plan: OCKAnyCarePlan, callbackQueue: DispatchQueue, completion: OCKResultClosure<OCKAnyCarePlan>?)
}

// MARK: Singular Methods for OCKAnyReadOnlyCarePlanStore

public extension OCKAnyReadOnlyCarePlanStore {
    func fetchAnyCarePlan(withID id: String, callbackQueue: DispatchQueue = .main,
                          completion: @escaping OCKResultClosure<OCKAnyCarePlan>) {
        var query = OCKCarePlanQuery(for: Date())
        query.limit = 1
        query.extendedSortDescriptors = [.effectiveDate(ascending: true)]
        query.ids = [id]

        fetchAnyCarePlans(query: query, callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .fetchFailed(reason: "No care plan with ID: \(id)")))
    }
}

// MARK: Singular Methods for OCKAnyCarePlanStore

public extension OCKAnyCarePlanStore {
    func addAnyCarePlan(_ plan: OCKAnyCarePlan, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<OCKAnyCarePlan>? = nil) {
        addAnyCarePlans([plan], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .addFailed(reason: "Failed to add care plan: \(plan)")))
    }

    func updateAnyCarePlan(_ plan: OCKAnyCarePlan, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<OCKAnyCarePlan>? = nil) {
        updateAnyCarePlans([plan], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .updateFailed(reason: "Failed to update care plan: \(plan)")))
    }

    func deleteAnyCarePlan(_ plan: OCKAnyCarePlan, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<OCKAnyCarePlan>? = nil) {
        deleteAnyCarePlans([plan], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .deleteFailed(reason: "Failed to delete care plan: \(plan)")))
    }
}
