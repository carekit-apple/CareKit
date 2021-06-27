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

import CoreData

extension OCKStore {

    open func fetchContacts(query: OCKContactQuery = OCKContactQuery(), callbackQueue: DispatchQueue = .main,
                            completion: @escaping (Result<[OCKContact], OCKStoreError>) -> Void) {
        fetchValues(
            predicate: buildPredicate(for: query),
            sortDescriptors: buildSortDescriptors(for: query),
            offset: query.offset,
            limit: query.limit) { result in

            callbackQueue.async {
                completion(result)
            }
        }
    }

    open func addContacts(_ contacts: [OCKContact], callbackQueue: DispatchQueue = .main,
                          completion: ((Result<[OCKContact], OCKStoreError>) -> Void)? = nil) {
        transaction(inserts: contacts, updates: [], deletes: []) { result in
            callbackQueue.async {
                completion?(result.map(\.inserts))
            }
        }
    }

    open func updateContacts(_ contacts: [OCKContact], callbackQueue: DispatchQueue = .main,
                             completion: OCKResultClosure<[OCKContact]>? = nil) {
        transaction(inserts: [], updates: contacts, deletes: []) { result in
            callbackQueue.async {
                completion?(result.map(\.updates))
            }
        }
    }

    open func deleteContacts(_ contacts: [OCKContact], callbackQueue: DispatchQueue = .main,
                             completion: ((Result<[OCKContact], OCKStoreError>) -> Void)? = nil) {
        transaction(inserts: [], updates: [], deletes: contacts) { result in
            callbackQueue.async {
                completion?(result.map(\.deletes))
            }
        }
    }

    private func buildPredicate(for query: OCKContactQuery) -> NSPredicate {
        var predicate = query.basicPredicate(enforceDateInterval: true)

        if !query.carePlanIDs.isEmpty {
            let planPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDContact.carePlan.id), query.carePlanIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, planPredicate])
        }

        if !query.carePlanUUIDs.isEmpty {
            let objectPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDContact.carePlan.uuid), query.carePlanUUIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, objectPredicate])
        }

        if !query.carePlanRemoteIDs.isEmpty {
            let remotePredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDContact.carePlan.remoteID), query.carePlanRemoteIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, remotePredicate])
        }

        return predicate
    }

    private func buildSortDescriptors(for query: OCKContactQuery) -> [NSSortDescriptor] {
        query.sortDescriptors.map { order -> NSSortDescriptor in
            switch order {
            case .effectiveDate(ascending: let ascending): return NSSortDescriptor(keyPath: \OCKCDContact.effectiveDate, ascending: ascending)
            case .familyName(ascending: let ascending): return NSSortDescriptor(keyPath: \OCKCDContact.name.familyName, ascending: ascending)
            case .givenName(ascending: let ascending): return NSSortDescriptor(keyPath: \OCKCDContact.name.givenName, ascending: ascending)
            }
        } + query.defaultSortDescriptors()
    }
}
