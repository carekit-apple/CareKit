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

extension OCKStore {

    open func fetchOutcomes(query: OCKOutcomeQuery = OCKOutcomeQuery(), callbackQueue: DispatchQueue = .main,
                            completion: @escaping (Result<[OCKOutcome], OCKStoreError>) -> Void) {
        context.perform {
            do {
                let predicate = try self.buildPredicate(for: query)
                let objects = OCKCDOutcome.fetchFromStore(in: self.context, where: predicate) { fetchRequest in
                    fetchRequest.fetchLimit = query.limit ?? 0
                    fetchRequest.fetchOffset = query.offset
                    fetchRequest.sortDescriptors = self.buildSortDescriptors(for: query)
                }

                let outcomes = try objects.map(self.makeOutcome)
                callbackQueue.async { completion(.success(outcomes)) }
            } catch {
                self.context.rollback()
                let reason = "Failed to fetch outcomes with query: \(String(describing: query)). \(error.localizedDescription)"
                callbackQueue.async { completion(.failure(.fetchFailed(reason: reason))) }
            }
        }
    }

    open func addOutcomes(_ outcomes: [OCKOutcome], callbackQueue: DispatchQueue = .main,
                          completion: ((Result<[OCKOutcome], OCKStoreError>) -> Void)? = nil) {
        context.perform {
            do {
                let persistableOutcomes = outcomes.map(self.createOutcome)
                try self.context.save()
                let updatedOutcomes = try persistableOutcomes.map(self.makeOutcome)
                callbackQueue.async {
                    self.outcomeDelegate?.outcomeStore(self, didAddOutcomes: updatedOutcomes)
                    completion?(.success(updatedOutcomes))
                }
            } catch {
                self.context.rollback()
                callbackQueue.async {
                    completion?(.failure(.addFailed(reason: "Failed to insert OKCOutomes: [\(outcomes)]. \(error.localizedDescription)")))
                }
            }
        }
    }

    open func updateOutcomes(_ outcomes: [OCKOutcome], callbackQueue: DispatchQueue = .main,
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
            let updatedOutcomes = try currentOutcomes.map(makeOutcome)
            callbackQueue.async {
                self.outcomeDelegate?.outcomeStore(self, didUpdateOutcomes: updatedOutcomes)
                completion?(.success(updatedOutcomes))
            }
        } catch {
            context.rollback()
            callbackQueue.async {
                completion?(.failure(.updateFailed(reason: "Failed to update OCKOutcomes: [\(outcomes)]. \(error.localizedDescription)")))
            }
        }
    }

    open func deleteOutcomes(_ outcomes: [OCKOutcome], callbackQueue: DispatchQueue = .main,
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
                callbackQueue.async {
                    self.outcomeDelegate?.outcomeStore(self, didDeleteOutcomes: outcomes)
                    completion?(.success(outcomes))
                }
            } catch {
                self.context.rollback()
                callbackQueue.async {
                    completion?(.failure(.deleteFailed(reason: "Failed to delete OCKOutcomes: [\(outcomes)]. \(error.localizedDescription)")))
                }
            }
        }
    }

    // MARK: Private

    private func createOutcome(from outcome: OCKOutcome) -> OCKCDOutcome {
        let persistableOutcome = OCKCDOutcome(context: context)
        copyOutcome(outcome, to: persistableOutcome)
        return persistableOutcome
    }

    private func copyOutcome(_ outcome: OCKOutcome, to persistableOutcome: OCKCDOutcome) {
        persistableOutcome.copyValues(from: outcome)
        persistableOutcome.values = Set(outcome.values.map(createValue))
        persistableOutcome.taskOccurrenceIndex = outcome.taskOccurrenceIndex
        if let task: OCKCDTask = try? fetchObject(havingLocalID: outcome.taskID) {
            let schedule = makeSchedule(elements: Array(task.scheduleElements))
            persistableOutcome.date = schedule.event(forOccurrenceIndex: outcome.taskOccurrenceIndex)?.start
            persistableOutcome.task = task
        }
    }

    /// - Remark: This method is intended to create a value type struct from a *persisted* NSManagedObject. Calling this method with an
    /// object that is not yet commited is a programmer error.
    private func makeOutcome(from object: OCKCDOutcome) throws -> OCKOutcome {
        assert(object.localDatabaseID != nil, "You shouldn't be calling this method with an object that hasn't been saved yet!")
        guard let taskID = object.task?.localDatabaseID else { throw OCKStoreError.invalidValue(reason: "Couldn't find a task for the outcome!") }
        let responses = object.values.map(makeValue)
        var outcome = OCKOutcome(taskID: taskID, taskOccurrenceIndex: object.taskOccurrenceIndex, values: responses)
        outcome.copyCommonValues(from: object)
        return outcome
    }

    private func buildPredicate(for query: OCKOutcomeQuery) throws -> NSPredicate {
        var predicate = NSPredicate(value: true)

        if let interval = query.dateInterval {
            let afterPredicate = NSPredicate(format: "%K >= %@", #keyPath(OCKCDOutcome.date), interval.start as NSDate)
            let beforePredicate = NSPredicate(format: "%K < %@", #keyPath(OCKCDOutcome.date), interval.end as NSDate)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, afterPredicate, beforePredicate])
        }

        if !query.localIDs.isEmpty {
            let localPredicate = NSPredicate(format: "self IN %@", try query.localIDs.map { try objectID(for: $0) })
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, localPredicate])
        }

        if !query.remoteIDs.isEmpty {
            let remotePredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDVersionedObject.remoteID), query.remoteIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, remotePredicate])
        }

        if !query.taskIDs.isEmpty {
            let taskPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDOutcome.task.id), query.taskIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, taskPredicate])
        }

        if !query.taskVersionIDs.isEmpty {
            let taskPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDOutcome.task), try query.taskVersionIDs.map { try objectID(for: $0) })
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, taskPredicate])
        }

        if !query.taskRemoteIDs.isEmpty {
            let taskPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDOutcome.task.remoteID), query.taskRemoteIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, taskPredicate])
        }

        if !query.groupIdentifiers.isEmpty {
            predicate = predicate.including(groupIdentifiers: query.groupIdentifiers)
        }

        if !query.tags.isEmpty {
            predicate = predicate.including(tags: query.tags)
        }

        return predicate
    }

    private func buildSortDescriptors(for query: OCKOutcomeQuery?) -> [NSSortDescriptor] {
        guard let orders = query?.extendedSortDescriptors else { return [] }
        return orders.map { order -> NSSortDescriptor in
            switch order {
            case .date(ascending: let ascending): return NSSortDescriptor(keyPath: \OCKCDOutcome.date, ascending: ascending)
            }
        }
    }
}
