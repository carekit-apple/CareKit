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

/// Any store from which a single type conforming to `OCKAnyContact` can be queried is considered `OCKAReadableCarePlanStore`.
public protocol OCKReadableContactStore: OCKAnyReadOnlyContactStore {
    associatedtype Contact: OCKAnyContact & Equatable & Identifiable

    /// `fetchContacts` asynchronously retrieves an array of contacts from the store.
    ///
    /// - Parameters:
    ///   - query: A query used to constrain the values that will be fetched.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func fetchContacts(query: OCKContactQuery, callbackQueue: DispatchQueue, completion: @escaping OCKResultClosure<[Contact]>)

    // MARK: Implementation Provided

    /// `fetchContact` asynchronously retrieves a contact from the store using its user-defined unique identifier. If a contact with the
    /// specified identifier is not found, the completion handler will be called with an error.
    ///
    /// - Parameters:
    ///   - id: A unique user-defined identifier.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func fetchContact(withID id: String, callbackQueue: DispatchQueue, completion: @escaping OCKResultClosure<Contact>)
}

/// Any store that can perform read and write operations on a single type conforming to `OCKAnyContact` is considered an `OCKCarePlanStore`.
public protocol OCKContactStore: OCKReadableContactStore, OCKAnyContactStore {

    /// `addContacts` asynchronously adds an array of contacts to the store.
    ///
    /// - Parameters:
    ///   - contacts: An array of contacts to be added to the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func addContacts(_ contacts: [Contact], callbackQueue: DispatchQueue, completion: OCKResultClosure<[Contact]>?)

    /// `updateContacts` asynchronously updates an array of contacts in the store.
    ///
    /// - Parameters:
    ///   - contacts: An array of contacts to be updated. The contacts must already exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func updateContacts(_ contacts: [Contact], callbackQueue: DispatchQueue, completion: OCKResultClosure<[Contact]>?)

    /// `deleteContacts` asynchronously deletes an array of contacts from the store.
    ///
    /// - Parameters:
    ///   - contacts: An array of contacts to be deleted. The contacts must exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func deleteContacts(_ contacts: [Contact], callbackQueue: DispatchQueue, completion: OCKResultClosure<[Contact]>?)

    // MARK: Implementation Provided

    /// `addContact` asynchronously adds a contact to the store.
    ///
    /// - Parameters:
    ///   - contact: A contact to be added to the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func addContact(_ contact: Contact, callbackQueue: DispatchQueue, completion: OCKResultClosure<Contact>?)

    /// `updateContact` asynchronously updates a contacts in the store.
    ///
    /// - Parameters:
    ///   - contact: A contact to be updated. The contact must already exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func updateContact(_ contact: Contact, callbackQueue: DispatchQueue, completion: OCKResultClosure<Contact>?)

    /// `deleteContact` asynchronously deletes a contact from the store.
    ///
    /// - Parameters:
    ///   - contact: A contact to be deleted. The contact must exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func deleteContact(_ contact: Contact, callbackQueue: DispatchQueue, completion: OCKResultClosure<Contact>?)
}

// MARK: Singular Methods for OCKReadableContactStore
public extension OCKReadableContactStore {
    func fetchContact(withID id: String, callbackQueue: DispatchQueue = .main,
                      completion: @escaping OCKResultClosure<Contact>) {
        var query = OCKContactQuery(for: Date())
        query.limit = 1
        query.ids = [id]
        query.sortDescriptors = [.effectiveDate(ascending: true)]

        fetchContacts(query: query, callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .fetchFailed(reason: "No contact with matching ID")))
    }
}

// MARK: Singular Methods for OCKContactStore

public extension OCKContactStore {
    func addContact(_ contact: Contact, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<Contact>? = nil) {
        addContacts([contact], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .addFailed(reason: "Failed to add contact")))
    }

    func updateContact(_ contact: Contact, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<Contact>? = nil) {
        updateContacts([contact], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .updateFailed(reason: "Failed to update contact")))
    }

    func deleteContact(_ contact: Contact, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<Contact>? = nil) {
        deleteContacts([contact], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .deleteFailed(reason: "Failed to delete contact")))
    }
}

// MARK: OCKAnyReadbaleContactStore conformance for OCKReadableContactStore

public extension OCKReadableContactStore {
    func fetchAnyContacts(query: OCKContactQuery, callbackQueue: DispatchQueue,
                          completion: @escaping OCKResultClosure<[OCKAnyContact]>) {
        fetchContacts(query: query, callbackQueue: callbackQueue) { completion($0.map { $0.map { $0 as OCKAnyContact } }) }
    }
}

// MARK: OCKAnyContactStore conformance for OCKContactStore

