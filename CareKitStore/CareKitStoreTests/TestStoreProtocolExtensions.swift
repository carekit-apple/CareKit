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

import Foundation

@testable import CareKitStore
import Synchronization
import XCTest


class TestStoreProtocolExtensions: XCTestCase {

    private typealias Event = OCKEvent<OCKTask, OCKOutcome>

    private let calendar = Calendar.current

    private lazy var beginningOfYear: Date = {
        let components = DateComponents(year: 2_023, month: 1, day: 1)
        let date = calendar.date(from: components)!
        return date
    }()

    var store: OCKStore!

    override func setUp() {
        super.setUp()
        store = OCKStore(name: UUID().uuidString, type: .inMemory)
    }

    // MARK: - fetchEvents

    func testFetchEventsAcrossVersionsWithNoOverlap() async throws {
        let beginningOfDay = Calendar.current.startOfDay(for: Date())
        let queryStart = Calendar.current.date(byAdding: .day, value: -3, to: beginningOfDay)!
        let startDate = Calendar.current.date(byAdding: .day, value: -10, to: beginningOfDay)!
        let midDate = Calendar.current.date(byAdding: .day, value: 0, to: beginningOfDay)!
        let endDate = Calendar.current.date(byAdding: .day, value: 3, to: beginningOfDay)!

        let schedule1 = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: startDate, end: midDate, text: nil)
        let schedule2 = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: midDate, end: endDate, text: nil)

        let taskV1 = OCKTask(id: "task", title: "Version 1", carePlanUUID: nil, schedule: schedule1)
        let taskV2 = OCKTask(id: "task", title: "Version 2", carePlanUUID: nil, schedule: schedule2)

        var query = OCKEventQuery(dateInterval: DateInterval(start: queryStart, end: endDate))
        query.taskIDs = ["task"]

        try await store.addTask(taskV1)
        try await store.updateTask(taskV2)
        let events = try await store.fetchEvents(query: query)
        guard events.count == 6 else { XCTFail("Expected 6 events, but got \(events.count)"); return }
        for index in 0..<3 { XCTAssertEqual(events[index].task.title, taskV1.title) }
        for index in 3..<6 { XCTAssertEqual(events[index].task.title, taskV2.title) }
    }

    func testFetchEventsAcrossVersionsWithOverlappingInfiniteSchedules() async throws {
        let beginningOfDay = Calendar.current.startOfDay(for: Date())
        let date1 = Calendar.current.date(byAdding: .day, value: -3, to: beginningOfDay)!
        let date2 = Calendar.current.date(byAdding: .day, value: -1, to: beginningOfDay)!
        let date3 = Calendar.current.date(byAdding: .day, value: -0, to: beginningOfDay)!
        let date4 = Calendar.current.date(byAdding: .day, value: 3, to: beginningOfDay)!

        let schedule1 = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: date1, end: nil, text: nil)
        let schedule2 = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: date3, end: nil, text: nil)

        let taskV1 = OCKTask(id: "task", title: "Version 1", carePlanUUID: nil, schedule: schedule1)
        let taskV2 = OCKTask(id: "task", title: "Version 2", carePlanUUID: nil, schedule: schedule2)

        var query = OCKEventQuery(dateInterval: DateInterval(start: date2, end: date4))
        query.taskIDs = ["task"]

        try await store.addTask(taskV1)
        try await store.updateTask(taskV2)
        let events = try await store.fetchEvents(query: query)
        guard events.count == 4 else { XCTFail("Expected 4 events, but got \(events.count)"); return }
        for index in 0..<1 { XCTAssertEqual(events[index].task.title, taskV1.title) }
        for index in 1..<4 { XCTAssertEqual(events[index].task.title, taskV2.title) }
    }

    func testFetchEventsReturnsEventsWithTheCorrectOccurrenceIndex() async throws {
        let beginningOfDay = Calendar.current.startOfDay(for: Date())
        let date1 = Calendar.current.date(byAdding: .day, value: -3, to: beginningOfDay)!
        let date2 = Calendar.current.date(byAdding: .day, value: -1, to: beginningOfDay)!
        let date3 = Calendar.current.date(byAdding: .day, value: 3, to: beginningOfDay)!

        let schedule = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: date1, end: nil, text: nil)
        var task = OCKTask(id: "task", title: "Medication", carePlanUUID: nil, schedule: schedule)
        task = try await store.addTask(task)
        let outcome = OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: 3, values: [])
        try await store.addOutcome(outcome)

        var query = OCKEventQuery(dateInterval: DateInterval(start: date2, end: date3))
        query.taskIDs = [task.id]

        let events = try await store.fetchEvents(query: query)
        XCTAssertEqual(events.count, 4)
        XCTAssertEqual(events[0].scheduleEvent.occurrence, 2)
        XCTAssertEqual(events[1].scheduleEvent.occurrence, 3)
        XCTAssertEqual(events[2].scheduleEvent.occurrence, 4)
        XCTAssertEqual(events[3].scheduleEvent.occurrence, 5)
        XCTAssertEqual(events[1].outcome?.taskOccurrenceIndex, 3)
    }

    func testFetchEventsEveryOtherDay() async throws {
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let startDate = Calendar.current.date(byAdding: DateComponents(day: -1, minute: 5), to: thisMorning)!

        let allDayEveryOtherDay = OCKSchedule(composing: [
            OCKScheduleElement(start: startDate,
                               end: nil,
                               interval: DateComponents(day: 2),
                               text: nil,
                               duration: .allDay)
        ])

        let oneSecondEveryOtherDay = OCKSchedule(composing: [
            OCKScheduleElement(start: startDate,
                               end: nil,
                               interval: DateComponents(day: 2),
                               text: nil,
                               duration: .seconds(1))
        ])
        let allDayRepeatingTask1 = OCKTask(id: "task1", title: "task1", carePlanUUID: nil, schedule: allDayEveryOtherDay)
        let shortRepeatingTask2 = OCKTask(id: "task2", title: "task2", carePlanUUID: nil, schedule: oneSecondEveryOtherDay)

        try await store.addTask(allDayRepeatingTask1)
        try await store.addTask(shortRepeatingTask2)

        // Yesterday's tasks - there should be 2
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        var yesterdayQuery = OCKTaskQuery(for: yesterday)
        yesterdayQuery.excludesTasksWithNoEvents = true
        var fetched = try await store.fetchTasks(query: yesterdayQuery).map { $0.id }
        XCTAssert(fetched.contains(allDayRepeatingTask1.id), "failed to fetch all day occurring event")
        XCTAssert(fetched.contains(shortRepeatingTask2.id), "failed to fetch yesterday's day occurring event")

        // Today's tasks - there shouldn't be any
        var todayQuery = OCKTaskQuery(for: Date())
        todayQuery.excludesTasksWithNoEvents = true
        fetched = try await store.fetchTasks(query: todayQuery).map { $0.id }
        XCTAssert(fetched.isEmpty, "Expected 0, but got \(fetched)")

        // Tomorrow's tasks - there should be two
        var tomorrowQuery = OCKTaskQuery(for: Date().addingTimeInterval(24 * 60 * 60))
        tomorrowQuery.excludesTasksWithNoEvents = true
        fetched = try await store.fetchTasks(query: tomorrowQuery).map { $0.id }
        XCTAssert(fetched.contains(allDayRepeatingTask1.id), "failed to fetch all day occurring event")
        XCTAssert(fetched.contains(shortRepeatingTask2.id), "failed to fetch yesterday's day occurring event")
    }

    func testFetchEventAfterEnd() async throws {
        let endDate = Date().addingTimeInterval(1_000)
        let afterEndDate = Date().addingTimeInterval(1_030)
        let schedule = OCKSchedule(composing: [
            OCKScheduleElement(start: Date(),
                               end: endDate,
                               interval: DateComponents(second: 1))
        ])
        let task = OCKTask(id: "exercise", title: "Push Ups", carePlanUUID: nil, schedule: schedule)
        try await store.addTask(task)

        let interval = DateInterval(start: afterEndDate, end: Date.distantFuture)
        var query = OCKTaskQuery(dateInterval: interval)
        query.excludesTasksWithNoEvents = true
        let tasks = try await store.fetchTasks(query: query)
        XCTAssert(tasks.isEmpty)
    }

    func testFetchEventsRespectsEffectiveDateDate() async throws {
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: thisMorning)!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: thisMorning)!

        let scheduleA = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: thisMorning, end: nil, text: nil)
        var versionA = OCKTask(id: "A", title: "a", carePlanUUID: nil, schedule: scheduleA)
        versionA = try await store.addTask(versionA)

        let scheduleB = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: nextWeek, end: nil, text: nil)
        var versionB = OCKTask(id: "A", title: "b", carePlanUUID: nil, schedule: scheduleB)
        versionB.effectiveDate = tomorrow
        versionB = try await store.updateTask(versionB)

        let interval = DateInterval(start: thisMorning, end: Calendar.current.date(byAdding: .day, value: 5, to: tomorrow)!)
        var query = OCKEventQuery(dateInterval: interval)
        query.taskIDs = ["A"]

        let events = try await store.fetchEvents(query: query)
        XCTAssertEqual(events.count, 1, "Expected to get 1 event, but got \(events.count)")
        XCTAssertEqual(events.first?.task.title, versionA.title)
    }

    func testFetchEventsReturnsOnlyTheNewerOfTwoEventsWhenTwoVersionsOfATaskHaveEventsAtQueryStart() async throws {
        let element = OCKScheduleElement(start: Date(), end: nil, interval: DateComponents(day: 1),
                                         text: nil, targetValues: [], duration: .allDay)
        let schedule = OCKSchedule(composing: [element])
        let versionA = OCKTask(id: "123", title: "A", carePlanUUID: nil, schedule: schedule)
        try await store.addTask(versionA)
        var versionB = OCKTask(id: "123", title: "B", carePlanUUID: nil, schedule: schedule)
        versionB.effectiveDate = schedule[4].start
        try await store.updateTask(versionB)

        var query = OCKEventQuery(for: schedule[4].start)
        query.taskIDs = ["123"]

        let events = try await store.fetchEvents(query: query)
        XCTAssertEqual(events.count, 1, "Expected 1, but got \(events.count)")
        XCTAssertEqual(events.first?.task.title, "B")
    }

    func testFetchEventsReturnsAnEventForEachVersionOfATaskWhenEventsAreAllDayDuration() async throws {
        let midnight = Calendar.current.startOfDay(for: Date())
        let schedule = OCKSchedule.dailyAtTime(hour: 0, minutes: 0, start: midnight, end: nil, text: nil, duration: .allDay, targetValues: [])
        let task = OCKTask(id: "A", title: "Original", carePlanUUID: nil, schedule: schedule)
        try await store.addTask(task)
        for i in 1...10 {
            var update = task
            update.effectiveDate = midnight.advanced(by: 10 * TimeInterval(i))
            update.title = "Update \(i)"
            try await store.updateTask(update)
        }

        var query = OCKEventQuery(for: midnight)
        query.taskIDs = ["A"]

        let events = try await store.fetchEvents(query: query)
        XCTAssertEqual(events.count, 11)
    }

    func testFetchingEventsForMultipleTasks() async throws {
        let schedule = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: Date(), end: nil, text: nil)
        let taskA = OCKTask(id: "A", title: "A", carePlanUUID: nil, schedule: schedule)
        let taskB = OCKTask(id: "B", title: "B", carePlanUUID: nil, schedule: schedule)
        try await store.addTasks([taskA, taskB])

        let query = OCKEventQuery(for: Date())
        let events = try await store.fetchEvents(query: query)
        let tasks = Set(events.map { $0.task.id })
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(tasks, Set(["A", "B"]))
    }

    func testFetchZeroDurationEventWithQueryEndOnEventStart() async throws {

        // Event interval:   |
        // Effective:        |--------------
        // Query:            |

        // Generate a daily task
        let daily = DateComponents(day: 1)
        let dailySchedule = OCKScheduleElement(start: beginningOfYear, end: nil, interval: daily, duration: .seconds(0))
        let task = OCKTask(id: "steps", title: nil, carePlanUUID: nil, schedule: OCKSchedule(composing: [dailySchedule]))
        let storedTask = try await store.addTask(task)

        // Generate an outcome for the task
        let outcome = OCKOutcome(taskUUID: storedTask.uuid, taskOccurrenceIndex: 0, values: [])
        _ = try await store.addOutcome(outcome)

        // Create a query that ends before the end of the event
        let queryInterval = DateInterval(
            start: dailySchedule[0].start,
            end: dailySchedule[0].start
        )

        // Fetch events from the store
        let query = OCKEventQuery(dateInterval: queryInterval)
        let fetchedEvents = try await store.fetchEvents(query: query)
        let streamedEvents = try await accumulate(store.events(matching: query), expectedCount: 1).flatMap { $0 }

        // Validate the result

        let expectedEvents: [Event] = []

        XCTAssertEqual(expectedEvents, fetchedEvents)
        XCTAssertEqual(fetchedEvents, streamedEvents)
    }

    func testFetchZeroDurationEventWithQueryStartOnEventStart() async throws {

        // Event interval:   |
        // Effective:        |--------------
        // Query:            |--|

        // Generate a daily task
        let daily = DateComponents(day: 1)
        let dailySchedule = OCKScheduleElement(start: beginningOfYear, end: nil, interval: daily, duration: .seconds(0))
        let task = OCKTask(id: "steps", title: nil, carePlanUUID: nil, schedule: OCKSchedule(composing: [dailySchedule]))
        let storedTask = try await store.addTask(task)

        // Generate an outcome for the task
        let outcome = OCKOutcome(taskUUID: storedTask.uuid, taskOccurrenceIndex: 0, values: [])
        let storedOutcome = try await store.addOutcome(outcome)

        // Create a query that ends before the end of the event
        let queryInterval = DateInterval(
            start: dailySchedule[0].start,
            end: dailySchedule[0].start + 1
        )

        // Fetch events from the store
        let query = OCKEventQuery(dateInterval: queryInterval)
        let fetchedEvents = try await store.fetchEvents(query: query)
        let streamedEvents = try await accumulate(store.events(matching: query), expectedCount: 1).flatMap { $0 }

        let fetchedEventsByOccurrence = [
            try await store.fetchEvent(forTask: storedTask, occurrence: 0)
        ]

        // Validate the result

        let expectedEvents: [Event] = [
            Event(task: storedTask, outcome: storedOutcome, scheduleEvent: dailySchedule[0])
        ]

        XCTAssertEqual(expectedEvents, fetchedEvents)
        XCTAssertEqual(expectedEvents, fetchedEventsByOccurrence)
        XCTAssertEqual(fetchedEventsByOccurrence, streamedEvents)
    }

    func testFetchEventWithQueryEndAfterEventEnd() async throws {

        // Event interval:   |-------|
        // Effective:        |--------------
        // Query:               |--------|

        // Generate a daily task
        let daily = DateComponents(day: 1)
        let dailySchedule = OCKScheduleElement(start: beginningOfYear, end: nil, interval: daily, duration: .hours(1))
        let task = OCKTask(id: "steps", title: nil, carePlanUUID: nil, schedule: OCKSchedule(composing: [dailySchedule]))
        let storedTask = try await store.addTask(task)

        // Generate an outcome for the task
        let outcome = OCKOutcome(taskUUID: storedTask.uuid, taskOccurrenceIndex: 0, values: [])
        let storedOutcome = try await store.addOutcome(outcome)

        // Create a query that ends before the end of the event
        let queryInterval = DateInterval(
            start: dailySchedule[0].start + 60,  // 60s after the event starts
            end: dailySchedule[0].end + 60       // 60s after the event ends
        )

        // Fetch events from the store
        let query = OCKEventQuery(dateInterval: queryInterval)
        let fetchedEvents = try await store.fetchEvents(query: query)
        let streamedEvents = try await accumulate(store.events(matching: query), expectedCount: 1).flatMap { $0 }

        let fetchedEventsByOccurrence = [
            try await store.fetchEvent(forTask: storedTask, occurrence: 0)
        ]

        // Validate the result

        let expectedEvents = [
            Event(task: storedTask, outcome: storedOutcome, scheduleEvent: dailySchedule[0])
        ]

        XCTAssertEqual(expectedEvents, fetchedEvents)
        XCTAssertEqual(expectedEvents, fetchedEventsByOccurrence)
        XCTAssertEqual(fetchedEventsByOccurrence, streamedEvents)
    }

    func testFetchEventWithQueryStartOnEventEnd() async throws {

        // Event interval:   |-------|
        // Effective:        |-------------------
        // Query:                    |--------|

        // Generate a daily task
        let daily = DateComponents(day: 1)
        let dailySchedule = OCKScheduleElement(start: beginningOfYear, end: nil, interval: daily, duration: .hours(1))
        let task = OCKTask(id: "steps", title: nil, carePlanUUID: nil, schedule: OCKSchedule(composing: [dailySchedule]))
        let storedTask = try await store.addTask(task)

        // Generate an outcome for the task
        let outcome = OCKOutcome(taskUUID: storedTask.uuid, taskOccurrenceIndex: 0, values: [])
        let storedOutcome = try await store.addOutcome(outcome)

        // Create a query that ends before the end of the event
        let queryInterval = DateInterval(
            start: dailySchedule[0].end,
            end: dailySchedule[0].end + 60
        )

        // Fetch events from the store
        let query = OCKEventQuery(dateInterval: queryInterval)
        let fetchedEvents = try await store.fetchEvents(query: query)
        let streamedEvents = try await accumulate(store.events(matching: query), expectedCount: 1).flatMap { $0 }

        let fetchedEventsByOccurrence = [
            try await store.fetchEvent(forTask: storedTask, occurrence: 0)
        ]

        // Validate the result

        let expectedEvents = [
            Event(task: storedTask, outcome: storedOutcome, scheduleEvent: dailySchedule[0])
        ]

        XCTAssertEqual(expectedEvents, fetchedEvents)
        XCTAssertEqual(expectedEvents, fetchedEventsByOccurrence)
        XCTAssertEqual(fetchedEventsByOccurrence, streamedEvents)
    }

    func testFetchEventWithQueryStartBeforeEventStart() async throws {

        // Event interval:       |-------|
        // Effective:            |-------------------
        // Query:            |--------|

        // Generate a daily task
        let daily = DateComponents(day: 1)
        let dailySchedule = OCKScheduleElement(start: beginningOfYear, end: nil, interval: daily, duration: .hours(1))
        let task = OCKTask(id: "steps", title: nil, carePlanUUID: nil, schedule: OCKSchedule(composing: [dailySchedule]))
        let storedTask = try await store.addTask(task)

        // Generate an outcome for the task
        let outcome = OCKOutcome(taskUUID: storedTask.uuid, taskOccurrenceIndex: 0, values: [])
        let storedOutcome = try await store.addOutcome(outcome)

        // Create a query that ends before the end of the event
        let queryInterval = DateInterval(
            start: dailySchedule[0].start - 1,
            end: dailySchedule[0].start + 1
        )

        // Fetch events from the store
        let query = OCKEventQuery(dateInterval: queryInterval)
        let fetchedEvents = try await store.fetchEvents(query: query)
        let streamedEvents = try await accumulate(store.events(matching: query), expectedCount: 1).flatMap { $0 }

        let fetchedEventsByOccurrence = [
            try await store.fetchEvent(forTask: storedTask, occurrence: 0)
        ]

        // Validate the result

        let expectedEvents = [
            Event(task: storedTask, outcome: storedOutcome, scheduleEvent: dailySchedule[0])
        ]

        XCTAssertEqual(expectedEvents, fetchedEvents)
        XCTAssertEqual(expectedEvents, fetchedEventsByOccurrence)
        XCTAssertEqual(fetchedEventsByOccurrence, streamedEvents)
    }

    func testFetchEventWithQueryEndOnEventStart() async throws {

        // Event interval:           |-------|
        // Effective:                |-------------------
        // Query:           |--------|

        // Generate a daily task
        let daily = DateComponents(day: 1)
        let dailySchedule = OCKScheduleElement(start: beginningOfYear, end: nil, interval: daily, duration: .hours(1))
        let task = OCKTask(id: "steps", title: nil, carePlanUUID: nil, schedule: OCKSchedule(composing: [dailySchedule]))
        let storedTask = try await store.addTask(task)

        // Generate an outcome for the task
        let outcome = OCKOutcome(taskUUID: storedTask.uuid, taskOccurrenceIndex: 0, values: [])
        let storedOutcome = try await store.addOutcome(outcome)

        // Create a query that ends before the end of the event
        let queryInterval = DateInterval(
            start: dailySchedule[0].start - 1,
            end: dailySchedule[0].start + 1
        )

        // Fetch events from the store
        let query = OCKEventQuery(dateInterval: queryInterval)
        let fetchedEvents = try await store.fetchEvents(query: query)
        let streamedEvents = try await accumulate(store.events(matching: query), expectedCount: 1).flatMap { $0 }

        let fetchedEventsByOccurrence = [
            try await store.fetchEvent(forTask: storedTask, occurrence: 0)
        ]

        // Validate the result

        let expectedEvents = [
            Event(task: storedTask, outcome: storedOutcome, scheduleEvent: dailySchedule[0])
        ]

        XCTAssertEqual(expectedEvents, fetchedEvents)
        XCTAssertEqual(expectedEvents, fetchedEventsByOccurrence)
        XCTAssertEqual(fetchedEventsByOccurrence, streamedEvents)
    }

    func testFetchEventWithQueryBeforeEvent() async throws {

        // Event interval:             |-------|
        // Effective:                  |-------------------
        // Query:           |--------|

        // Generate a daily task
        let daily = DateComponents(day: 1)
        let dailySchedule = OCKScheduleElement(start: beginningOfYear, end: nil, interval: daily, duration: .hours(1))
        let task = OCKTask(id: "steps", title: nil, carePlanUUID: nil, schedule: OCKSchedule(composing: [dailySchedule]))
        let storedTask = try await store.addTask(task)

        // Generate an outcome for the task
        let outcome = OCKOutcome(taskUUID: storedTask.uuid, taskOccurrenceIndex: 0, values: [])
        _ = try await store.addOutcome(outcome)

        // Create a query that ends before the end of the event
        let queryInterval = DateInterval(
            start: dailySchedule[0].start - 2,
            end: dailySchedule[0].start - 1
        )

        // Fetch events from the store
        let query = OCKEventQuery(dateInterval: queryInterval)
        let fetchedEvents = try await store.fetchEvents(query: query)
        let streamedEvents = try await accumulate(store.events(matching: query), expectedCount: 1).flatMap { $0 }

        // Validate the result

        let expectedEvents: [Event] = []

        XCTAssertEqual(expectedEvents, fetchedEvents)
        XCTAssertEqual(fetchedEvents, streamedEvents)
    }

    func testFetchEventWithQueryAfterEvent() async throws {

        // Event interval:   |-------|
        // Effective:        |-------------------
        // Query:                      |--------|

        // Generate a daily task
        let daily = DateComponents(day: 1)
        let dailySchedule = OCKScheduleElement(start: beginningOfYear, end: nil, interval: daily, duration: .hours(1))
        let task = OCKTask(id: "steps", title: nil, carePlanUUID: nil, schedule: OCKSchedule(composing: [dailySchedule]))
        let storedTask = try await store.addTask(task)

        // Generate an outcome for the task
        let outcome = OCKOutcome(taskUUID: storedTask.uuid, taskOccurrenceIndex: 0, values: [])
        _ = try await store.addOutcome(outcome)

        // Create a query that ends before the end of the event
        let queryInterval = DateInterval(
            start: dailySchedule[0].end + 1,
            end: dailySchedule[0].end + 2
        )

        // Fetch events from the store
        let query = OCKEventQuery(dateInterval: queryInterval)
        let fetchedEvents = try await store.fetchEvents(query: query)
        let streamedEvents = try await accumulate(store.events(matching: query), expectedCount: 1).flatMap { $0 }

        // Validate the result

        let expectedEvents: [Event] = []

        XCTAssertEqual(expectedEvents, fetchedEvents)
        XCTAssertEqual(fetchedEvents, streamedEvents)
    }

    func testFetchEventWithQueryEndBeforeEventEnd() async throws {

        // Event interval:   |-------|
        // Effective:        |-----------
        // Query:               |--|

        // Generate a daily task
        let daily = DateComponents(day: 1)
        let dailySchedule = OCKScheduleElement(start: beginningOfYear, end: nil, interval: daily, duration: .hours(1))
        let task = OCKTask(id: "steps", title: nil, carePlanUUID: nil, schedule: OCKSchedule(composing: [dailySchedule]))
        let storedTask = try await store.addTask(task)

        // Generate an outcome for the task
        let outcome = OCKOutcome(taskUUID: storedTask.uuid, taskOccurrenceIndex: 0, values: [])
        let storedOutcome = try await store.addOutcome(outcome)

        // Create a query that ends before the end of the event
        let queryInterval = DateInterval(
            start: dailySchedule[0].start + 60,  // 60s after the event starts
            end: dailySchedule[0].end - 60       // 60s before the event ends
        )

        // Fetch events from the store
        let query = OCKEventQuery(dateInterval: queryInterval)
        let fetchedEvents = try await store.fetchEvents(query: query)
        let streamedEvents = try await accumulate(store.events(matching: query), expectedCount: 1).flatMap { $0 }

        let fetchedEventsByOccurrence = [
            try await store.fetchEvent(forTask: storedTask, occurrence: 0)
        ]

        // Validate the result

        let expectedEvents = [
            Event(task: storedTask, outcome: storedOutcome, scheduleEvent: dailySchedule[0])
        ]

        XCTAssertEqual(expectedEvents, fetchedEvents)
        XCTAssertEqual(expectedEvents, fetchedEventsByOccurrence)
        XCTAssertEqual(fetchedEventsByOccurrence, streamedEvents)
    }

    func testFetchEventsForAllDayVersionedTaskReturnsBothVersions() async throws {

        // Event interval:     |-------|
        // Effective A:        |--------------
        // Effective B:          |------------
        // Query:              |-------|

        // Store a daily, all day task
        let daily = DateComponents(day: 1)
        let dailySchedule = OCKScheduleElement(start: beginningOfYear, end: nil, interval: daily, duration: .allDay)
        var taskA = OCKTask(id: "steps", title: nil, carePlanUUID: nil, schedule: OCKSchedule(composing: [dailySchedule]))
        taskA.effectiveDate = beginningOfYear
        var storedTaskA = try await store.addTask(taskA)

        // Update the effective date for the task. The effective date should be later than
        // that of the first version, but in the span of the first event.
        var taskB = storedTaskA
        taskB.effectiveDate = beginningOfYear + 1
        let storedTaskB = try await store.updateTask(taskB)

        // Fetch the changes to task A that point to task B
        storedTaskA = try await fetchTask(withUUID: storedTaskA.uuid)

        // Generate outcomes for each event
        let outcomeA = OCKOutcome(taskUUID: storedTaskA.uuid, taskOccurrenceIndex: 0, values: [])
        let outcomeB = OCKOutcome(taskUUID: storedTaskB.uuid, taskOccurrenceIndex: 0, values: [])
        let storedOutcomeA = try await store.addOutcome(outcomeA)
        let storedOutcomeB = try await store.addOutcome(outcomeB)

        // Fetch events from the store
        let query = OCKEventQuery(for: beginningOfYear)
        let fetchedEvents = try await store.fetchEvents(query: query)
        let streamedEvents = try await accumulate(store.events(matching: query), expectedCount: 1).flatMap { $0 }

        let fetchedEventsByOccurrence = [
            try await store.fetchEvent(forTask: storedTaskA, occurrence: 0),
            try await store.fetchEvent(forTask: storedTaskB, occurrence: 0)
        ]
        .sorted()

        // Validate the result, expecting an event from each task

        let expectedEvents = [
            Event(task: storedTaskA, outcome: storedOutcomeA, scheduleEvent: dailySchedule[0]),
            Event(task: storedTaskB, outcome: storedOutcomeB, scheduleEvent: dailySchedule[0])
        ]
        .sorted()

        XCTAssertEqual(expectedEvents, fetchedEvents)
        XCTAssertEqual(expectedEvents, fetchedEventsByOccurrence)
        XCTAssertEqual(fetchedEventsByOccurrence, streamedEvents)
    }

    func testFetchEventsForFixedLengthVersionedTaskReturnsBothVersions() async throws {

        // Event interval:     |-------|
        // Effective A:        |--------------
        // Effective B:          |------------
        // Query:              |-------|

        // Store a daily task that lasts an hour
        let daily = DateComponents(day: 1)
        let dailySchedule = OCKScheduleElement(start: beginningOfYear, end: nil, interval: daily, duration: .hours(1))
        var taskA = OCKTask(id: "steps", title: nil, carePlanUUID: nil, schedule: OCKSchedule(composing: [dailySchedule]))
        taskA.effectiveDate = beginningOfYear
        var storedTaskA = try await store.addTask(taskA)

        // Update the effective date for the task. The effective date should be later than
        // that of the first version, but in the span of the first event.
        var taskB = storedTaskA
        taskB.effectiveDate = beginningOfYear + 1
        let storedTaskB = try await store.updateTask(taskB)

        // Fetch the changes to task A
        storedTaskA = try await fetchTask(withUUID: storedTaskA.uuid)

        // Generate outcomes for each event
        let outcomeA = OCKOutcome(taskUUID: storedTaskA.uuid, taskOccurrenceIndex: 0, values: [])
        let outcomeB = OCKOutcome(taskUUID: storedTaskB.uuid, taskOccurrenceIndex: 0, values: [])
        let storedOutcomeA = try await store.addOutcome(outcomeA)
        let storedOutcomeB = try await store.addOutcome(outcomeB)

        // Fetch events from the store
        let query = OCKEventQuery(for: beginningOfYear)
        let fetchedEvents = try await store.fetchEvents(query: query)
        let streamedEvents = try await accumulate(store.events(matching: query), expectedCount: 1).flatMap { $0 }

        let fetchedEventsByOccurrence = [
            try await store.fetchEvent(forTask: storedTaskA, occurrence: 0),
            try await store.fetchEvent(forTask: storedTaskB, occurrence: 0)
        ]
        .sorted()

        // Validate the result, expecting an event from each task

        let expectedEvents = [
            Event(task: storedTaskA, outcome: storedOutcomeA, scheduleEvent: dailySchedule[0]),
            Event(task: storedTaskB, outcome: storedOutcomeB, scheduleEvent: dailySchedule[0])
        ]
        .sorted()

        XCTAssertEqual(expectedEvents, fetchedEvents)
        XCTAssertEqual(expectedEvents, fetchedEventsByOccurrence)
        XCTAssertEqual(fetchedEventsByOccurrence, streamedEvents)
    }

    func testFetchEventsForAllDayVersionedTaskReturnsNewestVersion() async throws {

        // Event interval:     |-------|
        // Effective A:        |--------------
        // Effective B:        |--------------
        // Query:              |-------|

        // Generate a daily, all day task
        let daily = DateComponents(day: 1)
        let dailySchedule = OCKScheduleElement(start: beginningOfYear, end: nil, interval: daily, duration: .allDay)
        let taskA = OCKTask(id: "steps", title: nil, carePlanUUID: nil, schedule: OCKSchedule(composing: [dailySchedule]))
        var storedTaskA = try await store.addTask(taskA)

        // Update the task, leaving all information the same. Since the effective date does not
        // change, this task should supersede the previous version.
        let storedTaskB = try await store.updateTask(storedTaskA)

        // Fetch the changes to task A
        storedTaskA = try await fetchTask(withUUID: storedTaskA.uuid)

        // Generate an outcome
        let outcomeB = OCKOutcome(taskUUID: storedTaskB.uuid, taskOccurrenceIndex: 0, values: [])
        let storedOutcomeB = try await store.addOutcome(outcomeB)

        // Fetch events from the store
        let query = OCKEventQuery(for: beginningOfYear)
        let fetchedEvents = try await store.fetchEvents(query: query)
        let streamedEvents = try await accumulate(store.events(matching: query), expectedCount: 1).flatMap { $0 }

        let fetchedEventsByOccurrence = [
            try await store.fetchEvent(forTask: storedTaskB, occurrence: 0)
        ]

        // Validate the result, expecting an event from the newest task

        let expectedEvents = [
            Event(task: storedTaskB, outcome: storedOutcomeB, scheduleEvent: dailySchedule[0])
        ]

        XCTAssertEqual(expectedEvents, fetchedEvents)
        XCTAssertEqual(expectedEvents, fetchedEventsByOccurrence)
        XCTAssertEqual(fetchedEventsByOccurrence, streamedEvents)
    }

    func testFetchEventsForFixedLengthVersionedTaskReturnsOneVersion() async throws {

        // Event interval:     |-------|
        // Effective A:        |--------------
        // Effective B:        |--------------
        // Query:              |-------|

        // Generate a daily, all day task
        let daily = DateComponents(day: 1)
        let dailySchedule = OCKScheduleElement(start: beginningOfYear, end: nil, interval: daily, duration: .hours(1))
        let taskA = OCKTask(id: "steps", title: nil, carePlanUUID: nil, schedule: OCKSchedule(composing: [dailySchedule]))
        var storedTaskA = try await store.addTask(taskA)

        // Update the task, leaving all information the same. Since the effective date does not
        // change, this task should supersede the previous version.
        let storedTaskB = try await store.updateTask(storedTaskA)

        // Fetch the changes to task A
        storedTaskA = try await fetchTask(withUUID: storedTaskA.uuid)

        // Generate an outcome
        let outcomeB = OCKOutcome(taskUUID: storedTaskB.uuid, taskOccurrenceIndex: 0, values: [])
        let storedOutcomeB = try await store.addOutcome(outcomeB)

        // Fetch events from the store
        let query = OCKEventQuery(for: beginningOfYear)
        let fetchedEvents = try await store.fetchEvents(query: query)
        let streamedEvents = try await accumulate(store.events(matching: query), expectedCount: 1).flatMap { $0 }

        let fetchedEventsByOccurrence = [
            try await store.fetchEvent(forTask: storedTaskB, occurrence: 0)
        ]

        // Validate the result, expecting an event from the newest task

        let expectedEvents = [
            Event(task: storedTaskB, outcome: storedOutcomeB, scheduleEvent: dailySchedule[0])
        ]

        XCTAssertEqual(expectedEvents, fetchedEvents)
        XCTAssertEqual(expectedEvents, fetchedEventsByOccurrence)
        XCTAssertEqual(fetchedEventsByOccurrence, streamedEvents)
    }

    func testFetchEventsForUpdatedTaskWithEarlierEffectiveDate() async throws {

        // Event interval:     |-------|
        // Effective A:        |--------------
        // Effective B:      |----------------
        // Query:              |-------|

        // Store a daily, all day task
        let daily = DateComponents(day: 1)
        let dailySchedule = OCKScheduleElement(start: beginningOfYear, end: nil, interval: daily, duration: .allDay)
        var taskA = OCKTask(id: "steps", title: "A", carePlanUUID: nil, schedule: OCKSchedule(composing: [dailySchedule]))
        taskA.effectiveDate = beginningOfYear
        var storedTaskA = try await store.addTask(taskA)

        // Update the effective date for the task. The effective date should be earlier than
        // that of the first version.
        var taskB = storedTaskA
        taskB.effectiveDate = beginningOfYear - 1
        _ = try await store.updateTask(taskB)

        // Fetch the changes to task A that point to task B
        storedTaskA = try await fetchTask(withUUID: storedTaskA.uuid)

        // Generate an outcome
        let outcomeA = OCKOutcome(taskUUID: storedTaskA.uuid, taskOccurrenceIndex: 0, values: [])
        let storedOutcomeA = try await store.addOutcome(outcomeA)

        // Fetch events from the store
        let query = OCKEventQuery(for: beginningOfYear)
        let fetchedEvents = try await store.fetchEvents(query: query)
        let streamedEvents = try await accumulate(store.events(matching: query), expectedCount: 1).flatMap { $0 }

        let fetchedEventsByOccurrence = [
            try await store.fetchEvent(forTask: storedTaskA, occurrence: 0)
        ]

        // Validate the result, expecting an event from each task

        let expectedEvents = [
            Event(task: storedTaskA, outcome: storedOutcomeA, scheduleEvent: dailySchedule[0])
        ]

        XCTAssertEqual(expectedEvents, fetchedEvents)
        XCTAssertEqual(expectedEvents, fetchedEventsByOccurrence)
        XCTAssertEqual(fetchedEventsByOccurrence, streamedEvents)
    }

    func testNewVersionWithEffectiveDateOnStartOfEvent() async throws {

        // Event interval A:      |-------|   |-------|    |-------|
        // Event interval B:                             |-------|
        // Effective A:           |-----------------------------------------
        // Effective B:                       |-----------------------------
        // Query:              |---------------------------------------|

        // Store a daily task that occurs at mealtimes
        let mealtimes = OCKSchedule.mealTimesEachDay(start: beginningOfYear, end: nil)
        var taskA = OCKTask(id: "steps", title: "A", carePlanUUID: nil, schedule: mealtimes)
        taskA.effectiveDate = beginningOfYear
        var storedTaskA = try await store.addTask(taskA)

        // Update the schedule to occur daily, effective at the end of the first event.
        var taskB = storedTaskA
        let daily = OCKSchedule.dailyAtTime(hour: 20, minutes: 0, start: beginningOfYear, end: nil, text: nil)
        taskB.schedule = daily
        taskB.effectiveDate = mealtimes[1].start
        let storedTaskB = try await store.updateTask(taskB)

        // Fetch the changes to task A that point to task B
        storedTaskA = try await fetchTask(withUUID: storedTaskA.uuid)

        // Generate outcomes
        let outcomeA = OCKOutcome(taskUUID: storedTaskA.uuid, taskOccurrenceIndex: 0, values: [])
        let outcomeB = OCKOutcome(taskUUID: storedTaskB.uuid, taskOccurrenceIndex: 0, values: [])
        let storedOutcomeA = try await store.addOutcome(outcomeA)
        let storedOutcomeB = try await store.addOutcome(outcomeB)

        // Fetch events from the store
        let query = OCKEventQuery(for: beginningOfYear)
        let fetchedEvents = try await store.fetchEvents(query: query)
        let streamedEvents = try await accumulate(store.events(matching: query), expectedCount: 1).flatMap { $0 }

        let fetchedEventsByOccurrence = [
            try await store.fetchEvent(forTask: storedTaskA, occurrence: 0),
            try await store.fetchEvent(forTask: storedTaskB, occurrence: 0)
        ]

        // Validate the result, expecting an event from each task

        let expectedEvents = [
            Event(task: storedTaskA, outcome: storedOutcomeA, scheduleEvent: mealtimes[0]),
            Event(task: storedTaskB, outcome: storedOutcomeB, scheduleEvent: daily[0])
        ]
        .sorted()

        XCTAssertEqual(expectedEvents, fetchedEvents)
        XCTAssertEqual(expectedEvents, fetchedEventsByOccurrence)
        XCTAssertEqual(fetchedEventsByOccurrence, streamedEvents)
    }

    func testNewVersionWithEffectiveDateOnEndOfEvent() async throws {

        // Event interval A:      |-------|   |-------|    |-------|
        // Event interval B:                             |-------|
        // Effective A:           |-----------------------------------------
        // Effective B:                               |---------------------
        // Query:              |---------------------------------------|

        // Store a daily task that occurs at mealtimes
        let mealtimes = OCKSchedule.mealTimesEachDay(start: beginningOfYear, end: nil)
        var taskA = OCKTask(id: "steps", title: "A", carePlanUUID: nil, schedule: mealtimes)
        taskA.effectiveDate = beginningOfYear
        var storedTaskA = try await store.addTask(taskA)

        // Update the schedule to occur daily, effective at the end of the first event.
        var taskB = storedTaskA
        let daily = OCKSchedule.dailyAtTime(hour: 20, minutes: 0, start: beginningOfYear, end: nil, text: nil)
        taskB.schedule = daily
        taskB.effectiveDate = mealtimes[1].end
        let storedTaskB = try await store.updateTask(taskB)

        // Fetch the changes to task A that point to task B
        storedTaskA = try await fetchTask(withUUID: storedTaskA.uuid)

        // Generate outcomes
        let outcomeA1 = OCKOutcome(taskUUID: storedTaskA.uuid, taskOccurrenceIndex: 0, values: [])
        let outcomeA2 = OCKOutcome(taskUUID: storedTaskA.uuid, taskOccurrenceIndex: 1, values: [])
        let outcomeB = OCKOutcome(taskUUID: storedTaskB.uuid, taskOccurrenceIndex: 0, values: [])
        let storedOutcomeA1 = try await store.addOutcome(outcomeA1)
        let storedOutcomeA2 = try await store.addOutcome(outcomeA2)
        let storedOutcomeB = try await store.addOutcome(outcomeB)

        // Fetch events from the store
        let query = OCKEventQuery(for: beginningOfYear)
        let fetchedEvents = try await store.fetchEvents(query: query)
        let streamedEvents = try await accumulate(store.events(matching: query), expectedCount: 1).flatMap { $0 }

        let fetchedEventsByOccurrence = [
            try await store.fetchEvent(forTask: storedTaskA, occurrence: 0),
            try await store.fetchEvent(forTask: storedTaskA, occurrence: 1),
            try await store.fetchEvent(forTask: storedTaskB, occurrence: 0)
        ]

        // Validate the result, expecting an event from each task

        let expectedEvents = [
            Event(task: storedTaskA, outcome: storedOutcomeA1, scheduleEvent: mealtimes[0]),
            Event(task: storedTaskA, outcome: storedOutcomeA2, scheduleEvent: mealtimes[1]),
            Event(task: storedTaskB, outcome: storedOutcomeB, scheduleEvent: daily[0])
        ]
        .sorted()

        XCTAssertEqual(expectedEvents, fetchedEvents)
        XCTAssertEqual(expectedEvents, fetchedEventsByOccurrence)
        XCTAssertEqual(fetchedEventsByOccurrence, streamedEvents)
    }

    func testNewVersionWithEffectiveBeforeEndOfEvent() async throws {

        // Event interval A:      |-------|   |-------|    |-------|
        // Event interval B:                             |-------|
        // Effective A:           |-----------------------------------------
        // Effective B:                            |------------------------
        // Query:              |---------------------------------------|

        // Store a daily task that occurs at mealtimes
        let mealtimes = OCKSchedule.mealTimesEachDay(start: beginningOfYear, end: nil)
        var taskA = OCKTask(id: "steps", title: "A", carePlanUUID: nil, schedule: mealtimes)
        taskA.effectiveDate = beginningOfYear
        var storedTaskA = try await store.addTask(taskA)

        // Update the schedule to occur daily, effective at the end of the first event.
        var taskB = storedTaskA
        let daily = OCKSchedule.dailyAtTime(hour: 20, minutes: 0, start: beginningOfYear, end: nil, text: nil)
        taskB.schedule = daily
        taskB.effectiveDate = mealtimes[1].end - 1
        let storedTaskB = try await store.updateTask(taskB)

        // Fetch the changes to task A that point to task B
        storedTaskA = try await fetchTask(withUUID: storedTaskA.uuid)

        // Generate outcomes
        let outcomeA1 = OCKOutcome(taskUUID: storedTaskA.uuid, taskOccurrenceIndex: 0, values: [])
        let outcomeA2 = OCKOutcome(taskUUID: storedTaskA.uuid, taskOccurrenceIndex: 1, values: [])
        let outcomeB = OCKOutcome(taskUUID: storedTaskB.uuid, taskOccurrenceIndex: 0, values: [])
        let storedOutcomeA1 = try await store.addOutcome(outcomeA1)
        let storedOutcomeA2 = try await store.addOutcome(outcomeA2)
        let storedOutcomeB = try await store.addOutcome(outcomeB)

        // Fetch events from the store
        let query = OCKEventQuery(for: beginningOfYear)
        let fetchedEvents = try await store.fetchEvents(query: query)
        let streamedEvents = try await accumulate(store.events(matching: query), expectedCount: 1).flatMap { $0 }

        let fetchedEventsByOccurrence = [
            try await store.fetchEvent(forTask: storedTaskA, occurrence: 0),
            try await store.fetchEvent(forTask: storedTaskA, occurrence: 1),
            try await store.fetchEvent(forTask: storedTaskB, occurrence: 0)
        ]

        // Validate the result, expecting an event from each task

        let expectedEvents = [
            Event(task: storedTaskA, outcome: storedOutcomeA1, scheduleEvent: mealtimes[0]),
            Event(task: storedTaskA, outcome: storedOutcomeA2, scheduleEvent: mealtimes[1]),
            Event(task: storedTaskB, outcome: storedOutcomeB, scheduleEvent: daily[0])
        ]
        .sorted()

        XCTAssertEqual(expectedEvents, fetchedEvents)
        XCTAssertEqual(expectedEvents, fetchedEventsByOccurrence)
        XCTAssertEqual(fetchedEventsByOccurrence, streamedEvents)
    }

    func testFetchEventsWithSameScheduleReturnsSortedEvents() async throws {

        // Generate multiple duplicate tasks

        let scheduleWithDuplicateEvents = OCKSchedule(
            composing: [
                OCKScheduleElement(start: beginningOfYear, end: nil, interval: DateComponents(day: 1)),
                OCKScheduleElement(start: beginningOfYear, end: nil, interval: DateComponents(day: 1)),
                OCKScheduleElement(start: beginningOfYear, end: nil, interval: DateComponents(day: 1))
            ]
        )

        var tasks = [
            OCKTask(id: "b", title: nil, carePlanUUID: nil, schedule: scheduleWithDuplicateEvents),
            OCKTask(id: "c", title: nil, carePlanUUID: nil, schedule: scheduleWithDuplicateEvents),
            OCKTask(id: "a", title: nil, carePlanUUID: nil, schedule: scheduleWithDuplicateEvents)
        ]

        // Choosing UUIDs helps us determine what the final event sort order will be
        tasks[0].uuid = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!
        tasks[1].uuid = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        tasks[2].uuid = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!

        let storedTasks = try await store.addTasks(tasks)

        // Fetch events from the store
        let query = OCKEventQuery(for: beginningOfYear)
        let fetchedEvents = try await store.fetchEvents(query: query)
        let streamedEvents = try await accumulate(store.events(matching: query), expectedCount: 1).flatMap { $0 }

        // Validate the result

        let expectedEvents: [OCKEvent<OCKTask, OCKOutcome>] = [
            OCKEvent(task: storedTasks[0], outcome: nil, scheduleEvent: storedTasks[0].schedule.event(forOccurrenceIndex: 0)!),
            OCKEvent(task: storedTasks[0], outcome: nil, scheduleEvent: storedTasks[0].schedule.event(forOccurrenceIndex: 1)!),
            OCKEvent(task: storedTasks[0], outcome: nil, scheduleEvent: storedTasks[0].schedule.event(forOccurrenceIndex: 2)!),
            OCKEvent(task: storedTasks[1], outcome: nil, scheduleEvent: storedTasks[1].schedule.event(forOccurrenceIndex: 0)!),
            OCKEvent(task: storedTasks[1], outcome: nil, scheduleEvent: storedTasks[1].schedule.event(forOccurrenceIndex: 1)!),
            OCKEvent(task: storedTasks[1], outcome: nil, scheduleEvent: storedTasks[1].schedule.event(forOccurrenceIndex: 2)!),
            OCKEvent(task: storedTasks[2], outcome: nil, scheduleEvent: storedTasks[1].schedule.event(forOccurrenceIndex: 0)!),
            OCKEvent(task: storedTasks[2], outcome: nil, scheduleEvent: storedTasks[1].schedule.event(forOccurrenceIndex: 1)!),
            OCKEvent(task: storedTasks[2], outcome: nil, scheduleEvent: storedTasks[1].schedule.event(forOccurrenceIndex: 2)!)
        ]

        let expectedSortedEvents = expectedEvents.sorted()

        // Make sure the events don't happen to be sorted coincidentally
        XCTAssertNotEqual(expectedEvents, fetchedEvents)

        XCTAssertEqual(fetchedEvents, expectedSortedEvents)
        XCTAssertEqual(streamedEvents, expectedSortedEvents)
    }

    // MARK: Adherence

    func testFetchAdherenceAggregatesEventsAcrossTasks() async throws {
        let start = Calendar.current.startOfDay(for: Date())
        let twoDaysEarly = Calendar.current.date(byAdding: .day, value: -2, to: start)!
        let twoDaysLater = Calendar.current.date(byAdding: DateComponents(day: 2, second: -1), to: start)!
        let element = OCKScheduleElement(start: start, end: nil, interval: DateComponents(day: 2))
        let schedule = OCKSchedule(composing: [element])
        let task1 = OCKTask(id: "meditate", title: "Medidate", carePlanUUID: nil, schedule: schedule)
        let task2 = OCKTask(id: "sleep", title: "Nap", carePlanUUID: nil, schedule: schedule)
        let task = try await store.addTasks([task1, task2]).first!
        let taskID = task.uuid
        let value = OCKOutcomeValue(20.0, units: "minutes")
        let outcome = OCKOutcome(taskUUID: taskID, taskOccurrenceIndex: 0, values: [value])
        try await store.addOutcome(outcome)
        let query = OCKAdherenceQuery(taskIDs: [task1.id, task2.id], dateInterval: DateInterval(start: twoDaysEarly, end: twoDaysLater))
        let adherence = try await store.fetchAdherence(query: query)
        XCTAssertEqual(
            adherence,
            [.noTasks, .noTasks, .progress(0.5), .noEvents]
        )
    }

    func testFetchAdherenceWithCustomAggregator() async throws {
        let start = Calendar.current.startOfDay(for: Date())
        let twoDaysEarly = Calendar.current.date(byAdding: .day, value: -2, to: start)!
        let twoDaysLater = Calendar.current.date(byAdding: DateComponents(day: 2, second: -1), to: start)!
        let schedule = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: start, end: nil, text: nil)
        let task = OCKTask(id: "meditate", title: "Medidate", carePlanUUID: nil, schedule: schedule)
        try await store.addTask(task)

        let timesCalled = Mutex(0)

        let query = OCKAdherenceQuery(
            taskIDs: [task.id],
            dateInterval: DateInterval(start: twoDaysEarly, end: twoDaysLater),
            computeProgress: { _ in
                timesCalled.withLock { $0 += 1 }
                return LinearCareTaskProgress(value: 1, goal: 2)
            }
        )

        let adherence = try await store.fetchAdherence(query: query)
        XCTAssertEqual(adherence, [.noTasks, .noTasks, .progress(0.5), .progress(0.5)])
        XCTAssertEqual(timesCalled.value(), 2)
    }

    private func fetchTask(withUUID uuid: UUID) async throws -> OCKTask {

        var query = OCKTaskQuery()
        query.uuids = [uuid]

        let result = try await store
            .fetchTasks(query: query)
            .first

        guard let result else {
            throw OCKStoreError.fetchFailed(reason: "Expected to find task with UUID: \(uuid)")
        }

        return result
    }
}

