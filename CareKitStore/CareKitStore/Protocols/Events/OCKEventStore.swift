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

/// Any store from which a single event type can be queried is considered a `OCKReadOnlyEventStore`.
public protocol OCKReadOnlyEventStore: OCKAnyReadOnlyEventStore, OCKReadableTaskStore, OCKReadableOutcomeStore {
    typealias Event = OCKEvent<Task, Outcome>

    // MARK: Implementation Provided when Task == OCKTask and Outcome == OCKOutcome

    /// `fetchEvents` retrieves all the occurrences of the specified task in the interval specified by the provided query.
    ///
    /// - Parameters:
    ///   - taskID: A user-defined unique identifier for the task.
    ///   - query: A query used to constrain the values that will be fetched.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func fetchEvents(taskID: String, query: OCKEventQuery, callbackQueue: DispatchQueue,
                     completion: @escaping OCKResultClosure<[Event]>)

    /// `fetchEvent` retrieves a single occurrence of the speficied task.
    ///
    /// - Parameter task: The task for which to retrieve an event.
    /// - Parameter occurrence: The occurrence index of the desired event.
    /// - Parameter queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    /// - Parameter completion: A callback that will fire on the specified queue.
    func fetchEvent(forTask task: Task, occurrence: Int, callbackQueue: DispatchQueue, completion: @escaping OCKResultClosure<Event>)
}

/// Any store in which a single event type can be both queried and written is considered a `OCKEventStore`.
public protocol OCKEventStore: OCKReadOnlyEventStore, OCKTaskStore, OCKOutcomeStore, OCKAnyEventStore {}

// MARK: OCKAnyReadOnlyEventStore conformance for OCKReadOnlyEventStore

public extension OCKReadOnlyEventStore {
    func fetchAnyEvents(taskID: String, query: OCKEventQuery, callbackQueue: DispatchQueue,
                        completion: @escaping OCKResultClosure<[OCKAnyEvent]>) {
        fetchEvents(taskID: taskID, query: query, callbackQueue: callbackQueue) { completion($0.map { $0.map { $0.anyEvent } }) }
    }

    func fetchAnyEvent(forTask task: OCKAnyTask, occurrence: Int, callbackQueue: DispatchQueue, completion: @escaping OCKResultClosure<OCKAnyEvent>) {
        guard let typedTask = task as? Task else {
            callbackQueue.async {
                let message = "Store of type \(type(of: self)) cannot fetch event with task type \(type(of: task))."
                completion(.failure(.fetchFailed(reason: message)))
            }
            return
        }
        fetchEvent(forTask: typedTask, occurrence: occurrence, callbackQueue: callbackQueue) { completion($0.map { $0.anyEvent }) }
    }
}

// MARK: OCKReadOnlyEventStore Implementations for Task: OCKAnyVersionableTask

public extension OCKReadOnlyEventStore where Task: OCKAnyVersionableTask {

    // MARK: Events

