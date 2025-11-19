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

/// A store that allows for reading outcomes.
public protocol OCKReadableOutcomeStore: OCKAnyReadOnlyOutcomeStore {

    associatedtype Outcome: OCKAnyOutcome, Equatable, Identifiable

    /// An asynchronous sequence that produces outcomes.
    associatedtype Outcomes: AsyncSequence & Sendable where Outcomes.Element == [Outcome]

    /// A continuous stream of outcomes that exist in the store.
    ///
    /// The stream yields a new value whenever the result changes and yields an error if there's an issue
    /// accessing the store or fetching results.
    ///
    /// Supply a query that'll be used to match outcomes in the store. If the query doesn't contain a date
    /// interval, the result will contain the latest version of each outcome. If the query does contain a date
    /// interval, the result will contain outcomes whose events occur within the interval.
    ///
    /// This method does not check if an outcome's task is effective in the query interval.
    ///
    /// - Parameter query: Used to match outcomes in the store.
    func outcomes(matching query: OCKOutcomeQuery) -> Outcomes

    /// Fetch a list of events that exist in the store.
    ///
    /// The completion will be called with an error if there's an issue accessing the store or fetching results.
    ///
    /// Supply a query that'll be used to match outcomes in the store. If the query doesn't contain a date
    /// interval, the result will contain the latest version of each outcome. If the query does contain a date
    /// interval, the result will contain outcomes whose events occur within the interval.
    ///
    /// This method does not check if an outcome's task is effective in the query interval.
    ///
    /// - Parameters:
    ///   - query: Used to match outcomes in the store.
    ///   - callbackQueue: The queue that runs the completion. In most cases this should be the
    ///                    main queue.
    ///   - completion: A callback that contains the result.
    func fetchOutcomes(query: OCKOutcomeQuery, callbackQueue: DispatchQueue,
                       completion: @escaping OCKResultClosure<[Outcome]>)

    /// Fetch a list of events that exist in the store.
    ///
    /// If more than one outcome matches the query, only the first will be returned. If no matching outcomes
    /// exist or there is an error accessing the store, the completion will be called with an error.
    ///
    /// Supply a query that'll be used to match outcomes in the store. If the query doesn't contain a date
    /// interval, the result will contain the latest version of each outcome. If the query does contain a date
    /// interval, the result will contain outcomes whose events occur within the interval.
    ///
    /// This method does not check if an outcome's task is effective in the query interval.
    ///
    /// - Parameters:
    ///   - query: Used to match outcomes in the store.
    ///   - callbackQueue: The queue that runs the completion. In most cases this should be the
    ///                    main queue.
    ///   - completion: A callback that contains the result.
    func fetchOutcome(query: OCKOutcomeQuery, callbackQueue: DispatchQueue,
                      completion: @escaping OCKResultClosure<Outcome>)
}

public protocol OCKOutcomeStore: OCKAnyOutcomeStore, OCKReadableOutcomeStore {

    /// `addOutcomes` asynchronously adds an array of outcomes to the store.
    ///
    /// - Parameters:
    ///   - outcomes: An array of outcomes to be added to the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func addOutcomes(_ outcomes: [Outcome], callbackQueue: DispatchQueue, completion: OCKResultClosure<[Outcome]>?)

    /// `updateOutcomes` asynchronously updates an array of outcomes in the store.
    ///
    /// - Parameters:
    ///   - outcomes: An array of outcomes to be updated. The outcomes must already exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func updateOutcomes(_ outcomes: [Outcome], callbackQueue: DispatchQueue, completion: OCKResultClosure<[Outcome]>?)

    /// `deleteOutcomes` asynchronously deletes an array of outcomes from the store.
    ///
    /// - Parameters:
    ///   - outcomes: An array of outcomes to be deleted. The outcomes must exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func deleteOutcomes(_ outcomes: [Outcome], callbackQueue: DispatchQueue, completion: OCKResultClosure<[Outcome]>?)

    // MARK: Implementation Provided

