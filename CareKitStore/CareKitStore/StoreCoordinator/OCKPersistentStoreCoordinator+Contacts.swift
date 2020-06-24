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

extension OCKStoreCoordinator {

    open func fetchAnyContacts(query: OCKAnyContactQuery, callbackQueue: DispatchQueue = .main,
                               completion: @escaping (Result<[OCKAnyContact], OCKStoreError>) -> Void) {
        let readableStores = readOnlyContactStores + contactStores
        let respondingStores = readableStores.filter { contactStore($0, shouldHandleQuery: query) }
        let closures = respondingStores.map({ store in { done in
            store.fetchAnyContacts(query: query, callbackQueue: callbackQueue, completion: done) }
        })
        aggregate(closures, callbackQueue: callbackQueue, completion: completion)
    }

    open func addAnyContacts(_ contacts: [OCKAnyContact], callbackQueue: DispatchQueue = .main,
                             completion: ((Result<[OCKAnyContact], OCKStoreError>) -> Void)? = nil) {
        do {
            try findStore(forContacts: contacts).addAnyContacts(contacts, callbackQueue: callbackQueue, completion: completion)
        } catch {
            callbackQueue.async { completion?(.failure(.addFailed(reason: "Failed to find store accepting contacts. Error: \(error)"))) }
        }
    }

    open func updateAnyContacts(_ contacts: [OCKAnyContact], callbackQueue: DispatchQueue = .main,
                                completion: ((Result<[OCKAnyContact], OCKStoreError>) -> Void)? = nil) {
        do {
            try findStore(forContacts: contacts).updateAnyContacts(contacts, callbackQueue: callbackQueue, completion: completion)
        } catch {
            callbackQueue.async { completion?(.failure(.updateFailed(reason: "Failed to find store accepting contacts. Error: \(error)"))) }
        }
    }

    open func deleteAnyContacts(_ contacts: [OCKAnyContact], callbackQueue: DispatchQueue = .main,
                                completion: ((Result<[OCKAnyContact], OCKStoreError>) -> Void)? = nil) {
        do {
            try findStore(forContacts: contacts).deleteAnyContacts(contacts, callbackQueue: callbackQueue, completion: completion)
        } catch {
            callbackQueue.async { completion?(.failure(.deleteFailed(reason: "Failed to find store accepting contacts. Error: \(error)"))) }
        }
    }

    private func findStore(forContacts contacts: [OCKAnyContact]) throws -> OCKAnyContactStore {
        let matchingStores = contacts.compactMap { contact in contactStores.first(where: { contactStore($0, shouldHandleWritingContact: contact) }) }
        guard matchingStores.count == contacts.count else { throw OCKStoreError.invalidValue(reason: "No store could be found for some contacts.") }
        guard let store = matchingStores.first else { throw OCKStoreError.invalidValue(reason: "No store could be found for any contacts.") }
        guard matchingStores.allSatisfy({ $0 === store }) else { throw OCKStoreError.invalidValue(reason: "Not all contacts belong to same store.") }
        return store
    }
}

extension OCKStoreCoordinator: OCKContactStoreDelegate {
    open func contactStore(_ store: OCKAnyReadOnlyContactStore, didAddContacts contacts: [OCKAnyContact]) {
        contactDelegate?.contactStore(self, didAddContacts: contacts)
    }

    open func contactStore(_ store: OCKAnyReadOnlyContactStore, didUpdateContacts contacts: [OCKAnyContact]) {
        contactDelegate?.contactStore(self, didUpdateContacts: contacts)
    }

    open func contactStore(_ store: OCKAnyReadOnlyContactStore, didDeleteContacts contacts: [OCKAnyContact]) {
        contactDelegate?.contactStore(self, didDeleteContacts: contacts)
    }
}
