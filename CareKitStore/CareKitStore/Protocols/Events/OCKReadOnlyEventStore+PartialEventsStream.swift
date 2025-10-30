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

    func partialEvents(matching query: OCKTaskQuery) -> some AsyncSequence<[PartialEvent<Task>], Error> & Sendable {

        let latestTaskVersionsQuery = makeLatestTaskVersionsQuery(from: query)

        guard let dateInterval = latestTaskVersionsQuery.dateInterval else {
            fatalError("Date interval should be set in makeLatestTaskVersionsQuery(from:)")
        }

        // Fetch the most recent version of the tasks in the date interval
        // Note, this means that if any of the latest versions of tasks matching
        // the query change, we will recompute all task version chains, not just
        // the version chain for the task that changed. If needed later, we
        // can optimize this by only refetching the task version chain that
        // has changed.

        let latestTaskVersions = tasks(matching: latestTaskVersionsQuery)

        let taskVersionChains = latestTaskVersions.map { tasks in

            return try await self.taskVersionChains(
                backwardsFrom: tasks,
                effectiveAfter: dateInterval.start
            )
        }

        // Convert each task version chain to an array of partial events. Partial
        // events can be used later to create full fledged events.
        let partialEvents = taskVersionChains.map { taskVersionChains in

            return taskVersionChains
                .flatMap { taskVersionChain in
                    return self.makePartialEvents(
                        taskVersionChain: taskVersionChain,
                        dateInterval: dateInterval
                    )
                }
                // Guarantee a stable sort order in UIs with lists of events
                .sorted { $0.isOrderedBefore(other: $1) }
        }

        return partialEvents
    }

    private func taskVersionChains(
        backwardsFrom tasks: [Task],
        effectiveAfter startDate: Date
    ) async throws -> [[Task]] {

        let taskVersionChains = try await withThrowingTaskGroup(
            of: [Task].self
        ) { group -> [[Task]] in

            // Create "concurrent tasks" to fetch "care task" version chains
            tasks.forEach { careTask in

                group.addTask {

                    // Note this a one-time fetch, and not a stream so we will not receive
                    // updates. But, the result shouldn't actually change because we're
                    // fetching *previous* versions of a task. If a task is updated, a
                    // new version is created and the previous versions are unaffected.
                    let versionChain = try await self.taskVersionChain(
                        backwardsFrom: careTask,
                        effectiveAfter: startDate
                    )

                    return versionChain
                }
            }

            // Collect the results into a single array
            let taskVersionChains: [[Task]] = try await group.reduce(
                into: []
            ) { partial, next in
                partial.append(next)
            }

            return taskVersionChains
        }

        return taskVersionChains
    }

    private func taskVersionChain(
        backwardsFrom task: Task?,
        effectiveAfter startDate: Date
    ) async throws -> [Task] {

        return try await withCheckedThrowingContinuation { continuation in

            fetchTaskVersionChain(
                backwardsFrom: task,
                effectiveAfter: startDate,
                previousResult: [],
                callbackQueue: DispatchQueue.global(qos: .userInitiated),
                completion: { continuation.resume(with: $0) }
            )
        }
    }
}