    /// `addOutcome` asynchronously adds an outcome to the store.
    ///
    /// - Parameters:
    ///   - outcome: An outcome to be added to the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func addOutcome(_ outcome: Outcome, callbackQueue: DispatchQueue, completion: OCKResultClosure<Outcome>?)

    /// `updateOutcome` asynchronously updates an outcome in the store.
    ///
    /// - Parameters:
    ///   - outcome: An outcome to be updated. The outcome must already exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func updateOutcome(_ outcome: Outcome, callbackQueue: DispatchQueue, completion: OCKResultClosure<Outcome>?)

    /// `deleteOutcome` asynchronously deletes an outcome from the store.
    ///
    /// - Parameters:
    ///   - outcome: An outcome to be deleted. The outcome must exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func deleteOutcome(_ outcome: Outcome, callbackQueue: DispatchQueue, completion: OCKResultClosure<Outcome>?)
}

// MARK: Singular Methods for OCKReadableOutcomeStore

public extension OCKReadableOutcomeStore {

    func anyOutcomes(matching query: OCKOutcomeQuery) -> CareStoreQueryResults<OCKAnyOutcome> {

        let outcomes = outcomes(matching: query)
            .map { $0 as [OCKAnyOutcome] }

        let wrappedOutcomes = CareStoreQueryResults(wrapping: outcomes)
        return wrappedOutcomes
    }

    func fetchOutcome(query: OCKOutcomeQuery, callbackQueue: DispatchQueue = .main,
                      completion: @escaping OCKResultClosure<Outcome>) {
        fetchOutcomes(query: query, callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .fetchFailed(reason: "No matching outcome found")))
    }
}

// MARK: Singular Methods for OCKOutcomeStore

public extension OCKOutcomeStore {
    func addOutcome(_ outcome: Outcome, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<Outcome>? = nil) {
        addOutcomes([outcome], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .addFailed(reason: "Failed to add outcome")))
    }

    func updateOutcome(_ outcome: Outcome, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<Outcome>? = nil) {
        updateOutcomes([outcome], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .updateFailed(reason: "Failed to update outcome")))
    }

    func deleteOutcome(_ outcome: Outcome, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<Outcome>? = nil) {
        deleteOutcomes([outcome], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .deleteFailed(reason: "Failed to delete outcome")))
    }
}

// MARK: OCKAnyReadOnlyStore conformance for OCKReadableOutcomeStore

public extension OCKReadableOutcomeStore {
    func fetchAnyOutcomes(query: OCKOutcomeQuery, callbackQueue: DispatchQueue,
                          completion: @escaping OCKResultClosure<[OCKAnyOutcome]>) {
        fetchOutcomes(query: query, callbackQueue: callbackQueue) { completion($0.map { $0.map { $0 as OCKAnyOutcome } }) }
    }
}

// MARK: OCKAnyStore conformance for OCKOutcomeStore

public extension OCKOutcomeStore {

    func addAnyOutcomes(_ outcomes: [OCKAnyOutcome], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyOutcome]>?) {
        guard let outcomes = outcomes as? [Outcome] else {
            let message = "Failed to add outcomes. Not all outcomes were the correct type, \(Outcome.self)."
            callbackQueue.async { completion?(.failure(.addFailed(reason: message))) }
            return
        }
        addOutcomes(outcomes, callbackQueue: callbackQueue) { completion?($0.map { $0.map { $0 as OCKAnyOutcome } }) }
    }

    func updateAnyOutcomes(_ outcomes: [OCKAnyOutcome], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyOutcome]>?) {
        guard let outcomes = outcomes as? [Outcome] else {
            let message = "Failed to update outcomes. Not all outcomes were the correct type, \(Outcome.self)."
            callbackQueue.async { completion?(.failure(.updateFailed(reason: message))) }
            return
        }
        updateOutcomes(outcomes, callbackQueue: callbackQueue) { completion?($0.map { $0.map { $0 as OCKAnyOutcome } }) }
    }

    func deleteAnyOutcomes(_ outcomes: [OCKAnyOutcome], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyOutcome]>?) {
        guard let outcomes = outcomes as? [Outcome] else {
            let message = "Failed to delete outcomes. Not all outcomes were the correct type, \(Outcome.self)."
            callbackQueue.async { completion?(.failure(.deleteFailed(reason: message))) }
            return
        }
        deleteOutcomes(outcomes, callbackQueue: callbackQueue) { completion?($0.map { $0.map { $0 as OCKAnyOutcome } }) }
    }
}

