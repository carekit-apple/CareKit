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

    public func tasks(matching query: OCKTaskQuery) -> CareStoreQueryResults<OCKTask> {

        // Setup a live query

        let predicate = buildPredicate(for: query)
        let sortDescriptors = buildSortDescriptors(for: query)

        let monitor = CoreDataQueryMonitor(
            OCKCDTask.self,
            predicate: predicate,
            sortDescriptors: sortDescriptors,
            context: context
        )

        // Wrap the live query in an async stream

        let coreDataTasks = monitor.results()

        // Convert Core Data results to DTOs

        let tasks = coreDataTasks
            .map { tasks in
                tasks.map { $0.makeTask() }
            }

        // Wrap the final transformed stream to hide all implementation details from
        // the public API

        let wrappedTasks = CareStoreQueryResults(wrapping: tasks)
        return wrappedTasks
    }

    public func fetchTasks(
        query: OCKTaskQuery = OCKTaskQuery(),
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[OCKTask], OCKStoreError>) -> Void) {

        fetchValues(
            predicate: buildPredicate(for: query),
            sortDescriptors: buildSortDescriptors(for: query),
            offset: query.offset,
            limit: query.limit) { (result: Result<[OCKTask], OCKStoreError>) in

            let filtered = result.map {
                $0.filtered(
                    dateInterval: query.dateInterval,
                    excludeTasksWithNoEvents: query.excludesTasksWithNoEvents
                )
            }

            callbackQueue.async {
                completion(filtered)
            }
        }
    }

    public func addTasks(
        _ tasks: [OCKTask],
        callbackQueue: DispatchQueue = .main,
        completion: ((Result<[OCKTask], OCKStoreError>) -> Void)? = nil) {

        transaction(inserts: tasks, updates: [], deletes: []) { result in
            callbackQueue.async {
                completion?(result.map(\.inserts))
            }
        }
    }

    public func updateTasks(
        _ tasks: [OCKTask],
        callbackQueue: DispatchQueue = .main,
        completion: ((Result<[OCKTask], OCKStoreError>) -> Void)? = nil) {

        transaction(
            inserts: [], updates: tasks, deletes: [],
            preInsertValidate: { try self.confirmUpdateWillNotCauseDataLoss(tasks: tasks) }) { result in

            callbackQueue.async {
                completion?(result.map(\.updates))
            }
        }
    }

    public func deleteTasks(
        _ tasks: [OCKTask],
        callbackQueue: DispatchQueue = .main,
        completion: ((Result<[OCKTask], OCKStoreError>) -> Void)? = nil) {

        transaction(inserts: [], updates: [], deletes: tasks) { result in
            callbackQueue.async {
                completion?(result.map(\.deletes))
            }
        }
    }

    // Ensure that new versions of tasks do not overwrite regions of previous
    // versions that already have outcomes saved to them.
    //
    // |<------------- Time Line --------------->|
    //  TaskV1 ------x------------------->
    //                     V2 ---------->
    //              V3------------------>
    //
    // Throws an error when updating to V3 from V2 if V1 has outcomes after `x`.
    // Throws an error when updating to V3 from V2 if V2 has any outcomes.
    // Does not throw when updating to V3 from V2 if V1 has outcomes before `x`.
    private func confirmUpdateWillNotCauseDataLoss(tasks: [OCKTask]) throws {
        let request = NSFetchRequest<OCKCDTask>(entityName: OCKCDTask.entity().name!)
        request.predicate = OCKCDTask.headerPredicate(tasks)
        request.returnsObjectsAsFaults = false
        let heads = try context.fetch(request)

        for task in heads {

            guard let proposedUpdate = tasks.first(where: { $0.id == task.id })
                else { fatalError("Fetched an OCKCDTask for which an update was not proposed.") }

            // For each task, gather all outcomes
            var allOutcomes: Set<OCKCDOutcome> = []
            var currentVersion: OCKCDTask? = task
            while let version = currentVersion {

                let conflictingOutcomes = version.outcomes
                    .filter { $0.next.isEmpty && $0.deletedDate == nil }

                allOutcomes = allOutcomes.union(conflictingOutcomes)
                currentVersion = version.previous.first as? OCKCDTask // AUDIT: RISKY CHANGE
            }

            // Get the date highest date on which an outcome exists.
            // If there are no outcomes, then any update is safe.
            guard let latestDate = allOutcomes.map({ $0.startDate }).max()
                else { continue }

            if proposedUpdate.effectiveDate <= latestDate {
                throw OCKStoreError.updateFailed(reason: """
                    Updating task \(task.id) failed. The new version of the task takes effect on \(task.effectiveDate), but an outcome for a
                    previous version of the task exists on \(latestDate). To prevent implicit data loss, you must explicitly delete all outcomes
                    that exist after the new version's `effectiveDate` before applying the update, or move the new version's `effectiveDate` to
                    some date past the latest outcome's date.
                    """
                )
            }
        }
    }

    func buildPredicate(for query: OCKTaskQuery) -> NSPredicate {
        var predicate = query.basicPredicate(enforceDateInterval: true)

        if !query.carePlanIDs.isEmpty {
            let planPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDTask.carePlan.id), query.carePlanIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, planPredicate])
        }

        if !query.carePlanUUIDs.isEmpty {
            let planPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDTask.carePlan.uuid), query.carePlanUUIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, planPredicate])
        }

        if !query.carePlanRemoteIDs.isEmpty {
            let planPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDTask.carePlan.remoteID), query.carePlanRemoteIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, planPredicate])
        }

        return predicate
    }

    func buildSortDescriptors(for query: OCKTaskQuery) -> [NSSortDescriptor] {
        query.sortDescriptors.map { order -> NSSortDescriptor in
            switch order {
            case .effectiveDate(ascending: let ascending):
                return NSSortDescriptor(keyPath: \OCKCDTask.effectiveDate, ascending: ascending)
            case .title(let ascending):
                return NSSortDescriptor(keyPath: \OCKCDTask.title, ascending: ascending)
            case .groupIdentifier(let ascending):
                return NSSortDescriptor(keyPath: \OCKCDTask.groupIdentifier, ascending: ascending)
            }
        } + query.defaultSortDescriptors()
    }
}
