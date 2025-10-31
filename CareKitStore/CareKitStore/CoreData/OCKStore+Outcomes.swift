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

import CoreData
import Foundation
import os.log

extension OCKStore {

    public func outcomes(matching query: OCKOutcomeQuery) -> some AsyncSequence<[OCKOutcome], Error> & Sendable {

        // Setup a live query

        let predicate = buildPredicate(for: query)
        let sortDescriptors = buildSortDescriptors(for: query)

        return AsyncStreamFactory.coreDataResults(
            OCKCDOutcome.self,
            predicate: predicate,
            sortDescriptors: sortDescriptors,
            context: context
        )
        .map { $0 as! [Outcome] }
    }

    public func fetchOutcomes(
        query: OCKOutcomeQuery = OCKOutcomeQuery(),
        callbackQueue: DispatchQueue = .main,
        completion: @Sendable @escaping (Result<[OCKOutcome], OCKStoreError>) -> Void
    ) {
        context.perform {
            do {
                let request = NSFetchRequest<OCKCDOutcome>(entityName: String(describing: OCKCDOutcome.self))
                request.fetchLimit = query.limit ?? 0
                request.fetchOffset = query.offset
                request.returnsObjectsAsFaults = false
                request.sortDescriptors = self.buildSortDescriptors(for: query)
                request.predicate = self.buildPredicate(for: query)
                let objects = try self.context.fetch(request)
                let notTombstoned = objects.filter { !$0.newestVersionIsTombstone() }
                let outcomes = notTombstoned.map { $0.makeOutcome() }

                callbackQueue.async { completion(.success(outcomes)) }
            } catch {
                self.context.rollback()
                let reason = "Failed to fetch outcomes for query. \(error.localizedDescription)"
                callbackQueue.async { completion(.failure(.fetchFailed(reason: reason))) }
            }
        }
    }

    public func addOutcomes(
        _ outcomes: [OCKOutcome],
        callbackQueue: DispatchQueue = .main,
        completion: (@Sendable (Result<[OCKOutcome], OCKStoreError>) -> Void)? = nil
    ) {
        transaction(
            inserts: outcomes, updates: [], deletes: [],
            preInsertValidate: {
                let metadata = try self.computeEventMetadata(for: outcomes)
                try self.confirmOutcomesAreInValidRegionOfTaskVersionChain(metadata)
                try self.confirmOutcomesAreUnique(outcomes)
            }
        ) { result in
            callbackQueue.async {
                completion?(result.map(\.inserts))
            }
        }
    }

    public func updateOutcomes(
        _ outcomes: [OCKOutcome],
        callbackQueue: DispatchQueue = .main,
        completion: (@Sendable (Result<[OCKOutcome], OCKStoreError>) -> Void)? = nil
    ) {
        transaction(
            inserts: [], updates: outcomes, deletes: [],
            preUpdateValidate: {
                let metadata = try self.computeEventMetadata(for: outcomes)
                try self.confirmOutcomesAreInValidRegionOfTaskVersionChain(metadata)
            }
        ) { result in
            callbackQueue.async {
                completion?(result.map(\.updates))
            }
        }
    }

    public func deleteOutcomes(
        _ outcomes: [OCKOutcome],
        callbackQueue: DispatchQueue = .main,
        completion: (@Sendable (Result<[OCKOutcome], OCKStoreError>) -> Void)? = nil
    ) {
        transaction(inserts: [], updates: [], deletes: outcomes) { result in
            callbackQueue.async {
                completion?(result.map(\.deletes))
            }
        }
    }

    // MARK: Private

