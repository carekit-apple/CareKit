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

public extension OCKStore {
    func fetchOutcomes(_ anchor: OCKOutcomeAnchor? = nil, query: OCKOutcomeQuery? = nil, queue: DispatchQueue = .main,
                       completion: @escaping (Result<[OCKOutcome], OCKStoreError>) -> Void) {
        context.perform {
            do {
                let predicate = try self.buildPredicate(for: anchor, and: query)
                let objects = OCKCDOutcome.fetchFromStore(in: self.context, where: predicate) { fetchRequest in
                    fetchRequest.fetchLimit = query?.limit ?? 0
                    fetchRequest.fetchOffset = query?.offset ?? 0
                    fetchRequest.sortDescriptors = self.buildSortDescriptors(for: query)
                }

                let outcomes = objects.map(self.makeOutcome)
                queue.async { completion(.success(outcomes)) }
            } catch {
                self.context.rollback()
                let reason = "Failed to fetch outcomes with query: \(String(describing: query)). \(error.localizedDescription)"
                queue.async { completion(.failure(.fetchFailed(reason: reason))) }
            }
        }
    }

    func addOutcomes(_ outcomes: [OCKOutcome], queue: DispatchQueue = .main,
                     completion: ((Result<[OCKOutcome], OCKStoreError>) -> Void)? = nil) {
        context.perform {
            do {
                let persistableOutcomes = outcomes.map { self.addOutcome($0) }
                try self.context.save()
                let updatedOutcomes = persistableOutcomes.map(self.makeOutcome)
                queue.async {
                    self.delegate?.store(self, didAddOutcomes: updatedOutcomes)
                    completion?(.success(updatedOutcomes))
                }
            } catch {
                self.context.rollback()
                queue.async {
                    completion?(.failure(.addFailed(reason: "Failed to insert OKCOutomes: [\(outcomes)]. \(error.localizedDescription)")))
                }
            }
        }
    }

    func updateOutcomes(_ outcomes: [OCKOutcome], queue: DispatchQueue = .main,
                        completion: ((Result<[OCKOutcome], OCKStoreError>) -> Void)? = nil) {
        do {
            let objectIDs = try retrieveObjectIDs(for: outcomes)
            let predicate = NSPredicate(format: "self IN %@", objectIDs)
            let currentOutcomes = OCKCDOutcome.fetchFromStore(in: context, where: predicate)
            for (outcomeIndex, objectID) in objectIDs.enumerated() {
                guard let index = currentOutcomes.firstIndex(where: { $0.objectID == objectID }) else {
                    throw OCKStoreError.updateFailed(reason: "No OCKOutcome with matching ID could be found: \(objectID)")
                }
                copyOutcome(outcomes[outcomeIndex], to: currentOutcomes[index])
            }
            try context.save()
            let updatedOutcomes = currentOutcomes.map(makeOutcome)
            queue.async {
                self.delegate?.store(self, didUpdateOutcomes: updatedOutcomes)
                completion?(.success(updatedOutcomes))
            }
        } catch {
            context.rollback()
            queue.async {
                completion?(.failure(.updateFailed(reason: "Failed to update OCKOutcomes: [\(outcomes)]. \(error.localizedDescription)")))
            }
        }
    }

    func deleteOutcomes(_ outcomes: [OCKOutcome], queue: DispatchQueue = .main,
                        completion: ((Result<[OCKOutcome], OCKStoreError>) -> Void)? = nil) {
        context.perform {
            do {
                let objectIDs = try self.retrieveObjectIDs(for: outcomes)
                let predicate = NSPredicate(format: "self IN %@", objectIDs)
                let persistableOutcomes: [OCKCDOutcome] = OCKCDOutcome.fetchFromStore(in: self.context, where: predicate) { request in
                    request.fetchLimit = outcomes.count
                }
                guard persistableOutcomes.count == outcomes.count else {
                    throw OCKStoreError.deleteFailed(reason: "Not all OCKOutcomes could be found to be deleted")
                }
                persistableOutcomes.forEach { self.context.delete($0) }
                try self.context.save()
                queue.async {
                    self.delegate?.store(self, didDeleteOutcomes: outcomes)
                    completion?(.success(outcomes))
                }
            } catch {
                self.context.rollback()
                queue.async {
                    completion?(.failure(.deleteFailed(reason: "Failed to delete OCKOutcomes: [\(outcomes)]. \(error.localizedDescription)")))
                }
            }
        }
    }

    // MARK: Private

