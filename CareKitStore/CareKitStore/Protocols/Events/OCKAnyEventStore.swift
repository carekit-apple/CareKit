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

/// A store that allows for reading events.
public protocol OCKAnyReadOnlyEventStore: OCKAnyReadOnlyTaskStore, OCKAnyReadOnlyOutcomeStore {

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
    func anyEvents(matching query: OCKEventQuery) -> CareStoreQueryResults<OCKAnyEvent>

    /// Fetch a list of events that exist in the store.
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
    func fetchAnyEvents(
        query: OCKEventQuery,
        callbackQueue: DispatchQueue,
        completion: @escaping OCKResultClosure<[OCKAnyEvent]>
    )

    /// `fetchAnyEvent` retrieves the occurrence of the specified task.
    ///
    /// - Parameters:
    ///   - task: The task for which to retrieve an event.
    ///   - occurrence: The occurrence number of the event to be fetched.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func fetchAnyEvent(
        forTask task: OCKAnyTask,
        occurrence: Int,
        callbackQueue: DispatchQueue,
        completion: @escaping OCKResultClosure<OCKAnyEvent>)

    /// `fetchAdherence` retrieves all the events and calculates the percent of tasks completed for every day between two dates.
    ///
    /// The way completion is computed depends on how many `expectedValues` a task has. If it has no expected values,
    /// then having an outcome with at least one value will count as complete. If a task has expected values, completion
    /// will be computed as ratio of the number of outcome values to the number of expected values.
    ///
    /// - Parameters:
    ///   - query: A query used to constrain the values that will be fetched.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue. The result contains an array with one value for each day.
    func fetchAdherence(query: OCKAdherenceQuery, callbackQueue: DispatchQueue, completion: @escaping OCKResultClosure<[OCKAdherence]>)
}

/// Any store from which `OCKAnyEvent`s  can be queried and also written is considered `OCKAnyEventStore`.
public protocol OCKAnyEventStore: OCKAnyReadOnlyEventStore, OCKAnyTaskStore, OCKAnyOutcomeStore {

}

// MARK: Adherence and Insights Methods for OCKAnyReadOnlyEventStore

public extension OCKAnyReadOnlyEventStore {

    func fetchAdherence(
        query: OCKAdherenceQuery,
        callbackQueue: DispatchQueue = .main,
        completion: @escaping OCKResultClosure<[OCKAdherence]>
    ) {
        var taskQuery = OCKTaskQuery(dateInterval: query.dateInterval)
        taskQuery.ids = query.taskIDs

        fetchAnyTasks(query: taskQuery, callbackQueue: callbackQueue) { result in
            switch result {
            case .failure(let error): completion(.failure(.fetchFailed(reason: "Failed to fetch adherence. \(error.localizedDescription)")))
            case .success(let tasks):
                let tasks = tasks.filter { $0.impactsAdherence }
                guard !tasks.isEmpty else {
                    let adherences = query.dates().map { _ in OCKAdherence.noTasks }
                    completion(.success(adherences))
                    return
                }
                let group = DispatchGroup()
                var error: Error?
                var events: [OCKAnyEvent] = []
                for id in tasks.map({ $0.id }) {
                    group.enter()

                    var query = OCKEventQuery(dateInterval: query.dateInterval)
                    query.taskIDs = [id]

                    self.fetchAnyEvents(query: query, callbackQueue: callbackQueue, completion: { result in
                        switch result {
                        case .failure(let fetchError):
                            error = fetchError
                        case .success(let fetchedEvents):
                            events.append(contentsOf: fetchedEvents)
                        }
                        group.leave()
                    })
                }
                group.notify(queue: .global(qos: .userInitiated), execute: {
                    if let error = error {
                        callbackQueue.async {
                            completion(.failure(.fetchFailed(reason: "Failed to fetch completion for tasks! \(error.localizedDescription)")))
                        }
                        return
                    }

                    let groupedEvents = self.groupEventsByDate(events: events, after: query.dateInterval.start, before: query.dateInterval.end)
                    var adherenceValues = [OCKAdherence](repeating: .noTasks, count: groupedEvents.count)
                    let indicesWithTasks = self.datesWithTasks(query: query, tasks: tasks).enumerated().compactMap { $1 ? $0 : nil }
                    indicesWithTasks.forEach {

                        // Make sure we have retrieved events
                        if groupedEvents[$0].isEmpty {
                            adherenceValues[$0] = .noEvents

                        // Aggregate the progress for the events
                        } else {

                            let events = groupedEvents[$0]

                            let progressForEvents = events.map { event -> CareTaskProgress in
                                query.computeProgress(event)
                            }

                            let aggregatedProgress = AggregatedCareTaskProgress(combining: progressForEvents)

                            adherenceValues[$0] = .progress(aggregatedProgress.fractionCompleted)
                        }
                    }

                    callbackQueue.async { completion(.success(adherenceValues)) }
                })
            }
        }
    }

    private func groupEventsByDate(events: [OCKAnyEvent], after start: Date, before end: Date) -> [[OCKAnyEvent]] {
        var days: [[OCKAnyEvent]] = []
        let grabDayIndex = { (date: Date) in Calendar.current.dateComponents(Set([.day]), from: start, to: date).day! }
        let numberOfDays = grabDayIndex(end) + 1
        for _ in 0..<numberOfDays {
            days.append([])
        }
        for event in events {
            let dayIndex = grabDayIndex(event.scheduleEvent.start)
            days[dayIndex].append(event)
        }
        return days
    }

    // Builds an array with one entry for each day in the query date range, where the entry is true or false
    // to indicate if there were any tasks defined on that day.
    private func datesWithTasks(query: OCKAdherenceQuery, tasks: [OCKAnyTask]) -> [Bool] {
        query.dates().map { date in tasks.map { $0.schedule.exists(onDay: date) }.contains(true) }
    }
}

// MARK: Async methods for OCKAnyReadOnlyEventStore

public extension OCKAnyReadOnlyEventStore {

    /// `fetchAnyEvents` retrieves all the occurrences of the specified task in the interval specified by the provided query.
    ///
    /// - Parameters:
    ///   - query: A query used to constrain the values that will be fetched.
    func fetchAnyEvents(query: OCKEventQuery) async throws -> [OCKAnyEvent] {
        try await withCheckedThrowingContinuation { continuation in
            fetchAnyEvents(query: query, callbackQueue: .main, completion: continuation.resume)
        }
    }

    /// `fetchAnyEvent` retrieves a single occurrence of the specified task.
    ///
    /// - Parameter task: The task for which to retrieve an event.
    /// - Parameter occurrence: The occurrence index of the desired event.
    func fetchAnyEvent(forTask task: OCKAnyTask, occurrence: Int) async throws -> OCKAnyEvent {
        try await withCheckedThrowingContinuation { continuation in
            fetchAnyEvent(forTask: task, occurrence: occurrence, callbackQueue: .main, completion: continuation.resume)
        }
    }

    /// `fetchAdherence` retrieves all the events and calculates the percent of tasks completed for every day between two dates.
    ///
    /// The way completion is computed depends on how many `expectedValues` a task has. If it has no expected values,
    /// then having an outcome with at least one value will count as complete. If a task has expected values, completion
    /// will be computed as ratio of the number of outcome values to the number of expected values.
    ///
    /// - Parameters:
    ///   - query: A query used to constrain the values that will be fetched.
    func fetchAdherence(query: OCKAdherenceQuery) async throws -> [OCKAdherence] {
        try await withCheckedThrowingContinuation { continuation in
            fetchAdherence(query: query, callbackQueue: .main, completion: continuation.resume)
        }
    }
}
