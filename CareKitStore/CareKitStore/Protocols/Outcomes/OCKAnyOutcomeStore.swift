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
public protocol OCKAnyReadOnlyOutcomeStore: OCKAnyResettableStore {

    /// A continuous stream of outcomes that exist in the store.
    ///
    /// The stream yields a new value whenever the result changes and yields an error if there's an issue
    /// accessing the store or fetching results.
    ///
    /// Supply a query that'll be used to match outcomes in the store. If the query doesn't contain a date
    /// interval, the result contains the latest version of each outcome. If the query does contain a date
    /// interval, the result contains outcomes whose events occur within the interval.
    ///
    /// This method doesn't check if an outcome's task is effective in the query interval.
    ///
    /// - Parameter query: Used to match outcomes in the store.
    func anyOutcomes(matching query: OCKOutcomeQuery) -> CareStoreQueryResults<OCKAnyOutcome>

    /// Fetch a list of outcomes that exist in the store.
    ///
    /// The closure receives an error if there's an issue accessing the store or fetching results.
    ///
    /// Supply a query that'll be used to match outcomes in the store. If the query doesn't contain a date
    /// interval, the result contains the latest version of each outcome. If the query does contain a date
    /// interval, the result contains outcomes whose events occur within the interval.
    ///
    /// This method doesn't check if an outcome's task is effective in the query interval.
    ///
    /// - Parameters:
    ///   - query: Used to match outcomes in the store.
    ///   - callbackQueue: The queue that runs the closure. In most cases this should be the
    ///                    main queue.
    ///   - completion: A callback that contains the result.
    func fetchAnyOutcomes(query: OCKOutcomeQuery, callbackQueue: DispatchQueue,
                          completion: @escaping OCKResultClosure<[OCKAnyOutcome]>)

    // MARK: Singular Methods - Implementation Provided

    /// Fetch an outcome from the store.
    ///
    /// If more than one outcome matches the query, only the first returns. If no matching outcomes
    /// exist, or there is an error accessing the store, the closure receives an error.
    ///
    /// Supply a query that'll be used to match outcomes in the store. If the query doesn't contain a date
    /// interval, the result contains the latest version of each outcome. If the query does contain a date
    /// interval, the result contains outcomes whose events occur within the interval.
    ///
    /// This method doesn't check if an outcome's task is effective in the query interval.
    ///
    /// - Parameters:
    ///   - query: Used to match outcomes in the store.
    ///   - callbackQueue: The queue that runs the closure. In most cases this should be the
    ///                    main queue.
    ///   - completion: A callback that contains the result.
    func fetchAnyOutcome(query: OCKOutcomeQuery, callbackQueue: DispatchQueue,
                         completion: @escaping OCKResultClosure<OCKAnyOutcome>)
}

public protocol OCKAnyOutcomeStore: OCKAnyReadOnlyOutcomeStore {

    /// Asynchronously add an array of outcomes to the store.
    ///
    /// - Parameters:
    ///   - outcomes: An array of outcomes to add to the store.
    ///   - callbackQueue: The queue that the function calls the closure on. In most cases this is the main queue.
    ///   - completion: A callback that the function calls on the provided callback queue.
    func addAnyOutcomes(_ outcomes: [OCKAnyOutcome], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyOutcome]>?)

    /// Asynchronously update an array of outcomes in the store.
    ///
    /// - Parameters:
    ///   - outcomes: An array of updated outcomes. The outcomes must already exist in the store.
    ///   - callbackQueue: The queue that the function calls the closure on. In most cases this is the main queue.
    ///   - completion: A callback that the function calls on the provided callback queue.
    func updateAnyOutcomes(_ outcomes: [OCKAnyOutcome], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyOutcome]>?)

    /// Asynchronously delete an array of outcomes from the store.
    ///
    /// - Parameters:
    ///   - outcomes: An array of outcomes to be deleted. The outcomes must exist in the store.
    ///   - callbackQueue: The queue that the function calls the closure on. In most cases this is the main queue.
    ///   - completion: A callback that the function calls on the provided callback queue.
    func deleteAnyOutcomes(_ outcomes: [OCKAnyOutcome], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyOutcome]>?)

    // MARK: Singular Methods - Implementation Provided

    /// Asynchronously add an outcome to the store.
    ///
    /// - Parameters:
    ///   - outcome: An outcome that the function adds to the store.
    ///   - callbackQueue: The queue that the function calls the closure on. In most cases this is the main queue.
    ///   - completion: A callback that the function calls on the provided callback queue.
    func addAnyOutcome(_ outcome: OCKAnyOutcome, callbackQueue: DispatchQueue, completion: OCKResultClosure<OCKAnyOutcome>?)

    /// Asynchronously update an outcome in the store.
    ///
    /// - Parameters:
    ///   - outcome: An outcome that the function updates. The outcome must already exist in the store.
    ///   - callbackQueue: The queue that the function calls the closure on. In most cases this is the main queue.
    ///   - completion: A callback that the function calls on the provided callback queue.
    func updateAnyOutcome(_ outcome: OCKAnyOutcome, callbackQueue: DispatchQueue, completion: OCKResultClosure<OCKAnyOutcome>?)

    /// Asynchronously delete an outcome from the store.
    ///
    /// - Parameters:
    ///   - outcome: An outcome that the function deletes. The outcome must exist in the store.
    ///   - callbackQueue: The queue that the function calls the closure on. In most cases this is the main queue.
    ///   - completion: A callback that the function calls on the provided callback queue.
    func deleteAnyOutcome(_ outcome: OCKAnyOutcome, callbackQueue: DispatchQueue, completion: OCKResultClosure<OCKAnyOutcome>?)
}

