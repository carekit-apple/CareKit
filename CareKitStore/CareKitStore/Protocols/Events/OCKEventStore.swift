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

import AsyncAlgorithms
import Foundation
import os.log

/// A store that allows for reading events.
public protocol OCKReadOnlyEventStore: OCKAnyReadOnlyEventStore, OCKReadableTaskStore, OCKReadableOutcomeStore {
    typealias Event = OCKEvent<Task, Outcome>

    /// An asynchronous sequence that produces events.
    associatedtype Events: AsyncSequence & Sendable where Events.Element == [Event]

    // MARK: Implementation Provided when Task == OCKTask and Outcome == OCKOutcome

    /// A continuous stream of events (occurrences of tasks) that exist in the store.
    ///
    /// The stream yields a new value whenever the result changes and yields an error if there's an issue
    /// accessing the store or fetching results.
    ///
    /// The result will contain an event if the event occurs within the query interval *and* the task is effective in the query interval.
    /// A task is effective if its ``OCKAnyVersionableTask/effectiveDate`` lies in the query interval. The outcome
    /// attached to the event will always be the most recent version available.
    ///
    /// This method will also walk through all versions of a task and compute the events for each version. The events will have the same
    /// ``OCKAnyTask/id`` but a unique ``OCKAnyTask/uuid``.
    ///
    /// It's important to handle events from multiple task version with care. Suppose `newTask` and `oldTask` are two versions of a
    /// task, where `newTask.effectiveDate < oldTask.effectiveDate`. A few important caveats to consider include:
    ///
    /// 1. If there exists an event for `newTask` that overlaps with an event for `oldTask`, both events will be returned by this method.
    /// Both events are relevant because at some point during each of their durations the associated task is effective, even if not for the
    /// entire duration.
    ///
    /// 2. If there exists an all-day event for `newTask` and an all-day event for `oldTask` on the same day, both events will
    /// be returned by this method.
    ///
    /// Ultimately, be sure to consider the task when handling events returned by this method. If the task is akin to a medication,
    /// make sure the events are properly spaced out before presenting them to the user to ensure there is no risk of under-dosing or
    /// over-dosing.
    ///
    /// Events returned by this method will be sorted by their start date and task effective date.
    ///
    /// - Parameter query: Used to match events in the store.
    func events(matching query: OCKEventQuery) -> Events

    // Fetch a list of events that exist in the store.
    ///
    /// The completion will be called with an error if there's an issue accessing the store or fetching results.
    ///
    /// The stream yields a new value whenever the result changes and yields an error if there's an issue
    /// accessing the store or fetching results.
    ///
    /// The result will contain an event if the event occurs within the query interval *and* the task is effective in the query interval.
    /// A task is effective if its ``OCKAnyVersionableTask/effectiveDate`` lies in the query interval. The outcome
    /// attached to the event will always be the most recent version available.
    ///
    /// This method will also walk through all versions of a task and compute the events for each version. The events will have the same
    /// ``OCKAnyTask/id`` but a unique ``OCKAnyTask/uuid``.
    ///
    /// It's important to handle events from multiple task version with care. Suppose `newTask` and `oldTask` are two versions of a
    /// task, where `newTask.effectiveDate < oldTask.effectiveDate`. A few important caveats to consider include:
    ///
    /// 1. If there exists an event for `newTask` that overlaps with an event for `oldTask`, both events will be returned by this method.
    /// Both events are relevant because at some point during each of their durations the associated task is effective, even if not for the
    /// entire duration.
    ///
    /// 2. If there exists an all-day event for `newTask` and an all-day event for `oldTask` on the same day, both events will
    /// be returned by this method.
    ///
    /// Ultimately, be sure to consider the task when handling events returned by this method. If the task is akin to a medication,
    /// make sure the events are properly spaced out before presenting them to the user to ensure there is no risk of under-dosing or
    /// over-dosing.
    ///
    /// Events returned by this method will be sorted by their start date and task effective date.
    ///
    /// - Parameters:
    ///   - query: Used to match events in the store.
    ///   - callbackQueue: The queue that runs the completion. In most cases this should be the
    ///                    main queue.
    ///   - completion: A callback that contains the result.
    func fetchEvents(
        query: OCKEventQuery,
        callbackQueue: DispatchQueue,
        completion: @escaping OCKResultClosure<[Event]>)

    /// `fetchEvent` retrieves a single occurrence of the specified task.
    ///
    /// - Parameters:
    ///   - task: The task for which to retrieve an event.
    ///   - occurrence: The occurrence index of the desired event.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the specified queue.
    func fetchEvent(
        forTask task: Task,
        occurrence: Int,
        callbackQueue: DispatchQueue,
        completion: @escaping OCKResultClosure<Event>
    )
}

/// Any store in which a single event type can be both queried and written is considered a `OCKEventStore`.
public protocol OCKEventStore: OCKReadOnlyEventStore, OCKTaskStore, OCKOutcomeStore, OCKAnyEventStore {}

// MARK: OCKAnyReadOnlyEventStore conformance for OCKReadOnlyEventStore

public extension OCKReadOnlyEventStore {

    func anyEvents(matching query: OCKEventQuery) -> CareStoreQueryResults<OCKAnyEvent> {

        let events = events(matching: query)
            .map { events in
                events.map { $0.anyEvent }
            }

        let wrappedEvents = CareStoreQueryResults(wrapping: events)
        return wrappedEvents
    }

    func fetchAnyEvents(
        query: OCKEventQuery,
        callbackQueue: DispatchQueue,
        completion: @escaping OCKResultClosure<[OCKAnyEvent]>) {

        fetchEvents(query: query, callbackQueue: callbackQueue) {
            completion($0.map { $0.map { $0.anyEvent } })
        }
    }