// MARK: Async methods for OCKReadableOutcomeStore

public extension OCKReadableOutcomeStore {

    /// `fetchOutcomes` asynchronously retrieves an array of outcomes from the store.
    ///
    /// - Parameters:
    ///   - query: A query used to constrain the values that will be fetched.
    func fetchOutcomes(query: OCKOutcomeQuery) async throws -> [Outcome] {
        try await withCheckedThrowingContinuation { continuation in
            fetchOutcomes(query: query, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }

    /// `fetchOutcome` asynchronously retrieves a single outcome from the store. If more than one outcome matches the query, only the first
    /// will be returned. If no matching outcomes exist, the completion handler will be called with an error.
    ///
    /// - Parameters:
    ///   - query: A query used to constrain the values that will be fetched.
    func fetchOutcome(query: OCKOutcomeQuery) async throws -> Outcome {
        try await withCheckedThrowingContinuation { continuation in
            fetchOutcome(query: query, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }
}

// MARK: Async methods for OCKOutcomeStore

public extension OCKOutcomeStore {

    /// `addOutcomes` asynchronously adds an array of outcomes to the store.
    ///
    /// - Parameters:
    ///   - outcomes: An array of outcomes to be added to the store.
    @discardableResult
    func addOutcomes(_ outcomes: [Outcome]) async throws -> [Outcome] {
        try await withCheckedThrowingContinuation { continuation in
            addOutcomes(outcomes, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }

    /// `updateOutcomes` asynchronously updates an array of outcomes in the store.
    ///
    /// - Parameters:
    ///   - outcomes: An array of outcomes to be updated. The outcomes must already exist in the store.
    @discardableResult
    func updateOutcomes(_ outcomes: [Outcome]) async throws -> [Outcome] {
        try await withCheckedThrowingContinuation { continuation in
            updateOutcomes(outcomes, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }

    /// `deleteOutcomes` asynchronously deletes an array of outcomes from the store.
    ///
    /// - Parameters:
    ///   - outcomes: An array of outcomes to be deleted. The outcomes must exist in the store.
    @discardableResult
    func deleteOutcomes(_ outcomes: [Outcome]) async throws -> [Outcome] {
        try await withCheckedThrowingContinuation { continuation in
            deleteOutcomes(outcomes, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }

    // MARK: Singular Methods - Implementation Provided

    /// `addOutcome` asynchronously adds an outcome to the store.
    ///
    /// - Parameters:
    ///   - outcome: An outcome to be added to the store.
    @discardableResult
    func addOutcome(_ outcome: Outcome) async throws -> Outcome {
        try await withCheckedThrowingContinuation { continuation in
            addOutcome(outcome, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }

    /// `updateOutcome` asynchronously updates an outcome in the store.
    ///
    /// - Parameters:
    ///   - outcome: An outcome to be updated. The outcome must already exist in the store.
    @discardableResult
    func updateOutcome(_ outcome: Outcome) async throws -> Outcome {
        try await withCheckedThrowingContinuation { continuation in
            updateOutcome(outcome, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }

    /// `deleteOutcome` asynchronously deletes an outcome from the store.
    ///
    /// - Parameters:
    ///   - outcome: An outcome to be deleted. The outcome must exist in the store.
    @discardableResult
    func deleteOutcome(_ outcome: Outcome) async throws -> Outcome {
        try await withCheckedThrowingContinuation { continuation in
            deleteOutcome(outcome, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }
}
