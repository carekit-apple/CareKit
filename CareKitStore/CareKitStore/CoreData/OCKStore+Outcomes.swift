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

    public func fetchOutcomes(query: OCKOutcomeQuery = OCKOutcomeQuery(), callbackQueue: DispatchQueue = .main,
                            completion: @escaping (Result<[OCKOutcome], OCKStoreError>) -> Void) {
        context.perform {
            do {
                let request = NSFetchRequest<OCKCDOutcome>(entityName: String(describing: OCKCDOutcome.self))
                request.fetchLimit = query.limit ?? 0
                request.fetchOffset = query.offset
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

    public func addOutcomes(_ outcomes: [OCKOutcome], callbackQueue: DispatchQueue = .main,
                          completion: ((Result<[OCKOutcome], OCKStoreError>) -> Void)? = nil) {
        transaction(
            inserts: outcomes, updates: [], deletes: [],
            preInsertValidate: { try self.confirmOutcomesAreInValidRegionOfTaskVersionChain(outcomes) }
        ) { result in
            callbackQueue.async {
                completion?(result.map(\.inserts))
            }
        }
    }

    public func updateOutcomes(_ outcomes: [OCKOutcome], callbackQueue: DispatchQueue = .main,
                             completion: ((Result<[OCKOutcome], OCKStoreError>) -> Void)? = nil) {
        transaction(inserts: [], updates: outcomes, deletes: []) { result in
            callbackQueue.async {
                completion?(result.map(\.updates))
            }
        }
    }

    public func deleteOutcomes(_ outcomes: [OCKOutcome], callbackQueue: DispatchQueue = .main,
                             completion: ((Result<[OCKOutcome], OCKStoreError>) -> Void)? = nil) {
        transaction(inserts: [], updates: [], deletes: outcomes) { result in
            callbackQueue.async {
                completion?(result.map(\.deletes))
            }
        }
    }

    // MARK: Private

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
    private func confirmOutcomesAreInValidRegionOfTaskVersionChain(_ outcomes: [Outcome]) throws {
        for outcome in outcomes {
            var task: OCKCDTask = try context.fetchObject(uuid: outcome.taskUUID)
            let schedule = OCKSchedule(composing: task.scheduleElements.map { $0.makeValue() })
            while let nextVersion = task.next.first as? OCKCDTask {
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

    private func buildPredicate(for query: OCKOutcomeQuery) -> NSPredicate {
        var predicate = query.basicPredicate(enforceDateInterval: false)
        
        if let interval = query.dateInterval {

            let beforePredicate = NSPredicate(
                format: "%K < %@",
                #keyPath(OCKCDOutcome.startDate),
                interval.end as NSDate
            )

            let afterPredicate = NSPredicate(
                format: "%K >= %@",
                #keyPath(OCKCDOutcome.endDate),
                interval.start as NSDate
            )

            let nextPredicate = NSPredicate(
                format: "%K.@count == 0 OR %K.@min > %@",
                #keyPath(OCKCDOutcome.next),
                #keyPath(OCKCDOutcome.next.effectiveDate),
                interval.end as NSDate
            )
            
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                predicate, beforePredicate, afterPredicate, nextPredicate
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
        query.sortDescriptors.map { order -> NSSortDescriptor in
            switch order {
            case .date(let ascending): return NSSortDescriptor(keyPath: \OCKCDOutcome.startDate, ascending: ascending)
            }
        } + query.defaultSortDescriptors()
    }
}
