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

/// Any store from which types conforming to `OCKAnyContact` can be queried is considered `OCKAnyReadOnlyContactStore`.
public protocol OCKAnyReadOnlyContactStore: AnyObject {

    /// The delegate receives callbacks when the contents of the care plan store are modified.
    /// In `CareKit` apps, the delegate will be set automatically, and it should not be modified.
    var contactDelegate: OCKContactStoreDelegate? { get set }

    /// `fetchAnyContacts` asynchronously retrieves an array of contacts from the store.
    ///
    /// - Parameters:
    ///   - query: A query used to constrain the values that will be fetched.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func fetchAnyContacts(query: OCKAnyContactQuery, callbackQueue: DispatchQueue, completion: @escaping OCKResultClosure<[OCKAnyContact]>)

    // MARK: Singular Methods - Implementation Provided

    /// `fetchAnyContact` asynchronously retrieves a single contact from the store.
    ///
    /// - Parameters:
    ///   - id: The identifier of the item to be fetched.
    ///   - query: A query used to constrain the values that will be fetched.
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

    // MARK: Singular Methods - Implementation Privided

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
    ///   - contact: An single contact to be deleted. The contact must exist in the store.
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
        query.extendedSortDescriptors = [.effectiveDate(ascending: true)]
        query.ids = [id]

        fetchAnyContacts(query: query, callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .fetchFailed(reason: "No contact with ID: \(id)")))
    }
}

// MARK: Singular Methods for OCKAnyContactStore

public extension OCKAnyContactStore {
    func addAnyContact(_ contact: OCKAnyContact, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<OCKAnyContact>? = nil) {
        addAnyContacts([contact], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .addFailed(reason: "Failed to add contact: \(contact)")))
    }

    func updateAnyContact(_ contact: OCKAnyContact, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<OCKAnyContact>? = nil) {
        updateAnyContacts([contact], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .updateFailed(reason: "Failed to update contact: \(contact)")))
    }

    func deleteAnyContact(_ contact: OCKAnyContact, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<OCKAnyContact>? = nil) {
        deleteAnyContacts([contact], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .deleteFailed(reason: "Failed to delete contact: \(contact)")))
    }
}
