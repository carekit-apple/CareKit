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
    public func fetchCarePlans(_ anchor: OCKCarePlanAnchor? = nil, query: OCKCarePlanQuery? = nil,
                               queue: DispatchQueue = .main, completion: @escaping (Result<[OCKCarePlan], OCKStoreError>) -> Void) {
        context.perform {
            do {
                let predicate = try self.buildPredicate(for: anchor, query: query)
                let persistedPlans = OCKCDCarePlan.fetchFromStore(in: self.context, where: predicate) { fetchRequest in
                    fetchRequest.fetchLimit = query?.limit ?? 0
                    fetchRequest.fetchOffset = query?.offset ?? 0
                    fetchRequest.sortDescriptors = self.buildSortDescriptors(from: query)
                }

                let plans = persistedPlans.map(self.makePlan)
                queue.async { completion(.success(plans)) }
            } catch {
                self.context.rollback()
                queue.async { completion(.failure(.fetchFailed(reason: "Building predicate failed: \(error.localizedDescription)"))) }
            }
        }
    }

    public func addCarePlans(_ plans: [OCKCarePlan], queue: DispatchQueue = .main,
                             completion: ((Result<[OCKCarePlan], OCKStoreError>) -> Void)? = nil) {
        context.perform {
            do {
                try OCKCDCarePlan.validateNewIdentifiers(plans.map { $0.identifier }, in: self.context)
                let persistablePlans = plans.map { self.addCarePlan($0) }
                try self.context.save()
                let addedPlans = persistablePlans.map(self.makePlan)
                queue.async {
                    self.delegate?.store(self, didAddCarePlans: addedPlans)
                    completion?(.success(addedPlans))
                }
            } catch {
                self.context.rollback()
                queue.async {
                    completion?(.failure(.addFailed(reason: "Failed to add OCKCarePlans: [\(plans)]. \(error.localizedDescription)")))
                }
            }
        }
    }

    public func updateCarePlans(_ plans: [OCKCarePlan], queue: DispatchQueue = .main,
                                completion: ((Result<[OCKCarePlan], OCKStoreError>) -> Void)? = nil) {
        context.perform {
            do {
                let identifiers = plans.map { $0.identifier }
                try OCKCDCarePlan.validateUpdateIdentifiers(identifiers, in: self.context)
                let updatedPlans = self.configuration.updatesCreateNewVersions ?
                    try self.performVersionedUpdate(values: plans, addNewVersion: self.addCarePlan) :
                    try self.performUnversionedUpdate(values: plans, update: self.copyPlan)

                try self.context.save()
                let plans = updatedPlans.map(self.makePlan)
                queue.async {
                    self.delegate?.store(self, didUpdateCarePlans: plans)
                    completion?(.success(updatedPlans.map(self.makePlan)))
                }
            } catch {
                self.context.rollback()
                queue.async {
                    completion?(.failure(.updateFailed(reason: "Failed to update OCKCarePlans: \(plans). \(error.localizedDescription)")))
                }
            }
        }
    }

    public func deleteCarePlans(_ plans: [OCKCarePlan], queue: DispatchQueue = .main,
                                completion: ((Result<[OCKCarePlan], OCKStoreError>) -> Void)? = nil) {
        context.perform {
            do {
                let deletedPlans = try self.performUnversionedUpdate(values: plans) { _, persistablePlan in
                    persistablePlan.deletedDate = Date()
                }.map(self.makePlan)

                try self.context.save()
                queue.async {
                    self.delegate?.store(self, didDeleteCarePlans: deletedPlans)
                    completion?(.success(deletedPlans))
                }
            } catch {
                self.context.rollback()
                queue.async {
                    completion?(.failure(.deleteFailed(reason: "Failed to update OCKCarePlans: [\(plans)]. \(error.localizedDescription)")))
                }
            }
        }
    }

    // MARK: Private

    /// - Remark: This does not commit the transaction. After calling this function one or more times, you must call `context.save()` in order to
    /// persist the changes to disk. This is an optimization to allow batching.
    /// - Remark: You should verify that the object does not already exist in the database and validate its values before calling this method.
    private func addCarePlan(_ plan: OCKCarePlan) -> OCKCDCarePlan {
        let persistablePlan = OCKCDCarePlan(context: context)
        copyPlan(plan, to: persistablePlan)
        return persistablePlan
    }

    /// - Remark: This method is intended to create a value type struct from a *persisted* NSManagedObject. Calling this method with an
    /// object that is not yet commited is a programmer error.
    private func makePlan(from object: OCKCDCarePlan) -> OCKCarePlan {
        assert(object.localDatabaseID != nil, "Don't this method with an object that isn't saved yet")
        var plan = OCKCarePlan(identifier: object.identifier, title: object.title, patientID: object.patient?.localDatabaseID)
        plan.copyVersionedValues(from: object)
        return plan
    }

    private func copyPlan(_ plan: OCKCarePlan, to object: OCKCDCarePlan) {
        object.copyVersionInfo(from: plan)
        object.allowsMissingRelationships = allowsEntitiesWithMissingRelationships
        object.title = plan.title
        if let patientId = plan.patientID { object.patient = try? fetchObject(havingLocalID: patientId) }
    }

    private func buildPredicate(for anchor: OCKCarePlanAnchor?, query: OCKCarePlanQuery?) throws -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            try buildSubPredicate(for: anchor),
            buildSubPredicate(for: query),
            NSPredicate(format: "%K == nil", #keyPath(OCKCDVersionedObject.deletedDate))
        ])
    }

    private func buildSubPredicate(for anchor: OCKCarePlanAnchor?) throws -> NSPredicate {
        guard let anchor = anchor else { return NSPredicate(value: true) }
        switch anchor {
        case .carePlanIdentifiers(let planIdentifiers):
            return NSPredicate(format: "%K IN %@", #keyPath(OCKCDVersionedObject.identifier), planIdentifiers)
        case .carePlanVersions(let planVersionIDs):
            return NSPredicate(format: "self IN %@", try planVersionIDs.map(objectID))
        case .carePlanRemoteIDs(let planRemoteIDs):
            return NSPredicate(format: "%K IN %@", #keyPath(OCKCDVersionedObject.remoteID), planRemoteIDs)

        case .patientVersions(let patientVersionIDs):
            return NSPredicate(format: "%K IN %@", #keyPath(OCKCDCarePlan.patient), try patientVersionIDs.map(objectID))
        case .patientIdentifiers(let patientIdentifiers):
            return NSPredicate(format: "%K IN %@", #keyPath(OCKCDCarePlan.patient.identifier), patientIdentifiers)
        case .patientRemoteIDs(let patientRemoteIDs):
            return NSPredicate(format: "%K IN %@", #keyPath(OCKCDCarePlan.patient.remoteID), patientRemoteIDs)
        }
    }

    private func buildSubPredicate(for query: OCKCarePlanQuery? = nil) -> NSPredicate {
        var predicate = NSPredicate(value: true)

        if let interval = query?.dateInterval {
            let datePredicate = OCKCDVersionedObject.newestVersionPredicate(in: interval)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, datePredicate])
        }

        if let groupIdentifiers = query?.groupIdentifiers {
            predicate = predicate.including(groupIdentifiers: groupIdentifiers)
        }

        if let tags = query?.tags {
            predicate = predicate.including(tags: tags)
        }

        return predicate
    }

    private func buildSortDescriptors(from query: OCKCarePlanQuery?) -> [NSSortDescriptor] {
        guard let orders = query?.sortDescriptors else { return [] }
        return orders.map { order -> NSSortDescriptor in
            switch order {
            case .effectiveDate(let ascending): return NSSortDescriptor(keyPath: \OCKCDCarePlan.effectiveDate, ascending: ascending)
            case .title(let ascending): return NSSortDescriptor(keyPath: \OCKCDCarePlan.title, ascending: ascending)
            }
        }
    }
}