// MARK: Singular Methods for OCKAnyReadOnlyOutcomeStore

public extension OCKAnyReadOnlyOutcomeStore {
    func fetchAnyOutcome(query: OCKOutcomeQuery, callbackQueue: DispatchQueue = .main,
                         completion: @escaping OCKResultClosure<OCKAnyOutcome>) {
        fetchAnyOutcomes(query: query, callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .fetchFailed(reason: "No matching outcome found")))
    }
}

// MARK: Singular Methods for OCKAnyOutcomeStore

public extension OCKAnyOutcomeStore {

    func addAnyOutcome(_ outcome: OCKAnyOutcome, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<OCKAnyOutcome>? = nil) {
        addAnyOutcomes([outcome], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .addFailed(reason: "Failed to add outcome")))
    }

    func updateAnyOutcome(_ outcome: OCKAnyOutcome, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<OCKAnyOutcome>? = nil) {
        updateAnyOutcomes([outcome], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .updateFailed(reason: "Failed to update outcome")))
    }

    func deleteAnyOutcome(_ outcome: OCKAnyOutcome, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<OCKAnyOutcome>? = nil) {
        deleteAnyOutcomes([outcome], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .deleteFailed(reason: "Failed to delete outcome")))
    }
}

// MARK: Async methods for OCKAnyReadOnlyOutcomeStore

public extension OCKAnyReadOnlyOutcomeStore {

    /// Asynchronously retrieve an array of outcomes from the store.
    ///
    /// - Parameters:
    ///   - query: A query that constrains the fetched values.
    func fetchAnyOutcomes(query: OCKOutcomeQuery) async throws -> [OCKAnyOutcome] {
        try await withCheckedThrowingContinuation { continuation in
            fetchAnyOutcomes(query: query, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }

    // MARK: Singular Methods - Implementation Provided

    /// Asynchronously retrieve a single outcome from the store.
    ///
    /// If more than one outcome matches the query, only the first
    /// returns. If no matching outcomes exist, the completion handler receives an error.
    ///
    /// - Parameters:
    ///   - query: A query that constrains the fetched values.
    func fetchAnyOutcome(query: OCKOutcomeQuery) async throws -> OCKAnyOutcome {
        try await withCheckedThrowingContinuation { continuation in
            fetchAnyOutcome(query: query, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }
}

// MARK: Async methods for OCKAnyOutcomeStore

public extension OCKAnyOutcomeStore {

    /// Asynchronously add an array of outcomes to the store.
    ///
    /// - Parameters:
    ///   - outcomes: An array of outcomes added to the store.
    func addAnyOutcomes(_ outcomes: [OCKAnyOutcome]) async throws -> [OCKAnyOutcome] {
        try await withCheckedThrowingContinuation { continuation in
            addAnyOutcomes(outcomes, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }

    /// Asynchronously update an array of outcomes in the store.
    ///
    /// - Parameters:
    ///   - outcomes: An array of updated outcomes. The outcomes must already exist in the store.
    func updateAnyOutcomes(_ outcomes: [OCKAnyOutcome]) async throws -> [OCKAnyOutcome] {
        try await withCheckedThrowingContinuation { continuation in
            updateAnyOutcomes(outcomes, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }

    /// Asynchronously delete an array of outcomes from the store.
    ///
    /// - Parameters:
    ///   - outcomes: An array of outcomes that the function deletes. The outcomes must exist in the store.
    func deleteAnyOutcomes(_ outcomes: [OCKAnyOutcome]) async throws -> [OCKAnyOutcome] {
        try await withCheckedThrowingContinuation { continuation in
            deleteAnyOutcomes(outcomes, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }

    // MARK: Singular Methods - Implementation Provided

    /// Asynchronously add an outcome to the store.
    ///
    /// - Parameters:
    ///   - outcome: An outcome that the function adds to the store.
    func addAnyOutcome(_ outcome: OCKAnyOutcome) async throws -> OCKAnyOutcome {
        try await withCheckedThrowingContinuation { continuation in
            addAnyOutcome(outcome, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }

    /// Asynchronously update an outcome in the store.
    ///
    /// - Parameters:
    ///   - outcome: An outcome that the function updates. The outcome must already exist in the store.
    func updateAnyOutcome(_ outcome: OCKAnyOutcome) async throws -> OCKAnyOutcome {
        try await withCheckedThrowingContinuation { continuation in
            updateAnyOutcome(outcome, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }

    /// Asynchronously delete an outcome from the store.
    ///
    /// - Parameters:
    ///   - outcome: An outcome the function deletes. The outcome must exist in the store.
    func deleteAnyOutcome(_ outcome: OCKAnyOutcome) async throws -> OCKAnyOutcome {
        try await withCheckedThrowingContinuation { continuation in
            deleteAnyOutcome(outcome, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }
}