    func fetchEvents(taskID: String, query: OCKEventQuery, callbackQueue: DispatchQueue = .main,
                     completion: @escaping OCKResultClosure<[OCKEvent<Task, Outcome>]>) {
        var taskQuery = OCKTaskQuery()
        taskQuery.dateInterval = query.dateInterval
        taskQuery.limit = 1
        taskQuery.ids = [taskID]

        fetchTasks(query: TaskQuery(taskQuery), callbackQueue: callbackQueue, completion: chooseFirst(then: { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let task):
                self.fetchEvents(task: task, query: query, previousEvents: [], callbackQueue: callbackQueue, completion: completion)
            }
        }, replacementError: .fetchFailed(reason: "No task with id: \(taskID) for query: \(taskQuery)")))
    }

    func fetchEvent(forTask task: Task, occurrence: Int, callbackQueue: DispatchQueue = .main, completion: @escaping OCKResultClosure<Event>) {
        guard let taskUUID = task.uuid else {
            callbackQueue.async {
                let message = "Cannot fetch events for a task that hasn't been persisted yet!"
                completion(.failure(.fetchFailed(reason: message)))
            }
            return
        }
        fetchEvent(withTaskVersion: taskUUID, occurrenceIndex: occurrence, callbackQueue: callbackQueue, completion: completion)
    }

    private func fetchEvent(withTaskVersion taskVersionUUID: UUID, occurrenceIndex: Int,
                            callbackQueue: DispatchQueue, completion: @escaping OCKResultClosure<OCKEvent<Task, Outcome>>) {
        fetchTask(withVersion: taskVersionUUID, callbackQueue: callbackQueue, completion: { (result: Result<Task, OCKStoreError>) in
            switch result {
            case .failure(let error): completion(.failure(.fetchFailed(reason: "Failed to fetch task. \(error.localizedDescription)")))
            case .success(let task):
                guard let scheduleEvent = task.schedule.event(forOccurrenceIndex: occurrenceIndex) else {
                    completion(.failure(.fetchFailed(reason: "Invalid occurrence \(occurrenceIndex) for task with version ID: \(taskVersionUUID)")))
                    return
                }
                let early = scheduleEvent.start.addingTimeInterval(-1)
                let late = scheduleEvent.end.addingTimeInterval(1)
                var query = OCKOutcomeQuery(dateInterval: DateInterval(start: early, end: late))
                query.taskUUIDs = [taskVersionUUID]
                self.fetchOutcomes(query: OutcomeQuery(query), callbackQueue: callbackQueue, completion: { result in
                    switch result {
                    case .failure(let error): completion(.failure(.fetchFailed(reason: "Couldn't find outcome. \(error.localizedDescription)")))
                    case .success(let outcomes):
                        let matchingOutcome = outcomes.first(where: { $0.taskOccurrenceIndex == occurrenceIndex })
                        let event = OCKEvent(task: task, outcome: matchingOutcome, scheduleEvent: scheduleEvent)
                        completion(.success(event))
                    }
                })
            }
        })
    }

    // This is a recursive async function that gets all events within a query for a given task, examining all past versions of the task
    private func fetchEvents(task: Task, query: OCKEventQuery, previousEvents: [Event],
                             callbackQueue: DispatchQueue = .main, completion: @escaping (Result<[Event], OCKStoreError>) -> Void) {
        guard let versionUUID = task.uuid else { completion(.failure(.fetchFailed(reason: "Task didn't have a versionID"))); return }
        let start = max(task.effectiveDate, query.dateInterval.start)
        let scheduledEndDate = task.schedule.endDate()
        let end = scheduledEndDate == nil ? query.dateInterval.end : min(scheduledEndDate!, query.dateInterval.end)
        let scheduleEvents = task.schedule.events(from: start, to: end)
        var outcomeQuery = OCKOutcomeQuery(dateInterval: DateInterval(start: start, end: end))
        outcomeQuery.taskUUIDs = [versionUUID]
        self.fetchOutcomes(query: OutcomeQuery(outcomeQuery), callbackQueue: callbackQueue, completion: { result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let outcomes):
                let events = self.join(task: task, with: outcomes, and: scheduleEvents) + previousEvents

                // If the query doesn't go back in time beyond the start of this version of the task, we're done.
                guard query.dateInterval.start < task.effectiveDate else {
                    completion(.success(events))
                    return
                }

                self.fetchNextValidPreviousVersion(for: task, callbackQueue: callbackQueue) { result in
                    switch result {
                    case .failure(let error): completion(.failure(error))
                    case .success(let previousVersion):

                        // If there is no previous version, then we're done fetching all events.
                        guard let previousVersion = previousVersion else {
                            completion(.success(events))
                            return
                        }

                        // If there is a previous version, fetch the events for it that don't overlap with
                        // any of the versions we've already fetched events for.
                        let nextEndDate = task.effectiveDate
                        let nextStartDate = query.dateInterval.start
                        let nextInterval = DateInterval(start: nextStartDate, end: nextEndDate)
                        let nextQuery = OCKEventQuery(dateInterval: nextInterval)
                        self.fetchEvents(task: previousVersion, query: nextQuery, previousEvents: events,
                                         callbackQueue: callbackQueue, completion: completion)
                    }

                }
            }
        })
    }

    private func fetchNextValidPreviousVersion(for task: Task, callbackQueue: DispatchQueue, completion: @escaping OCKResultClosure<Task?>) {

        guard let versionID = task.previousVersionUUID else {
            completion(.success(nil))
            return
        }

        fetchTask(withVersion: versionID, callbackQueue: callbackQueue) { result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let previousVersion):

                // If the newer version goes back further in time than the pervious version, skip fetching events for the older version.
                if task.effectiveDate <= previousVersion.effectiveDate {
                    self.fetchNextValidPreviousVersion(for: previousVersion, callbackQueue: callbackQueue, completion: completion)
                    return
                }

                completion(.success(previousVersion))
            }
        }
    }

    private func fetchTask(withVersion uuid: UUID, callbackQueue: DispatchQueue, completion: @escaping OCKResultClosure<Task>) {
        var query = OCKTaskQuery()
        query.uuids = [uuid]
        fetchTasks(query: TaskQuery(query), callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .fetchFailed(reason: "No task with versionID: \(uuid)")))
    }

    private func join(task: Task, with outcomes: [Outcome], and scheduleEvents: [OCKScheduleEvent]) -> [OCKEvent<Task, Outcome>] {
        guard !scheduleEvents.isEmpty else { return [] }
        let offset = scheduleEvents[0].occurrence
        var events = scheduleEvents.map { OCKEvent<Task, Outcome>(task: task, outcome: nil, scheduleEvent: $0) }
        for outcome in outcomes {
            events[outcome.taskOccurrenceIndex - offset].outcome = outcome
        }
        return events
    }
}
