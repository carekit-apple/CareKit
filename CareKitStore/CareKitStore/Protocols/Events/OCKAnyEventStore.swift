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

/// Any store from which `OCKAnyEvent`s  can be queried is considered `OCKAnyReadOnlyEventStore`.
public protocol OCKAnyReadOnlyEventStore: OCKAnyReadOnlyTaskStore, OCKAnyReadOnlyOutcomeStore {

    /// `fetchAnyEvents` retrieves all the occurrences of the speficied task in the interval specified by the provided query.
    ///
    /// - Parameters:
    ///   - taskID: A user-defined unique identifier for the task.
    ///   - query: A query used to constrain the values that will be fetched.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func fetchAnyEvents(taskID: String, query: OCKEventQuery, callbackQueue: DispatchQueue,
                        completion: @escaping OCKResultClosure<[OCKAnyEvent]>)

    /// `fetchAnyEvent` retrieves a single occurrence of the speficied task.
    ///
    /// - Parameter task: The task for which to retrieve an event.
    /// - Parameter occurrence: The occurrence index of the desired event.
    /// - Parameter queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    /// - Parameter completion: A callback that will fire on the specified queue.
    func fetchAnyEvent(forTask task: OCKAnyTask, occurrence: Int, callbackQueue: DispatchQueue, completion: @escaping OCKResultClosure<OCKAnyEvent>)

    /// `fetchAnyAdherence` retrieves all the events and calculates the percent of tasks completed for every day between two dates.
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

    /// `fetchInsights` computes a metric for a given task between two dates using the provided closure.
    ///
    /// - Parameters:
    ///   - query: A query used to constrain the values that will be fetched.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func fetchInsights(query: OCKInsightQuery, callbackQueue: DispatchQueue, completion: @escaping OCKResultClosure<[Double]>)
}

/// Any store from which `OCKAnyEvent`s  can be queried and also written is considered `OCKAnyEventStore`.
public protocol OCKAnyEventStore: OCKAnyReadOnlyEventStore, OCKAnyTaskStore, OCKAnyOutcomeStore {

}

// MARK: Adherence and Insights Methods for OCKAnyReadOnlyEventStore

public extension OCKAnyReadOnlyEventStore where Self: OCKAnyReadOnlyTaskStore, Self: OCKAnyReadOnlyOutcomeStore {

    func fetchAdherence(query: OCKAdherenceQuery, callbackQueue: DispatchQueue = .main,
                        completion: @escaping OCKResultClosure<[OCKAdherence]>) {
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
                    let query = OCKEventQuery(dateInterval: query.dateInterval)
                    self.fetchAnyEvents(taskID: id, query: query, callbackQueue: callbackQueue, completion: { result in
                        switch result {
                        case .failure(let fetchError):      error = fetchError
                        case .success(let fetchedEvents):   events.append(contentsOf: fetchedEvents)
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
                    indicesWithTasks.forEach { adherenceValues[$0] = query.aggregator.aggregate(events: groupedEvents[$0]) }
                    callbackQueue.async { completion(.success(adherenceValues)) }
                })
            }
        }
    }

    func fetchInsights(query: OCKInsightQuery, callbackQueue: DispatchQueue = .main,
                       completion: @escaping OCKResultClosure<[Double]>) {
        let eventQuery = OCKEventQuery(dateInterval: query.dateInterval)
        fetchAnyEvents(taskID: query.taskID, query: eventQuery, callbackQueue: callbackQueue) { result in
            switch result {
            case .failure(let error): completion(.failure(.fetchFailed(reason: "Failed to fetch insights. \(error.localizedDescription)")))
            case .success(let events):
                let eventsByDay = self.groupEventsByDate(events: events, after: query.dateInterval.start, before: query.dateInterval.end)
                let valuesByDay = eventsByDay.map(query.aggregator.aggregate)
                completion(.success(valuesByDay))
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
