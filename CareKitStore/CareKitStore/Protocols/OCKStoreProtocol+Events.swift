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

public extension OCKStoreProtocol {
    // MARK: Outcomes

    func fetchOutcome(taskVersionID: OCKLocalVersionID, occurenceIndex: Int, queue: DispatchQueue = .main,
                      completion: @escaping OCKResultClosure<Outcome>) {
        fetchEvent(withTaskVersionID: taskVersionID, occurenceIndex: occurenceIndex, queue: queue, completion: { result in
            switch result {
            case .failure(let error): completion(.failure(.fetchFailed(reason: "Failed to fetch outcome. \(error.localizedDescription)")))
            case .success(let event):
                guard let outcome = event.outcome else { completion(.failure(.fetchFailed(reason: "No matching outcome found"))); return }
                completion(.success(outcome))
            }
        })
    }

    // MARK: Events

    func fetchEvents(taskIdentifier: String, query: OCKEventQuery, queue: DispatchQueue = .main,
                     completion: @escaping OCKResultClosure<[OCKEvent<Task, Outcome>]>) {
        var taskQuery = OCKTaskQuery(from: query)
        taskQuery.limit = 1
        taskQuery.sortDescriptors = [.effectiveDate(ascending: true)]

        fetchTasks(.taskIdentifiers([taskIdentifier]), query: taskQuery, queue: queue, completion: chooseFirst(then: { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let task):
                self.fetchEvents(task: task, query: query, previousEvents: [], queue: queue) { result in
                    completion(result)
                }
            }
        }, replacementError: .fetchFailed(reason: "No task with identifier: \(taskIdentifier) for query: \(taskQuery)")))
    }

    func fetchEvent(withTaskVersionID taskVersionID: OCKLocalVersionID, occurenceIndex: Int,
                    queue: DispatchQueue = .main, completion: @escaping OCKResultClosure<OCKEvent<Task, Outcome>>) {
        fetchTask(withVersionID: taskVersionID, queue: queue, completion: { result in
            switch result {
            case .failure(let error): completion(.failure(.fetchFailed(reason: "Failed to fetch task. \(error.localizedDescription)")))
            case .success(let task):
                guard let scheduleEvent = task.convert().schedule.event(forOccurenceIndex: occurenceIndex) else {
                    completion(.failure(.fetchFailed(reason: "Invalid occurence \(occurenceIndex) for task with version ID: \(taskVersionID)")))
                    return
                }
                let early = scheduleEvent.start.addingTimeInterval(-1)
                let late = scheduleEvent.end.addingTimeInterval(1)
                let query = OCKOutcomeQuery(start: early, end: late)
                self.fetchOutcome(.taskVersions([taskVersionID]), query: query, queue: queue, completion: { result in
                    switch result {
                    case .failure(let error): completion(.failure(.fetchFailed(reason: "Couldn't find outcome. \(error.localizedDescription)")))
                    case .success(let outcome):
                        let event = OCKEvent(task: task, outcome: outcome, scheduleEvent: scheduleEvent)
                        completion(.success(event))
                    }
                })
            }
        })
    }

    // This is a recursive async function that gets all events within a query for a given task, examining all past versions of the task
    private func fetchEvents(task: Task, query: OCKEventQuery, previousEvents: [OCKEvent<Task, Outcome>],
                             queue: DispatchQueue = .main, completion: @escaping (Result<[OCKEvent<Task, Outcome>], OCKStoreError>) -> Void) {
        let converted = task.convert()
        guard let versionID = converted.localDatabaseID else { completion(.failure(.fetchFailed(reason: "Task didn't have a versionID"))); return }
        let start = max(converted.effectiveDate, query.start)
        let end = converted.schedule.end == nil ? query.end : min(converted.schedule.end!, query.end)
        let outcomeQuery = OCKOutcomeQuery(start: start, end: end)
        let scheduleEvents = converted.schedule.events(from: start, to: end)
        self.fetchOutcomes(.taskVersions([versionID]), query: outcomeQuery, queue: queue, completion: { result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let outcomes):
                let events = self.join(task: task, with: outcomes, and: scheduleEvents) + previousEvents
                guard let version = task.convert().previousVersionID else { completion(.success(events)); return }
                self.fetchTask(withVersionID: version, queue: queue, completion: { result in
                    switch result {
                    case .failure(let error): completion(.failure(error))
                    case .success(let task):
                        let nextEndDate = converted.effectiveDate
                        let nextStartDate = max(query.start, task.convert().effectiveDate)
                        let nextQuery = OCKEventQuery(start: nextStartDate, end: nextEndDate)
                        self.fetchEvents(task: task, query: nextQuery, previousEvents: events, queue: queue, completion: { result in
                            completion(result)
                        })
                    }
                })
            }
        })
    }

    private func join(task: Task, with outcomes: [Outcome], and scheduleEvents: [OCKScheduleEvent]) -> [OCKEvent<Task, Outcome>] {
        guard !scheduleEvents.isEmpty else { return [] }
        let offset = scheduleEvents[0].occurence
        var events = scheduleEvents.map { OCKEvent<Task, Outcome>(task: task, outcome: nil, scheduleEvent: $0) }
        for outcome in outcomes {
            events[outcome.convert().taskOccurenceIndex - offset].outcome = outcome
        }
        return events
    }

    // MARK: Adherence

    func fetchAdherence(forTasks identifiers: [String]? = nil, query: OCKAdherenceQuery<Event>,
                        queue: DispatchQueue = .main, completion: @escaping OCKResultClosure<[OCKAdherence]>) {
        let anchor = identifiers == nil ? nil : OCKTaskAnchor.taskIdentifiers(identifiers!)
        let taskQuery = OCKTaskQuery(from: query)

        fetchTasks(anchor, query: taskQuery, queue: queue) { result in
            switch result {
            case .failure(let error): completion(.failure(.fetchFailed(reason: "Failed to fetch adherence. \(error.localizedDescription)")))
            case .success(let tasks):
                let tasks = tasks.filter { $0.convert().impactsAdherence }
                guard !tasks.isEmpty else {
                    let adherences = taskQuery.dates().map { _ in OCKAdherence.noTasks }
                    completion(.success(adherences))
                    return
                }
                let group = DispatchGroup()
                var error: Error?
                var events: [OCKEvent<Task, Outcome>] = []
                for identifier in tasks.map({ $0.convert().identifier }) {
                    group.enter()
                    let query = OCKEventQuery(from: query)
                    self.fetchEvents(taskIdentifier: identifier, query: query, queue: queue, completion: { result in
                        switch result {
                        case .failure(let fetchError):      error = fetchError
                        case .success(let fetchedEvents):   events.append(contentsOf: fetchedEvents)
                        }
                        group.leave()
                    })
                }
                group.notify(queue: .global(qos: .userInitiated), execute: {
                    if let error = error {
                        queue.async {
                            completion(.failure(.fetchFailed(reason: "Failed to fetch completion for tasks! \(error.localizedDescription)")))
                        }
                        return
                    }
                    let groupedEvents = self.groupEventsByDate(events: events, after: query.start, before: query.end)
                    let completionPercentages = groupedEvents.map(query.aggregator.aggregate)
                    queue.async { completion(.success(completionPercentages)) }
                })
            }
        }
    }

    private func groupEventsByDate(events: [Event], after start: Date, before end: Date) -> [[Event]] {
        var days: [[Event]] = []
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

    // MARK: Insights

    func fetchInsights(forTask identifier: String, query: OCKInsightQuery<Event>,
                       queue: DispatchQueue = .main, completion: @escaping OCKResultClosure<[Double]>) {
        let eventQuery = OCKEventQuery(from: query)
        fetchEvents(taskIdentifier: identifier, query: eventQuery, queue: queue) { result in
            switch result {
            case .failure(let error): completion(.failure(.fetchFailed(reason: "Failed to fetch insights. \(error.localizedDescription)")))
            case .success(let events):
                let eventsByDay = self.groupEventsByDate(events: events, after: query.start, before: query.end)
                let valuesByDay = eventsByDay.map(query.aggregator.aggregate)
                completion(.success(valuesByDay))
            }
        }
    }
}