    private func computeEventMetadata(for outcomes: [Outcome]) throws -> [OutcomeMetadata] {

        // Fetch the task for each outcome. Group the tasks in a dictionary for easy lookup.

        let taskUUIDs = outcomes.map { $0.taskUUID }
        let tasks: [OCKCDTask] = try context.fetchObjects(withUUIDs: Set(taskUUIDs))

        let tasksGroupedByUUID = Dictionary(
            grouping: tasks,
            by: { $0.uuid }
        )

        // Create outcome metadata by matching up outcomes and tasks

        let metadata = try outcomes.map { outcome -> OutcomeMetadata in

            // Find the task for the outcome

            let taskUUID = outcome.taskUUID
            let task = tasksGroupedByUUID[taskUUID]?.first

            guard let task else {
                let msg = "Failed to find task with UUID \(taskUUID)"
                throw OCKStoreError.invalidValue(reason: msg)
            }

            // Compute the schedule event for the outcome

            let scheduleElements = task.scheduleElements.map { $0.makeValue() }
            let schedule = OCKSchedule(composing: scheduleElements)
            let event = schedule.event(forOccurrenceIndex: outcome.taskOccurrenceIndex)

            // If an event cannot be created, the event occurrence is likely after the end
            // of the schedule
            guard let event else {
                let msg = "Invalid outcome occurrence: \(outcome)"
                throw OCKStoreError.invalidValue(reason: msg)
            }

            // Create the metadata for the outcome

            let metadata = OutcomeMetadata(task: task, scheduleEvent: event)
            return metadata
        }

        return metadata
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
    private func confirmOutcomesAreInValidRegionOfTaskVersionChain(_ metadata: [OutcomeMetadata]) throws {

        for metadata in metadata {

            let eventStart = metadata.scheduleEvent.start
            var task = metadata.task

            while let nextVersion = task.next.first as? OCKCDTask {

                if
                    nextVersion.effectiveDate >= task.effectiveDate &&  // The next version is effective after this version
                    nextVersion.effectiveDate <= eventStart             // The next version is effective before the start of the event
                {
                    throw OCKStoreError.invalidValue(reason: """
                        Tried to place an outcome in a date range overshadowed by a future version of task.
                        The event for the outcome is dated \(eventStart), but a newer version of the task starts on \(nextVersion.effectiveDate).
                        """)
                }
                task = nextVersion
            }
        }
    }

    private func confirmOutcomesAreUnique(_ outcomes: [Outcome]) throws {

        // Build a predicate that searches for all effective outcomes

        let query = OCKOutcomeQuery(for: Date())
        let effectivePredicate = buildPredicate(for: query)

        // Ensure there are no effective outcomes with matching task occurrence
        // index and task UUID. This essentially checks that there is only one
        // effective outcome for a single event.

        let uniquenessPredicates = outcomes.map {

            NSPredicate(
                format: "%K == %@ AND %K == %i",
                #keyPath(OCKCDOutcome.task.uuid),
                $0.taskUUID as CVarArg,
                #keyPath(OCKCDOutcome.taskOccurrenceIndex),
                $0.taskOccurrenceIndex
            )
        }

        let uniquenessPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: uniquenessPredicates)

        let predicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [
                effectivePredicate, uniquenessPredicate
            ]
        )

        // Create a fetch request to search for conflicting outcomes

        let entityName = OCKOutcome.entity().name!
        let request = NSFetchRequest<OCKCDVersionedObject>(entityName: entityName)
        request.predicate = predicate

        let conflictCount = try context.count(for: request)

        if conflictCount > 0 {
            let errorMessage = """
            Tried to add a non-unique outcome to the store. Outcomes are unique on their \
            task UUID and task occurrence index.
            """
            throw OCKStoreError.invalidValue(reason: errorMessage)
        }

    }

    private func buildPredicate(for query: OCKOutcomeQuery) -> NSPredicate {
        var predicate = query.basicPredicate(enforceDateInterval: false)
        
        if let interval = query.dateInterval {


            // Ensure the event for the outcome occurs in the query interval
            let doesEventForOutcomeOccurDuringQueryInterval = doesEventForOutcomeOccur(in: interval)


            let hasNoPreviousVersionWithNewerEffectiveDate = NSPredicate(
                format: "SUBQUERY(%K, $x, $x.effectiveDate > %K).@count == 0",
                #keyPath(OCKCDOutcome.previous),
                #keyPath(OCKCDOutcome.effectiveDate)
            )

            let hasNoNextVersionWithNewerEffectiveDate = NSPredicate(
                format: "SUBQUERY(%K, $x, $x.effectiveDate >= %K).@count == 0",
                #keyPath(OCKCDOutcome.next),
                #keyPath(OCKCDOutcome.effectiveDate)
            )
            
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                predicate, doesEventForOutcomeOccurDuringQueryInterval,
                hasNoNextVersionWithNewerEffectiveDate, hasNoPreviousVersionWithNewerEffectiveDate
            ])
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
        
        return predicate
    }

    private func buildSortDescriptors(for query: OCKOutcomeQuery) -> [NSSortDescriptor] {
        query.defaultSortDescriptors()
    }

    private func doesEventForOutcomeOccur(in interval: DateInterval) -> NSPredicate {

        // Outcome's event starts before the interval end date (exclusive)
        let doesStartBeforeIntervalEnd = NSPredicate(
            format: "%K < %@",
            #keyPath(OCKCDOutcome.startDate),
            interval.end as NSDate
        )

        // Outcome's event ends after the interval start date (inclusive)
        let doesEndAfterIntervalStart = NSPredicate(
            format: "%K >= %@",
            #keyPath(OCKCDOutcome.endDate),
            interval.start as NSDate
        )

        let subpredicates = [doesStartBeforeIntervalEnd, doesEndAfterIntervalStart]
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
        return compoundPredicate
    }
}

private struct OutcomeMetadata {

    var task: OCKCDTask
    var scheduleEvent: OCKScheduleEvent
}
