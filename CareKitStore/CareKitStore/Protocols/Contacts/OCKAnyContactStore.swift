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

/// A store that allows for reading contacts.
public protocol OCKAnyReadOnlyContactStore: OCKAnyResettableStore, Sendable {

    /// A continuous stream of contacts that exist in the store.
    ///
    /// The stream yields a new value whenever the result changes and yields an error if there's an issue
    /// accessing the store or fetching results.
    ///
    /// Supply a query that'll be used to match contacts in the store. If the query doesn't contain a date
    /// interval, the result will contain every version of a contact. Multiple versions of the same contact will
    /// have the same ``OCKAnyContact/id`` but a different UUID. If the query does contain a date
    /// interval, the result will contain the newest version of a contact that exists in the interval.
    ///
    /// - Parameter query: Used to match contacts in the store.
    func anyContacts(matching query: OCKContactQuery) -> CareStoreQueryResults<OCKAnyContact>

    /// `fetchAnyContacts` asynchronously retrieves an array of contacts from the store.
    ///
    /// - Parameters:
    ///   - query: A query used to constrain the values that will be fetched.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func fetchAnyContacts(query: OCKContactQuery, callbackQueue: DispatchQueue, completion: @escaping OCKResultClosure<[OCKAnyContact]>)

    // MARK: Singular Methods - Implementation Provided

    /// `fetchAnyContact` asynchronously retrieves a single contact from the store.
    ///
    /// - Parameters:
    ///   - id: The identifier of the item to be fetched.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func fetchAnyContact(withID id: String, callbackQueue: DispatchQueue, completion: @escaping OCKResultClosure<OCKAnyContact>)
}

/// Any store able to write to one ore more types conforming to `OCKAnyContact` is considered an `OCKAnyContactStore`.
public protocol OCKAnyContactStore: OCKAnyReadOnlyContactStore {

    /// `addAnyContacts` asynchronously adds an array of contacts to the store.
    ///
    /// - Parameters:
    ///   - contacts: An array of contacts to be added to the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func addAnyContacts(_ contacts: [OCKAnyContact], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyContact]>?)

    /// `updateAnyContacts` asynchronously updates an array of contacts in the store.
    ///
    /// - Parameters:
    ///   - contacts: An array of contacts to be updated. The contacts must already exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func updateAnyContacts(_ contacts: [OCKAnyContact], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyContact]>?)

    /// `deleteAnyContacts` asynchronously deletes an array of contacts from the store.
    ///
    /// - Parameters:
    ///   - contacts: An array of contacts to be deleted. The contacts must exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func deleteAnyContacts(_ contacts: [OCKAnyContact], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyContact]>?)

    // MARK: Singular Methods - Implementation Provided

    /// `addAnyContact` asynchronously adds a single contact to the store.
    ///
    /// - Parameters:
    ///   - contact: A single contact to be added to the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func addAnyContact(_ contact: OCKAnyContact, callbackQueue: DispatchQueue, completion: OCKResultClosure<OCKAnyContact>?)

    /// `updateAnyContact` asynchronously update single contact in the store.
    ///
    /// - Parameters:
    ///   - contact: A single contact to be updated. The contact must already exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func updateAnyContact(_ contact: OCKAnyContact, callbackQueue: DispatchQueue, completion: OCKResultClosure<OCKAnyContact>?)

    /// `deleteAnyContact` asynchronously deletes a single contact from the store.
    ///
    /// - Parameters:
    ///   - contact: A single contact to be deleted. The contact must exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func deleteAnyContact(_ contact: OCKAnyContact, callbackQueue: DispatchQueue, completion: OCKResultClosure<OCKAnyContact>?)
}

// MARK: Singular Methods for OCKAnyReadOnlyContactStore

public extension OCKAnyReadOnlyContactStore {
    func fetchAnyContact(withID id: String, callbackQueue: DispatchQueue = .main,
                         completion: @escaping OCKResultClosure<OCKAnyContact>) {
        var query = OCKContactQuery(for: Date())
        query.limit = 1
        query.sortDescriptors = [.effectiveDate(ascending: true)]
        query.ids = [id]

        fetchAnyContacts(query: query, callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .fetchFailed(reason: "No contact with matching ID")))
    }
}

