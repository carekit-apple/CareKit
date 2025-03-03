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
import Foundation
import os.log

extension OCKStore {

    public func carePlans(matching query: OCKCarePlanQuery) -> CareStoreQueryResults<OCKCarePlan> {

        // Setup a live query

        let predicate = buildPredicate(for: query)
        let sortDescriptors = buildSortDescriptors(from: query)

        let monitor = CoreDataQueryMonitor(
            OCKCDCarePlan.self,
            predicate: predicate,
            sortDescriptors: sortDescriptors,
            context: context
        )

        // Wrap the live query in an async stream

        let coreDataCarePlans = monitor.results()

        // Convert Core Data results to DTOs

        let carePlans = coreDataCarePlans
            .map { carePlans in
                carePlans.map { $0.makePlan() }
            }

        // Wrap the final transformed stream to hide all implementation details from
        // the public API

        let wrappedCarePlans = CareStoreQueryResults(wrapping: carePlans)
        return wrappedCarePlans
    }

    public func fetchCarePlans(
        query: OCKCarePlanQuery = OCKCarePlanQuery(),
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[OCKCarePlan], OCKStoreError>) -> Void
    ) {
        fetchValues(
            predicate: buildPredicate(for: query),
            sortDescriptors: buildSortDescriptors(from: query),
            offset: query.offset,
            limit: query.limit) { result in

            callbackQueue.async {
                completion(result)
            }
        }
    }

    public func addCarePlans(
        _ plans: [OCKCarePlan],
        callbackQueue: DispatchQueue = .main,
        completion: ((Result<[OCKCarePlan], OCKStoreError>) -> Void)? = nil
    ) {
        transaction(inserts: plans, updates: [], deletes: []) { result in
            callbackQueue.async {
                completion?(result.map(\.inserts))
            }
        }
    }

    public func updateCarePlans(
        _ plans: [OCKCarePlan],
        callbackQueue: DispatchQueue = .main,
        completion: ((Result<[OCKCarePlan], OCKStoreError>) -> Void)? = nil
    ) {
        transaction(inserts: [], updates: plans, deletes: []) { result in
            callbackQueue.async {
                completion?(result.map(\.updates))
            }
        }
    }

    public func deleteCarePlans(
        _ plans: [OCKCarePlan], callbackQueue: DispatchQueue = .main,
        completion: ((Result<[OCKCarePlan], OCKStoreError>) -> Void)? = nil
    ) {
        transaction(inserts: [], updates: [], deletes: plans) { result in
            callbackQueue.async {
                completion?(result.map(\.deletes))
            }
        }
    }

    private func buildPredicate(for query: OCKCarePlanQuery) -> NSPredicate {
        var predicate = query.basicPredicate(enforceDateInterval: true)

        if !query.patientIDs.isEmpty {
            let patientPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDCarePlan.patient.id), query.patientIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, patientPredicate])
        }

        if !query.patientUUIDs.isEmpty {
            let objectPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDCarePlan.patient.uuid), query.patientUUIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, objectPredicate])
        }

        if !query.patientRemoteIDs.isEmpty {
            let remotePredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDCarePlan.patient.remoteID), query.patientRemoteIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, remotePredicate])
        }

        return predicate
    }

    private func buildSortDescriptors(from query: OCKCarePlanQuery) -> [NSSortDescriptor] {
        query.sortDescriptors.map { order -> NSSortDescriptor in
            switch order {
            case .effectiveDate(let ascending): return NSSortDescriptor(keyPath: \OCKCDCarePlan.effectiveDate, ascending: ascending)
            case .title(let ascending): return NSSortDescriptor(keyPath: \OCKCDCarePlan.title, ascending: ascending)
            case .groupIdentifier(let ascending): return NSSortDescriptor(keyPath: \OCKCDCarePlan.groupIdentifier, ascending: ascending)
            }
        } + query.defaultSortDescriptors()
    }
}