    func fetchAnyEvent(
        forTask task: OCKAnyTask,
        occurrence: Int,
        callbackQueue: DispatchQueue,
        completion: @escaping OCKResultClosure<OCKAnyEvent>) {

        guard let typedTask = task as? Self.Task else {
            callbackQueue.async {
                let message = "Store of type \(type(of: self)) cannot fetch event with task type \(type(of: task))."
                completion(.failure(.fetchFailed(reason: message)))
            }
            return
        }

        fetchEvent(
            forTask: typedTask,
            occurrence: occurrence,
            callbackQueue: callbackQueue) {

            completion($0.map { $0.anyEvent })
        }
    }
}

// MARK: OCKReadOnlyEventStore Implementations for Task: OCKAnyVersionableTask

public extension OCKReadOnlyEventStore where Task: OCKAnyVersionableTask {

    func events(matching query: OCKEventQuery) -> CareStoreQueryResults<Event> {

        let taskQuery = query.taskQuery
        let outcomeQuery = query.outcomeQuery

        let partialEvents = partialEvents(matching: taskQuery)
        let outcomes = outcomes(matching: outcomeQuery)

        let events = combineLatest(partialEvents, outcomes)
            .map { partialEvents, outcomes in
                self.join(partialEvents: partialEvents, outcomes: outcomes)
            }
            .removeDuplicates()

        let wrappedEvents = CareStoreQueryResults(wrapping: events)
        return wrappedEvents
    }

    func fetchEvent(
        forTask task: Self.Task,
        occurrence: Int,
        callbackQueue: DispatchQueue,
        completion: @escaping OCKResultClosure<Event>) {

        var query = OCKTaskQuery()
        query.uuids = [task.uuid]

        fetchTask(withVersion: task.uuid, callbackQueue: callbackQueue) { result in
            switch result {

            case let .failure(error):
                completion(.failure(error))

            case let .success(task):

                guard let scheduleEvent = task.schedule.event(forOccurrenceIndex: occurrence) else {
                    completion(.failure(.fetchFailed(reason: "Invalid occurence index")))
                    return
                }

                // +1 to include the event end date in the query result. CareKit date intervals
                // are considered inclusive at the start and exclusive at the end.
                let interval = DateInterval(
                    start: scheduleEvent.start,
                    end: scheduleEvent.end + 1
                )

                var query = OCKOutcomeQuery(dateInterval: interval)
                query.taskUUIDs = [task.uuid]

                self.fetchOutcomes(query: query, callbackQueue: callbackQueue) { result in

                    switch result {

                    case let .failure(error):
                        completion(.failure(error))

                    case let .success(outcomes):
                        let match = outcomes.first(where: { $0.taskOccurrenceIndex == occurrence })
                        let event = Event(task: task, outcome: match, scheduleEvent: scheduleEvent)
                        completion(.success(event))
                    }
                }
            }
        }
    }

    func fetchEvents(
        query: OCKEventQuery,
        callbackQueue: DispatchQueue = .main,
        completion: @escaping OCKResultClosure<[OCKEvent<Task, Outcome>]>
    ) {

        let taskQuery = query.taskQuery
        let outcomeQuery = query.outcomeQuery

        fetchPartialEvents(
            query: taskQuery,
            callbackQueue: callbackQueue
        ) { result in

            switch result {

            case let .success(partialEvents):

                self.fetchOutcomes(
                    query: outcomeQuery,
                    partialEvents: partialEvents,
                    callbackQueue: callbackQueue,
                    completion: completion
                )

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    private func fetchOutcomes(
        query: OCKOutcomeQuery,
        partialEvents: [PartialEvent<Task>],
        callbackQueue: DispatchQueue,
        completion: @escaping OCKResultClosure<[OCKEvent<Task, Outcome>]>
    ) {
        fetchOutcomes(
            query: query,
            callbackQueue: callbackQueue
        ) { result in

            switch result {

            case let .success(outcomes):

                // Join the partial events and the outcomes into a final result
                let events = self.join(partialEvents: partialEvents, outcomes: outcomes)
                completion(.success(events))

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    private func fetchTask(
        withVersion uuid: UUID,
        callbackQueue: DispatchQueue,
        completion: @escaping OCKResultClosure<Task>) {

        var query = OCKTaskQuery()
        query.uuids = [uuid]

        fetchTasks(
            query: query,
            callbackQueue: callbackQueue,
            completion: chooseFirst(
                then: completion,
                replacementError: .fetchFailed(reason: "No task with UUID: \(uuid)")
            )
        )
    }
}

// MARK: Async methods for OCKReadOnlyEventStore

public extension OCKReadOnlyEventStore {

    /// `fetchEvents` retrieves all the occurrences of the specified task in the interval specified by the provided query.
    ///
    /// - Parameters:
    ///   - query: A query that specifies which events to fetch.
    func fetchEvents(query: OCKEventQuery) async throws -> [Event] {
        try await withCheckedThrowingContinuation { continuation in
            fetchEvents(query: query, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }

    /// `fetchEvent` retrieves a single occurrence of the specified task.
    ///
    /// - Parameter task: The task for which to retrieve an event.
    /// - Parameter occurrence: The occurrence index of the desired event.
    func fetchEvent(forTask task: Task, occurrence: Int) async throws -> Event {
        try await withCheckedThrowingContinuation { continuation in
            fetchEvent(forTask: task, occurrence: occurrence, callbackQueue: .main, completion: { continuation.resume(with: $0) })
        }
    }
}
