/*
 Copyright (c) 2022, Apple Inc. All rights reserved.
 
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

extension OCKReadOnlyEventStore where Task: OCKAnyVersionableTask {

    // MARK: - Task version chain

    func fetchTaskVersionChains(
        query: OCKTaskQuery,
        effectiveAfter startDate: Date,
        callbackQueue: DispatchQueue,
        completion: @escaping (Result<[[Task]], OCKStoreError>) -> Void
    ) {

        fetchTasks(
            query: query,
            callbackQueue: callbackQueue
        ) { result in

            switch result {

            case let .success(latestTaskVersions):

                let closures = latestTaskVersions.map { task in
                    { completion in
                        self.fetchTaskVersionChain(
                            backwardsFrom: task,
                            effectiveAfter: startDate,
                            previousResult: [],
                            callbackQueue: callbackQueue,
                            completion: completion
                        )
                    }
                }

                aggregate(
                    closures,
                    callbackQueue: callbackQueue,
                    completion: completion
                )

            case let .failure(error):
                completion(.failure(error))
                return
            }
        }
    }

    func fetchTaskVersionChain(
        backwardsFrom task: Task?,
        effectiveAfter startDate: Date,
        previousResult: [Task],
        callbackQueue: DispatchQueue,
        completion: @escaping (Result<[Task], OCKStoreError>) -> Void
    ) {

        // If there is no task, return
        guard let task = task else {
            completion(.success(previousResult))
            return
        }

        // If the current task is not active before the specified `startDate`, return
        if
            task.effectiveDate < startDate,
            let previousEffectiveDate = previousResult.first?.effectiveDate,
            previousEffectiveDate <= startDate
        {
            completion(.success(previousResult))
            return
        }

        // Store the current task. Task chain is ordered by descending `effectiveDate`
        var taskVersionChain = previousResult
        taskVersionChain.append(task)

        // If there are no previous versions, we can return early
        guard let previousTaskVersionUUID = task
            .previousVersionUUIDs
            .first
        else {
            completion(.success(taskVersionChain))
            return
        }

        // Create a query for the previous task version
        var previousTaskVersionQuery = OCKTaskQuery()
        previousTaskVersionQuery.uuids = [previousTaskVersionUUID]

        // Walk backwards to the previous task version
        fetchTasks(
            query: previousTaskVersionQuery,
            callbackQueue: callbackQueue
        ) { result in

            switch result {

            case let .success(tasks):

                let previousTaskVersion = tasks.first

                self.fetchTaskVersionChain(
                    backwardsFrom: previousTaskVersion,
                    effectiveAfter: startDate,
                    previousResult: taskVersionChain,
                    callbackQueue: callbackQueue,
                    completion: completion
                )

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Mappers

    func makePartialEvents(
        taskVersionChain: [Task],
        dateInterval: DateInterval
    ) -> [PartialEvent<Task>] {

        // Algorithm:
        // 1. Sort tasks by effective date. The most recently effective task should be the first task in the array.
        // 2. Iterate through the array and compute the events between one effective date and the next. Because the
        //    array is sorted by descending effective date, events for more recently effective tasks will be preferred.

        // If two tasks have the same effective date, the task version chain guarantees
        // that the LHS is already known to be the newer version, so we don't want to switch their order.
        // To make that guarantee, we use a stable sort to sort by descending effective date.
        //
        // Ultimately the tasks are now sorted by:
        // 1. Descending effective date
        // 2. Descending version
        let taskVersionsSortedByDescendingEffectiveDate = taskVersionChain
            .sorted { $1.effectiveDate < $0.effectiveDate }

        // Compute the effective date interval from one task to the next by iterating
        // through pairs of tasks

        var currentEnd = dateInterval.end

        let eventsPerTask = taskVersionsSortedByDescendingEffectiveDate.map { task -> [PartialEvent<Task>] in

            // Compute the start and end dates of the current task schedule. This task schedule should only
            // run up until the effective date of the next task in the version chain.

            let start = max(
                task.effectiveDate,
                dateInterval.start
            )

            defer {
                currentEnd = task.effectiveDate
            }

            // Compute the events for the date interval of the task schedule

            guard start < currentEnd else { return [] }

            let scheduleEvents = task
                .schedule
                .events(from: start, to: currentEnd)

            let events = scheduleEvents.map { scheduleEvent in
                PartialEvent(
                    task: task,
                    scheduleEvent: scheduleEvent
                )
            }

            return events
        }

        // Reverse the order of `eventsPerTask` so that we return tasks in ascending effective order.
        //
        // The tasks are now sorted by:
        // 1. Ascending effective date
        // 2. Ascending version
        let mostRecentlyEffectiveEvents = eventsPerTask
            .reversed()
            .flatMap { $0 }

        return mostRecentlyEffectiveEvents
    }

    func makeLatestTaskVersionsQuery(from query: OCKTaskQuery) -> OCKTaskQuery {

        var latestTaskVersionsQuery = query

        // We need to explicitly set the date interval in case it's nil
        // to ensure that we fetch the most recent version of a task in a
        // given date interval, and not all versions of the task

        let dateInterval = latestTaskVersionsQuery.dateInterval ??
            Calendar.current.dateInterval(of: .day, for: Date())!

        latestTaskVersionsQuery.dateInterval = dateInterval

        return latestTaskVersionsQuery
    }
}