    /// - Remark: This does not commit the transaction. After calling this function one or more times, you must call `context.save()` in order to
    /// persist the changes to disk. This is an optimization to allow batching.
    /// - Remark: You should verify that the object does not already exist in the database and validate its values before calling this method.
    private func addOutcome(_ outcome: OCKOutcome) -> OCKCDOutcome {
        let persistableOutcome = OCKCDOutcome(context: context)
        copyOutcome(outcome, to: persistableOutcome)
        return persistableOutcome
    }

    private func copyOutcome(_ outcome: OCKOutcome, to persistableOutcome: OCKCDOutcome) {
        persistableOutcome.copyValues(from: outcome)
        persistableOutcome.allowsMissingRelationships = allowsEntitiesWithMissingRelationships
        persistableOutcome.values = Set(outcome.values.map(addValue))
        persistableOutcome.taskOccurenceIndex = outcome.taskOccurenceIndex
        if let taskID = outcome.taskID, let task: OCKCDTask = try? fetchObject(havingLocalID: taskID) {
            let schedule = makeSchedule(from: task.scheduleElements)
            persistableOutcome.date = schedule.event(forOccurenceIndex: outcome.taskOccurenceIndex)?.start
            persistableOutcome.task = task
        }
    }

    /// - Remark: This does not commit the transaction. After calling this function one or more times, you must call `context.save()` in order to
    /// persist the changes to disk. This is an optimization to allow batching.
    internal func addValue(_ value: OCKOutcomeValue) -> OCKCDOutcomeValue {
        let object = OCKCDOutcomeValue(context: context)
        object.copyValues(from: value)
        object.value = value.value
        object.kind = value.kind
        object.units = value.units
        object.index = value.index == nil ? nil : NSNumber(value: value.index!)
        return object
    }

    /// - Remark: This method is intended to create a value type struct from a *persisted* NSManagedObject. Calling this method with an
    /// object that is not yet commited is a programmer error.
    private func makeOutcome(from object: OCKCDOutcome) -> OCKOutcome {
        assert(object.localDatabaseID != nil, "You shouldn't be calling this method with an object that hasn't been saved yet!")
        let responses = object.values.map(makeValue)
        var outcome = OCKOutcome(taskID: object.task?.localDatabaseID, taskOccurenceIndex: object.taskOccurenceIndex, values: responses)
        outcome.copyCommonValues(from: object)
        return outcome
    }
    private func buildPredicate(for anchor: OCKOutcomeAnchor?, and query: OCKOutcomeQuery?) throws -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            try buildSubquery(for: anchor),
            buildSubquery(for: query)
        ])
    }

    private func buildSubquery(for anchor: OCKOutcomeAnchor?) throws -> NSPredicate {
        guard let anchor = anchor else { return NSPredicate(value: true) }
        switch anchor {
        case .taskIdentifiers(let taskIdentifiers):
            return NSPredicate(format: "%K IN %@", #keyPath(OCKCDOutcome.task.identifier), taskIdentifiers)
        case .taskVersions(let taskVersionedLocalIDs):
            return NSPredicate(format: "%K IN %@", #keyPath(OCKCDOutcome.task), try taskVersionedLocalIDs.map { try objectID(for: $0) })
        case .taskRemoteIDs(let remoteIDs):
            return NSPredicate(format: "%K IN %@", #keyPath(OCKCDOutcome.task.remoteID), remoteIDs)

        case .outcomeVersions(let outcomeVersionedLocalIDs):
            return NSPredicate(format: "self IN %@", try outcomeVersionedLocalIDs.map { try objectID(for: $0) })
        case .outcomeRemoteIDs(let remoteIDs):
            return NSPredicate(format: "%K IN %@", #keyPath(OCKCDVersionedObject.remoteID), remoteIDs)
        }
    }

    private func buildSubquery(for query: OCKOutcomeQuery?) -> NSPredicate {
        guard let query = query else { return NSPredicate(value: true) }
        let afterPredicate = NSPredicate(format: "%K >= %@", #keyPath(OCKCDOutcome.date), query.start as NSDate)
        let beforePredicate = NSPredicate(format: "%K < %@", #keyPath(OCKCDOutcome.date), query.end as NSDate)
        var predicate: NSPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [afterPredicate, beforePredicate])
        if let groupIdentifiers = query.groupIdentifiers {
            predicate = predicate.including(groupIdentifiers: groupIdentifiers)
        }
        if let tags = query.tags {
            predicate = predicate.including(tags: tags)
        }
        return predicate
    }

    private func buildSortDescriptors(for query: OCKOutcomeQuery?) -> [NSSortDescriptor] {
        guard let orders = query?.sortDescriptors else { return [] }
        return orders.map { order -> NSSortDescriptor in
            switch order {
            case .date(ascending: let ascending): return NSSortDescriptor(keyPath: \OCKCDOutcome.date, ascending: ascending)
            }
        }
    }
}
