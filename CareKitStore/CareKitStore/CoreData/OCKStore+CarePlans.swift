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

extension OCKStore {

    /// Determines whether or not this store is intended to handle adding, updating, and deleting a certain care plan.
    /// - Parameter plan: The care plan that is about to be modified.
    /// - Note: `OCKStore` returns true for all care plans.
    open func shouldHandleCarePlan(_ plan: OCKAnyCarePlan) -> Bool { true }

    /// Determines whether or not this store is intended to handle fetching for a certain query.
    /// - Parameter query: The query that will be performed.
    /// - Note: `OCKStore` returns true for all cases.
    open func shouldHandleCarePlanQuery(query: OCKAnyCarePlanQuery) -> Bool { true }

    open func fetchCarePlans(query: OCKCarePlanQuery = OCKCarePlanQuery(),
                             callbackQueue: DispatchQueue = .main, completion: @escaping (Result<[OCKCarePlan], OCKStoreError>) -> Void) {
        context.perform {
            do {
                let predicate = try self.buildPredicate(for: query)
                let persistedPlans = OCKCDCarePlan.fetchFromStore(in: self.context, where: predicate) { fetchRequest in
                    fetchRequest.fetchLimit = query.limit ?? 0
                    fetchRequest.fetchOffset = query.offset
                    fetchRequest.sortDescriptors = self.buildSortDescriptors(from: query)
                }

                let plans = persistedPlans
                    .map(self.makePlan)
                    .filter({ $0.matches(tags: query.tags) })

                callbackQueue.async { completion(.success(plans)) }
            } catch {
                self.context.rollback()
                callbackQueue.async { completion(.failure(.fetchFailed(reason: "Building predicate failed: \(error.localizedDescription)"))) }
            }
        }
    }

    open func addCarePlans(_ plans: [OCKCarePlan], callbackQueue: DispatchQueue = .main,
                           completion: ((Result<[OCKCarePlan], OCKStoreError>) -> Void)? = nil) {
        context.perform {
            do {
                try OCKCDCarePlan.validateNewIDs(plans.map { $0.id }, in: self.context)
                let persistablePlans = plans.map(self.createCarePlan)
                try self.context.save()
                let addedPlans = persistablePlans.map(self.makePlan)
                callbackQueue.async {
                    self.carePlanDelegate?.carePlanStore(self, didAddCarePlans: addedPlans)
                    completion?(.success(addedPlans))
                }
            } catch {
                self.context.rollback()
                callbackQueue.async {
                    completion?(.failure(.addFailed(reason: "Failed to add OCKCarePlans: [\(plans)]. \(error.localizedDescription)")))
                }
            }
        }
    }

    open func updateCarePlans(_ plans: [OCKCarePlan], callbackQueue: DispatchQueue = .main,
                              completion: ((Result<[OCKCarePlan], OCKStoreError>) -> Void)? = nil) {
        context.perform {
            do {
                let ids = plans.map { $0.id }
                try OCKCDCarePlan.validateUpdateIdentifiers(ids, in: self.context)
                let updatedPlans = try self.performVersionedUpdate(values: plans, addNewVersion: self.createCarePlan)
                try self.context.save()
                let plans = updatedPlans.map(self.makePlan)
                callbackQueue.async {
                    self.carePlanDelegate?.carePlanStore(self, didUpdateCarePlans: plans)
                    completion?(.success(updatedPlans.map(self.makePlan)))
                }
            } catch {
                self.context.rollback()
                callbackQueue.async {
                    completion?(.failure(.updateFailed(reason: "Failed to update OCKCarePlans: \(plans). \(error.localizedDescription)")))
                }
            }
        }
    }

