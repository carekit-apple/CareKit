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

    open func fetchOutcomes(query: OCKOutcomeQuery = OCKOutcomeQuery(), callbackQueue: DispatchQueue = .main,
                            completion: @escaping (Result<[OCKOutcome], OCKStoreError>) -> Void) {
        context.perform {
            do {
                let request = NSFetchRequest<OCKCDOutcome>(entityName: String(describing: OCKCDOutcome.self))
                request.fetchLimit = query.limit ?? 0
                request.fetchOffset = query.offset
                request.sortDescriptors = self.buildSortDescriptors(for: query)
                request.predicate = self.buildPredicate(for: query)
                let objects = try self.context.fetch(request)

                let outcomes = objects
                    .map(self.makeOutcome)
                    .filter({ $0.matches(tags: query.tags) })

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
                let updatedOutcomes = try self.createOutcomesWithoutCommiting(outcomes)
                try self.context.save()
                callbackQueue.async {
                    self.outcomeDelegate?.outcomeStore(self, didAddOutcomes: updatedOutcomes)
                    self.autoSynchronizeIfRequired()
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
        context.perform {
            do {
                let updated = try self.updateOutcomesLeavingTombstone(outcomes)
                try self.context.save()
                callbackQueue.async {
                    self.outcomeDelegate?.outcomeStore(self, didUpdateOutcomes: updated)
                    self.autoSynchronizeIfRequired()
                    completion?(.success(updated))
                }
            } catch {
                self.context.rollback()
                callbackQueue.async {
                    completion?(.failure(.updateFailed(reason: error.localizedDescription)))
                }
            }
        }
    }

    open func deleteOutcomes(_ outcomes: [OCKOutcome], callbackQueue: DispatchQueue = .main,
                             completion: ((Result<[OCKOutcome], OCKStoreError>) -> Void)? = nil) {
        context.perform {
            do {
                let deleted = outcomes.map { outcome -> OCKOutcome in
                    var delete = outcome
                    delete.deletedDate = Date()
                    return delete
                }

                _ = try self.updateOutcomesLeavingTombstone(deleted)
                try self.context.save()
                callbackQueue.async {
                    self.outcomeDelegate?.outcomeStore(self, didDeleteOutcomes: deleted)
                    self.autoSynchronizeIfRequired()
                    completion?(.success(deleted))
                }
            } catch {
                self.context.rollback()
                callbackQueue.async {
                    completion?(.failure(.updateFailed(reason: error.localizedDescription)))
                }
            }
        }
    }

    // MARK: Internal
    // These methods are also used when syncing with a remote store.
    // Make sure these are always called from the context's queue.

    func createOutcomesWithoutCommiting(_ outcomes: [OCKOutcome]) throws -> [OCKOutcome] {
        try confirmOutcomesAreInValidRegionOfTaskVersionChain(outcomes)
        let persistableOutcomes = outcomes.map(self.createOutcome)
        let addedOutcomes = persistableOutcomes.map(self.makeOutcome)
        return addedOutcomes
    }

    // MARK: Private

    /// - WARNING: Must be called from context's thread.
    /// Deletes the given outcomes and replaces them with a new, updated versions.
    func updateOutcomesLeavingTombstone(_ outcomes: [OCKOutcome]) throws -> [OCKOutcome] {

        try self.confirmOutcomesAreInValidRegionOfTaskVersionChain(outcomes)
        let currentOutcomes = self.fetchMatchingOutcomes(outcomes)

        if currentOutcomes.count < outcomes.count {
            throw OCKStoreError.fetchFailed(reason: "Not all updates could be found.")
        } else if currentOutcomes.count > outcomes.count {
            throw OCKStoreError.fetchFailed(reason: "Found too many matching outcomes!")
        }

        currentOutcomes.forEach {
            $0.deletedDate = Date()
            $0.values = Set()
        }

        let newOutcomes = outcomes.map(self.createOutcome)
        newOutcomes.forEach { $0.uuid = UUID() }

        let updatedOutcomes = newOutcomes.map(self.makeOutcome)
        return updatedOutcomes
    }

    /// - WARNING: Must be called from context's thread.
    func fetchMatchingOutcomes(_ outcomes: [OCKOutcome]) -> [OCKCDOutcome] {
        let request = NSFetchRequest<OCKCDOutcome>(entityName: String(describing: OCKCDOutcome.self))
        request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: outcomes.map { outcome in
            NSPredicate(format: "%K == %@ AND %K == %lld AND %K == nil",
                        #keyPath(OCKCDOutcome.task.uuid), outcome.taskUUID as CVarArg,
                        #keyPath(OCKCDOutcome.taskOccurrenceIndex), Int64(outcome.taskOccurrenceIndex),
                        #keyPath(OCKCDOutcome.deletedDate))
        })
        let results = try! context.fetch(request)
        return results
    }

    // Confirms that outcomes cannot be added to past versions of a task in regions covered by a newer version.
    //
    // |<------------- Time Line --------------->|
    //  TaskV1 a-------b------------------->
    //                     V2 ---------->
    //                V3------------------>
    //
    // Throws an error if the outcome is added to V1 outside the region between `a` and `b`.
    // Throws an error if the outcome is added to V2 anywhere because V2 is fully eclipsed.
    // Does not throw an error for outcomes to added to V3 because V3 is the newest version.
    func confirmOutcomesAreInValidRegionOfTaskVersionChain(_ outcomes: [Outcome]) throws {
        for outcome in outcomes {
            var task: OCKCDTask = try fetchObject(uuid: outcome.taskUUID)
            let schedule = makeSchedule(elements: Array(task.scheduleElements))
            while let nextVersion = task.next as? OCKCDTask {
                let eventDate = schedule.event(forOccurrenceIndex: outcome.taskOccurrenceIndex)!.start
                if nextVersion.effectiveDate <= eventDate {
                    throw OCKStoreError.invalidValue(reason: """
                        Tried to place an outcome in a date range overshadowed by a future version of task.
                        The event for the outcome is dated \(eventDate), but a newer version of the task starts on \(nextVersion.effectiveDate).
                        """)
                }
                task = nextVersion
            }
        }
    }

    private func createOutcome(from outcome: OCKOutcome) -> OCKCDOutcome {
        let persistableOutcome = OCKCDOutcome(context: context)
        copyOutcome(outcome, to: persistableOutcome)
        return persistableOutcome
    }

    func copyOutcome(_ outcome: OCKOutcome, to persistableOutcome: OCKCDOutcome) {
        guard let task: OCKCDTask = try? fetchObject(uuid: outcome.taskUUID) else {
            fatalError("All outcomes should be owned by a task. The database is corrupt.")
        }
        let schedule = makeSchedule(elements: Array(task.scheduleElements))
        persistableOutcome.date = schedule.event(forOccurrenceIndex: outcome.taskOccurrenceIndex)!.start
        persistableOutcome.deletedDate = outcome.deletedDate
        persistableOutcome.copyValues(from: outcome)
        persistableOutcome.values = Set(outcome.values.map(createValue))
        persistableOutcome.taskOccurrenceIndex = Int64(outcome.taskOccurrenceIndex)
        persistableOutcome.task = task
    }

    func makeOutcome(from object: OCKCDOutcome) -> OCKOutcome {
        let responses = object.values.map(makeValue)
        var outcome = OCKOutcome(
            taskUUID: object.task.uuid,
            taskOccurrenceIndex: Int(object.taskOccurrenceIndex),
            values: responses)
        outcome.copyCommonValues(from: object)
        outcome.deletedDate = object.deletedDate
        return outcome
    }

    private func buildPredicate(for query: OCKOutcomeQuery) -> NSPredicate {
        var predicate = NSPredicate(format: "%K == nil AND %K == nil",
                                    #keyPath(OCKCDOutcome.deletedDate),
                                    #keyPath(OCKCDOutcome.task.deletedDate))

        if let interval = query.dateInterval {
            let afterPredicate = NSPredicate(format: "%K >= %@", #keyPath(OCKCDOutcome.date), interval.start as NSDate)
            let beforePredicate = NSPredicate(format: "%K < %@", #keyPath(OCKCDOutcome.date), interval.end as NSDate)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, afterPredicate, beforePredicate])
        }
        
        if !query.uuids.isEmpty {
            let versionPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDObject.uuid), query.uuids)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, versionPredicate])
        }

        if !query.uuids.isEmpty {
            let objectPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDObject.uuid), query.uuids)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, objectPredicate])
        }
     
        if !query.remoteIDs.isEmpty {
            predicate = predicate.including(query.remoteIDs, for: #keyPath(OCKCDObject.remoteID))
        }

        if !query.taskIDs.isEmpty {
            let taskPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDOutcome.task.id), query.taskIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, taskPredicate])
        }

        if !query.taskUUIDs.isEmpty {
            let taskPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDOutcome.task.uuid), query.taskUUIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, taskPredicate])
        }

        if !query.taskRemoteIDs.isEmpty {
            let taskPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDOutcome.task.remoteID), query.taskRemoteIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, taskPredicate])
        }

        if !query.groupIdentifiers.isEmpty {
            predicate = predicate.including(
                query.groupIdentifiers,
                for: #keyPath(OCKCDObject.groupIdentifier))
        }

        return predicate
    }

    private func buildSortDescriptors(for query: OCKOutcomeQuery) -> [NSSortDescriptor] {
        let orders = query.extendedSortDescriptors
        return orders.map { order -> NSSortDescriptor in
            switch order {
            case .date(let ascending): return NSSortDescriptor(keyPath: \OCKCDOutcome.date, ascending: ascending)
            case .createdDate(let ascending): return NSSortDescriptor(keyPath: \OCKCDOutcome.createdDate, ascending: ascending)
            }
        } + defaultSortDescritors()
    }
}
