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

public protocol OCKAnyReadOnlyOutcomeStore: AnyObject {

    /// The delegate receives callbacks when the contents of the care plan store are modified.
    /// In `CareKit` apps, the delegate will be set automatically, and it should not be modified.
    var outcomeDelegate: OCKOutcomeStoreDelegate? { get set }

    /// `fetchAnyOutcomes` asynchronously retrieves an array of outcomes from the store.
    ///
    /// - Parameters:
    ///   - query: A query used to constrain the values that will be fetched.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func fetchAnyOutcomes(query: OCKAnyOutcomeQuery, callbackQueue: DispatchQueue,
                          completion: @escaping OCKResultClosure<[OCKAnyOutcome]>)

    // MARK: Singular Methods - Implementation Provided

    /// `fetchAnyOutcome` asynchronously retrieves a single outcome from the store. If more than one outcome matches the query, only the first
    /// will be returned. If no matching outcomes exist, the completion handler will be called with an error.
    ///
    /// - Parameters:
    ///   - query: A query used to constrain the values that will be fetched.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func fetchAnyOutcome(query: OCKAnyOutcomeQuery, callbackQueue: DispatchQueue,
                         completion: @escaping OCKResultClosure<OCKAnyOutcome>)
}

public protocol OCKAnyOutcomeStore: OCKAnyReadOnlyOutcomeStore {

    /// `addOutcomes` asynchronously adds an array of outcomes to the store.
    ///
    /// - Parameters:
    ///   - outcomes: An array of outcomes to be added to the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func addAnyOutcomes(_ outcomes: [OCKAnyOutcome], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyOutcome]>?)

    /// `updateOutcomes` asynchronously updates an array of outcomes in the store.
    ///
    /// - Parameters:
    ///   - contacts: An array of outcomes to be updated. The outcomes must already exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func updateAnyOutcomes(_ outcomes: [OCKAnyOutcome], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyOutcome]>?)

    /// `deleteOutcomes` asynchronously deletes an array of outcomes from the store.
    ///
    /// - Parameters:
    ///   - outcomes: An array of outcomes to be deleted. The outcomes must exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func deleteAnyOutcomes(_ outcomes: [OCKAnyOutcome], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyOutcome]>?)

    // MARK: Singular Methods - Implementation Provided

    /// `addOutcome` asynchronously adds an outcome to the store.
    ///
    /// - Parameters:
    ///   - outcome: An outcome to be added to the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func addAnyOutcome(_ outcome: OCKAnyOutcome, callbackQueue: DispatchQueue, completion: OCKResultClosure<OCKAnyOutcome>?)

    /// `updateOutcome` asynchronously updates an outcome in the store.
    ///
    /// - Parameters:
    ///   - outcome: An outcome to be updated. The outcome must already exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func updateAnyOutcome(_ outcome: OCKAnyOutcome, callbackQueue: DispatchQueue, completion: OCKResultClosure<OCKAnyOutcome>?)

    /// `deleteOutcome` asynchronously deletes an outcome from the store.
    ///
    /// - Parameters:
    ///   - outcome: An outcome to be deleted. The outcome must exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func deleteAnyOutcome(_ outcome: OCKAnyOutcome, callbackQueue: DispatchQueue, completion: OCKResultClosure<OCKAnyOutcome>?)
}

// MARK: Singular Methods for OCKAnyReadOnlyOutcomeStore

public extension OCKAnyReadOnlyOutcomeStore {
    func fetchAnyOutcome(query: OCKAnyOutcomeQuery, callbackQueue: DispatchQueue = .main,
                         completion: @escaping OCKResultClosure<OCKAnyOutcome>) {
        fetchAnyOutcomes(query: query, callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .fetchFailed(reason: "No matching outcome found")))
    }
}

// MARK: Singular Methods for OCKAnyOutcomeStore

public extension OCKAnyOutcomeStore {

    func addAnyOutcome(_ outcome: OCKAnyOutcome, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<OCKAnyOutcome>? = nil) {
        addAnyOutcomes([outcome], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .addFailed(reason: "Failed to add outcome: \(outcome)")))
    }

    func updateAnyOutcome(_ outcome: OCKAnyOutcome, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<OCKAnyOutcome>? = nil) {
        updateAnyOutcomes([outcome], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .updateFailed(reason: "Failed to update outcome: \(outcome)")))
    }

    func deleteAnyOutcome(_ outcome: OCKAnyOutcome, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<OCKAnyOutcome>? = nil) {
        deleteAnyOutcomes([outcome], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .deleteFailed(reason: "Failed to delete outcome: \(outcome)")))
    }
}