    open func deleteCarePlans(_ plans: [OCKCarePlan], callbackQueue: DispatchQueue = .main,
                              completion: ((Result<[OCKCarePlan], OCKStoreError>) -> Void)? = nil) {
        context.perform {
            do {
                let markedPlans: [OCKCDCarePlan] = try self.performDeletion(values: plans)
                try self.context.save()
                let deletedPlans = markedPlans.map(self.makePlan)
                callbackQueue.async {
                    self.carePlanDelegate?.carePlanStore(self, didDeleteCarePlans: deletedPlans)
                    completion?(.success(deletedPlans))
                }
            } catch {
                self.context.rollback()
                callbackQueue.async {
                    completion?(.failure(.deleteFailed(reason: "Failed to update OCKCarePlans: [\(plans)]. \(error.localizedDescription)")))
                }
            }
        }
    }

    // MARK: Private

    /// - Remark: This does not commit the transaction. After calling this function one or more times, you must call `context.save()` in order to
    /// persist the changes to disk. This is an optimization to allow batching.
    /// - Remark: You should verify that the object does not already exist in the database and validate its values before calling this method.
    private func createCarePlan(from plan: OCKCarePlan) -> OCKCDCarePlan {
        let persistablePlan = OCKCDCarePlan(context: context)
        persistablePlan.copyVersionInfo(from: plan)
        persistablePlan.allowsMissingRelationships = configuration.allowsEntitiesWithMissingRelationships
        persistablePlan.title = plan.title
        if let patientId = plan.patientID { persistablePlan.patient = try? fetchObject(havingLocalID: patientId) }
        return persistablePlan
    }

    /// - Remark: This method is intended to create a value type struct from a *persisted* NSManagedObject. Calling this method with an
    /// object that is not yet commited is a programmer error.
    private func makePlan(from object: OCKCDCarePlan) -> OCKCarePlan {
        assert(object.localDatabaseID != nil, "Don't this method with an object that isn't saved yet")
        var plan = OCKCarePlan(id: object.id, title: object.title, patientID: object.patient?.localDatabaseID)
        plan.copyVersionedValues(from: object)
        return plan
    }

    private func buildPredicate(for query: OCKCarePlanQuery) throws -> NSPredicate {
        var predicate = OCKCDVersionedObject.notDeletedPredicate

        if let interval = query.dateInterval {
            let intervalPredicate = OCKCDVersionedObject.newestVersionPredicate(in: interval)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, intervalPredicate])
        }

        if !query.ids.isEmpty {
            let idPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDVersionedObject.id), query.ids)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, idPredicate])
        }

        if !query.versionIDs.isEmpty {
            let versionPredicate = NSPredicate(format: "self IN %@", try query.versionIDs.map(objectID))
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, versionPredicate])
        }

        if !query.remoteIDs.isEmpty {
            let remotePredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDObject.remoteID), query.remoteIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, remotePredicate])
        }

        if !query.patientIDs.isEmpty {
            let patientPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDCarePlan.patient.id), query.patientIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, patientPredicate])
        }

        if !query.patientVersionIDs.isEmpty {
            let versionPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDCarePlan.patient), try query.patientVersionIDs.map(fetchObject))
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, versionPredicate])
        }

        if !query.patientRemoteIDs.isEmpty {
            let remotePredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDCarePlan.patient.remoteID), query.patientRemoteIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, remotePredicate])
        }

        if !query.groupIdentifiers.isEmpty {
            predicate = predicate.including(groupIdentifiers: query.groupIdentifiers)
        }

        return predicate
    }

    private func buildSortDescriptors(from query: OCKCarePlanQuery?) -> [NSSortDescriptor] {
        guard let orders = query?.extendedSortDescriptors else { return [] }
        return orders.map { order -> NSSortDescriptor in
            switch order {
            case .effectiveDate(let ascending): return NSSortDescriptor(keyPath: \OCKCDCarePlan.effectiveDate, ascending: ascending)
            case .title(let ascending): return NSSortDescriptor(keyPath: \OCKCDCarePlan.title, ascending: ascending)
            }
        }
    }
}