// MARK: Singular Methods for OCKAnyContactStore

public extension OCKAnyContactStore {
    func addAnyContact(_ contact: OCKAnyContact, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<OCKAnyContact>? = nil) {
        addAnyContacts([contact], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .addFailed(reason: "Failed to add contact")))
    }

    func updateAnyContact(_ contact: OCKAnyContact, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<OCKAnyContact>? = nil) {
        updateAnyContacts([contact], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .updateFailed(reason: "Failed to update contact")))
    }

    func deleteAnyContact(_ contact: OCKAnyContact, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<OCKAnyContact>? = nil) {
        deleteAnyContacts([contact], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .deleteFailed(reason: "Failed to delete contact")))
    }
}

// MARK: Async methods for OCKAnyReadOnlyContactStore

public extension OCKAnyReadOnlyContactStore {

    /// `fetchAnyContacts` asynchronously retrieves an array of contacts from the store.
    ///
    /// - Parameters:
    ///   - query: A query used to constrain the values that will be fetched.
    func fetchAnyContacts(query: OCKContactQuery) async throws -> [OCKAnyContact] {
        try await withCheckedThrowingContinuation { continuation in
            fetchAnyContacts(query: query, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }

    // MARK: Singular Methods - Implementation Provided

    /// `fetchAnyContact` asynchronously retrieves a single contact from the store.
    ///
    /// - Parameters:
    ///   - id: The identifier of the item to be fetched.
    func fetchAnyContact(withID id: String) async throws -> OCKAnyContact {
        try await withCheckedThrowingContinuation { continuation in
            fetchAnyContact(withID: id, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }
}

// MARK: Async methods for OCKAnyContactStore

public extension OCKAnyContactStore {

    /// `addAnyContacts` asynchronously adds an array of contacts to the store.
    ///
    /// - Parameters:
    ///   - contacts: An array of contacts to be added to the store.
    @discardableResult
    func addAnyContacts(_ contacts: [OCKAnyContact]) async throws -> [OCKAnyContact] {
        try await withCheckedThrowingContinuation { continuation in
            addAnyContacts(contacts, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }

    /// `updateAnyContacts` asynchronously updates an array of contacts in the store.
    ///
    /// - Parameters:
    ///   - contacts: An array of contacts to be updated. The contacts must already exist in the store.
    @discardableResult
    func updateAnyContacts(_ contacts: [OCKAnyContact]) async throws -> [OCKAnyContact] {
        try await withCheckedThrowingContinuation { continuation in
            updateAnyContacts(contacts, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }

    /// `deleteAnyContacts` asynchronously deletes an array of contacts from the store.
    ///
    /// - Parameters:
    ///   - contacts: An array of contacts to be deleted. The contacts must exist in the store.
    @discardableResult
    func deleteAnyContacts(_ contacts: [OCKAnyContact]) async throws -> [OCKAnyContact] {
        try await withCheckedThrowingContinuation { continuation in
            deleteAnyContacts(contacts, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }

    // MARK: Singular Methods - Implementation Provided

    /// `addAnyContact` asynchronously adds a single contact to the store.
    ///
    /// - Parameters:
    ///   - contact: A single contact to be added to the store.
    @discardableResult
    func addAnyContact(_ contact: OCKAnyContact) async throws -> OCKAnyContact {
        try await withCheckedThrowingContinuation { continuation in
            addAnyContact(contact, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }

    /// `updateAnyContact` asynchronously update a single contact in the store.
    ///
    /// - Parameters:
    ///   - contact: A single contact to be updated. The contact must already exist in the store.
    @discardableResult
    func updateAnyContact(_ contact: OCKAnyContact) async throws -> OCKAnyContact {
        try await withCheckedThrowingContinuation { continuation in
            updateAnyContact(contact, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }

    /// `deleteAnyContact` asynchronously deletes a single contact from the store.
    ///
    /// - Parameters:
    ///   - contact: A single contact to be deleted. The contact must exist in the store.
    @discardableResult
    func deleteAnyContact(_ contact: OCKAnyContact) async throws -> OCKAnyContact {
        try await withCheckedThrowingContinuation { continuation in
            deleteAnyContact(contact, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }
}