public extension OCKContactStore {
    func addAnyContacts(_ contacts: [OCKAnyContact], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyContact]>?) {
        guard let contacts = contacts as? [Contact] else {
            let message = "Failed to add contacts. Not all contact were the correct type: \(Contact.self)."
            callbackQueue.async { completion?(.failure(.addFailed(reason: message))) }
            return
        }
        addContacts(contacts, callbackQueue: callbackQueue) { completion?($0.map { $0.map { $0 as OCKAnyContact } }) }
    }

    func updateAnyContacts(_ contacts: [OCKAnyContact], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyContact]>?) {
        guard let contacts = contacts as? [Contact] else {
            let message = "Failed to update contacts. Not all contact were the correct type: \(Contact.self)."
            callbackQueue.async { completion?(.failure(.updateFailed(reason: message))) }
            return
        }
        updateContacts(contacts, callbackQueue: callbackQueue) { completion?($0.map { $0.map { $0 as OCKAnyContact } }) }
    }

    func deleteAnyContacts(_ contacts: [OCKAnyContact], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyContact]>?) {
        guard let contacts = contacts as? [Contact] else {
            let message = "Failed to delete contacts. Not all contact were the correct type: \(Contact.self)."
            callbackQueue.async { completion?(.failure(.deleteFailed(reason: message))) }
            return
        }
        deleteContacts(contacts, callbackQueue: callbackQueue) { completion?($0.map { $0.map { $0 as OCKAnyContact } }) }
    }
}

// MARK: Async methods for OCKReadableContactStore

@available(iOS 15.0, watchOS 8.0, *)
public extension OCKReadableContactStore {

    /// `fetchContacts` asynchronously retrieves an array of contacts from the store.
    ///
    /// - Parameters:
    ///   - query: A query used to constrain the values that will be fetched.
    func fetchContacts(query: OCKContactQuery) async throws -> [Contact] {
        try await withCheckedThrowingContinuation { continuation in
            fetchContacts(query: query, callbackQueue: .main, completion: continuation.resume)
        }
    }

    // MARK: Singular Methods - Implementation Provided

    /// `fetchContact` asynchronously retrieves a contact from the store using its user-defined unique identifier. If a contact with the
    /// specified identifier is not found, the completion handler will be called with an error.
    ///
    /// - Parameters:
    ///   - id: The identifier of the item to be fetched.
    func fetchContact(withID id: String) async throws -> Contact {
        try await withCheckedThrowingContinuation { continuation in
            fetchContact(withID: id, callbackQueue: .main, completion: continuation.resume)
        }
    }
}

// MARK: Async methods for OCKContactStore

@available(iOS 15.0, watchOS 8.0, *)
public extension OCKContactStore {

    /// `addContacts` asynchronously adds an array of contacts to the store.
    ///
    /// - Parameters:
    ///   - contacts: An array of contacts to be added to the store.
    func addContacts(_ contacts: [Contact]) async throws -> [Contact] {
        try await withCheckedThrowingContinuation { continuation in
            addContacts(contacts, callbackQueue: .main, completion: continuation.resume)
        }
    }

    /// `updateContacts` asynchronously updates an array of contacts in the store.
    ///
    /// - Parameters:
    ///   - contacts: An array of contacts to be updated. The contacts must already exist in the store.
    func updateContacts(_ contacts: [Contact]) async throws -> [Contact] {
        try await withCheckedThrowingContinuation { continuation in
            updateContacts(contacts, callbackQueue: .main, completion: continuation.resume)
        }
    }

    /// `deleteContacts` asynchronously deletes an array of contacts from the store.
    ///
    /// - Parameters:
    ///   - contacts: An array of contacts to be deleted. The contacts must exist in the store.
    func deleteContacts(_ contacts: [Contact]) async throws -> [Contact] {
        try await withCheckedThrowingContinuation { continuation in
            deleteContacts(contacts, callbackQueue: .main, completion: continuation.resume)
        }
    }

    // MARK: Singular Methods - Implementation Provided

    /// `addContact` asynchronously adds a contact to the store.
    ///
    /// - Parameters:
    ///   - contact: A contact to be added to the store.
    func addContact(_ contact: Contact) async throws -> Contact {
        try await withCheckedThrowingContinuation { continuation in
            addContact(contact, callbackQueue: .main, completion: continuation.resume)
        }
    }

    /// `updateContact` asynchronously updates a contacts in the store.
    ///
    /// - Parameters:
    ///   - contact: A contact to be updated. The contact must already exist in the store.
    func updateContact(_ contact: Contact) async throws -> Contact {
        try await withCheckedThrowingContinuation { continuation in
            updateContact(contact, callbackQueue: .main, completion: continuation.resume)
        }
    }

    /// `deleteContact` asynchronously deletes a contact from the store.
    ///
    /// - Parameters:
    ///   - contact: A contact to be deleted. The contact must exist in the store.
    func deleteContact(_ contact: Contact) async throws -> Contact {
        try await withCheckedThrowingContinuation { continuation in
            deleteContact(contact, callbackQueue: .main, completion: continuation.resume)
        }
    }
}
