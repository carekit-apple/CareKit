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

extension OCKStoreCoordinator {

    public func anyContacts(matching query: OCKContactQuery) -> CareStoreQueryResults<OCKAnyContact> {

        let relevantStores = storesHandlingQuery(query)

        let contactsStreams = relevantStores.map {
            $0.anyContacts(matching: query)
        }

        let contacts = combineMany(
            sequences: contactsStreams,
            makeSortDescriptors: {
                return query
                    .sortDescriptors
                    .map(\.nsSortDescriptor)
            }
        )

        return contacts
    }

    public func fetchAnyContacts(
        query: OCKContactQuery,
        callbackQueue: DispatchQueue = .main,
        completion: @Sendable @escaping (Result<[OCKAnyContact], OCKStoreError>) -> Void
    ) {
        let respondingStores = storesHandlingQuery(query)

        let closures = respondingStores.map({ store in { done in
            store.fetchAnyContacts(query: query, callbackQueue: callbackQueue, completion: done) }
        })
        aggregateAndFlatten(closures, callbackQueue: callbackQueue, completion: completion)
    }

    public func addAnyContacts(
        _ contacts: [OCKAnyContact],
        callbackQueue: DispatchQueue = .main,
        completion: (@Sendable (Result<[OCKAnyContact], OCKStoreError>) -> Void)? = nil
    ) {
        do {
            let store = try firstStoreHandlingContacts(contacts)
            store.addAnyContacts(contacts, callbackQueue: callbackQueue, completion: completion)
        } catch {
            callbackQueue.async {
                completion?(.failure(.addFailed(
                    reason: "Failed to find store accepting contacts. Error: \(error.localizedDescription)")))
            }
        }
    }

    public func updateAnyContacts(
        _ contacts: [OCKAnyContact],
        callbackQueue: DispatchQueue = .main,
        completion: (@Sendable (Result<[OCKAnyContact], OCKStoreError>) -> Void)? = nil
    ) {
        do {
            let store = try firstStoreHandlingContacts(contacts)
            store.updateAnyContacts(contacts, callbackQueue: callbackQueue, completion: completion)
        } catch {
            callbackQueue.async {
                completion?(.failure(.updateFailed(
                    reason: "Failed to find store accepting contacts. Error: \(error.localizedDescription)")))
            }
        }
    }

    public func deleteAnyContacts(
        _ contacts: [OCKAnyContact],
        callbackQueue: DispatchQueue = .main,
        completion: (@Sendable (Result<[OCKAnyContact], OCKStoreError>) -> Void)? = nil
    ) {
        do {
            let store = try firstStoreHandlingContacts(contacts)
            store.deleteAnyContacts(contacts, callbackQueue: callbackQueue, completion: completion)
        } catch {
            callbackQueue.async {
                completion?(.failure(.deleteFailed(
                    reason: "Failed to find store accepting contacts. Error: \(error.localizedDescription)")))
            }
        }
    }

    private func firstStoreHandlingContacts(_ contacts: [OCKAnyContact]) throws -> OCKAnyContactStore {

        let firstMatchingStore = state.withLock { state in

            return state.contactStores.first { store in
                return contacts.allSatisfy { contact in
                    return
                        state.delegate?.contactStore(store, shouldHandleWritingContact: contact) ??
                        contactStore(store, shouldHandleWritingContact: contact)
                }
            }
        }

        guard let firstMatchingStore else {
            throw OCKStoreError.invalidValue(reason: "Cannot find store to handle contacts")
        }

        return firstMatchingStore
    }

    private func storesHandlingQuery(_ query: OCKContactQuery) -> [OCKAnyReadOnlyContactStore] {

        return state.withLock { state in

            let stores = state.readOnlyContactStores + state.contactStores

            let respondingStores = stores.filter { store in
                return
                    state.delegate?.contactStore(store, shouldHandleQuery: query) ??
                    contactStore(store, shouldHandleQuery: query)

            }

            return respondingStores
        }
    }
}
