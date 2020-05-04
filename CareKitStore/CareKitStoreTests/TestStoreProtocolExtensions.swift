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

@testable import CareKitStore
import XCTest

class TestStoreProtocolExtensions: XCTestCase {
    var store: OCKStore!

    override func setUp() {
        super.setUp()
        store = OCKStore(name: "TestDatabase", type: .inMemory)
    }

    override func tearDown() {
        super.tearDown()
        store = nil
    }

    // MARK: - fetchEvents

    func testFetchEventsAcrossVersionsWithNoOverlap() throws {
        let beginningOfDay = Calendar.current.startOfDay(for: Date())
        let queryStart = Calendar.current.date(byAdding: .day, value: -3, to: beginningOfDay)!
        let startDate = Calendar.current.date(byAdding: .day, value: -10, to: beginningOfDay)!
        let midDate = Calendar.current.date(byAdding: .day, value: 0, to: beginningOfDay)!
        let endDate = Calendar.current.date(byAdding: .day, value: 3, to: beginningOfDay)!

        let schedule1 = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: startDate, end: midDate, text: nil)
        let schedule2 = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: midDate, end: endDate, text: nil)

        let taskV1 = OCKTask(id: "task", title: "Version 1", carePlanID: nil, schedule: schedule1)
        let taskV2 = OCKTask(id: "task", title: "Version 2", carePlanID: nil, schedule: schedule2)

        let query = OCKEventQuery(dateInterval: DateInterval(start: queryStart, end: endDate))
        try store.addTaskAndWait(taskV1)
        try store.updateTaskAndWait(taskV2)
        let events = try store.fetchEventsAndWait(taskID: "task", query: query)
        guard events.count == 6 else { XCTFail("Expected 6 events, but got \(events.count)"); return }
        for index in 0..<3 { XCTAssert(events[index].task.title == taskV1.title) }
        for index in 3..<6 { XCTAssert(events[index].task.title == taskV2.title) }
    }

    func testFetchEventsAcrossVersionsWithOverlappingInfiniteSchedules() throws {
        let beginningOfDay = Calendar.current.startOfDay(for: Date())
        let date1 = Calendar.current.date(byAdding: .day, value: -3, to: beginningOfDay)!
        let date2 = Calendar.current.date(byAdding: .day, value: -1, to: beginningOfDay)!
        let date3 = Calendar.current.date(byAdding: .day, value: -0, to: beginningOfDay)!
        let date4 = Calendar.current.date(byAdding: .day, value: 3, to: beginningOfDay)!

        let schedule1 = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: date1, end: nil, text: nil)
        let schedule2 = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: date3, end: nil, text: nil)

        let taskV1 = OCKTask(id: "task", title: "Version 1", carePlanID: nil, schedule: schedule1)
        let taskV2 = OCKTask(id: "task", title: "Version 2", carePlanID: nil, schedule: schedule2)

        let query = OCKEventQuery(dateInterval: DateInterval(start: date2, end: date4))
        try store.addTaskAndWait(taskV1)
        try store.updateTaskAndWait(taskV2)
        let events = try store.fetchEventsAndWait(taskID: "task", query: query)
        guard events.count == 4 else { XCTFail("Expected 4 events, but got \(events.count)"); return }
        for index in 0..<1 { XCTAssert(events[index].task.title == taskV1.title) }
        for index in 1..<4 { XCTAssert(events[index].task.title == taskV2.title) }
    }

    func testFetchEventsReturnsEventsWithTheCorrectOccurrenceIndex() throws {
        let beginningOfDay = Calendar.current.startOfDay(for: Date())
        let date1 = Calendar.current.date(byAdding: .day, value: -3, to: beginningOfDay)!
        let date2 = Calendar.current.date(byAdding: .day, value: -1, to: beginningOfDay)!
        let date3 = Calendar.current.date(byAdding: .day, value: 3, to: beginningOfDay)!

        let schedule = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: date1, end: nil, text: nil)
        var task = OCKTask(id: "task", title: "Medication", carePlanID: nil, schedule: schedule)
        task = try store.addTaskAndWait(task)
        let outcome = OCKOutcome(taskID: try task.getLocalID(), taskOccurrenceIndex: 3, values: [])
        try store.addOutcomeAndWait(outcome)

        let query = OCKEventQuery(dateInterval: DateInterval(start: date2, end: date3))
        let events = try store.fetchEventsAndWait(taskID: task.id, query: query)
        XCTAssert(events.count == 4)
        XCTAssert(events[0].scheduleEvent.occurrence == 2)
        XCTAssert(events[1].scheduleEvent.occurrence == 3)
        XCTAssert(events[2].scheduleEvent.occurrence == 4)
        XCTAssert(events[3].scheduleEvent.occurrence == 5)
        XCTAssert(events[1].outcome?.taskOccurrenceIndex == 3)
    }

    func testFetchSingleEvent() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task = OCKTask(id: "exercise", title: "Push Ups", carePlanID: nil, schedule: schedule)
        task = try store.addTaskAndWait(task)
        let taskID = try task.getLocalID()
        var outcome = OCKOutcome(taskID: taskID, taskOccurrenceIndex: 5, values: [])
        outcome = try store.addOutcomeAndWait(outcome)
        let event = try store.fetchEventAndWait(forTask: task, occurrence: 5)
        XCTAssert(event.outcome == outcome)
    }

    func testFetchSingleEventFailsIfTaskIsNotPersistedYet() {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = OCKTask(id: "exercise", title: "Push Ups", carePlanID: nil, schedule: schedule)
        XCTAssertThrowsError(try store.fetchEventAndWait(forTask: task, occurrence: 0))
    }

    func testFetchEventsEveryOtherDay() throws {
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
        let allDayRepeatingTask1 = OCKTask(id: "task1", title: "task1", carePlanID: nil, schedule: allDayEveryOtherDay)
        let shortRepeatingTask2 = OCKTask(id: "task2", title: "task2", carePlanID: nil, schedule: oneSecondEveryOtherDay)

        try store.addTaskAndWait(allDayRepeatingTask1)
        try store.addTaskAndWait(shortRepeatingTask2)

        // Yesterday's tasks - there should be 2
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        var yesterdayQuery = OCKTaskQuery(for: yesterday)
        yesterdayQuery.excludesTasksWithNoEvents = true
        var fetched = try store.fetchTasksAndWait(query: yesterdayQuery).map { $0.id }
        XCTAssert(fetched.contains(allDayRepeatingTask1.id), "failed to fetch all day occurring event")
        XCTAssert(fetched.contains(shortRepeatingTask2.id), "failed to fetch yesterday's day occurring event")

        // Today's tasks - there shouldn't be any
        var todayQuery = OCKTaskQuery(for: Date())
        todayQuery.excludesTasksWithNoEvents = true
        fetched = try store.fetchTasksAndWait(query: todayQuery).map { $0.id }
        XCTAssert(fetched.isEmpty, "Expected 0, but got \(fetched)")

        // Tomorrow's tasks - there should be two
        var tomorrowQuery = OCKTaskQuery(for: Date().addingTimeInterval(24 * 60 * 60))
        tomorrowQuery.excludesTasksWithNoEvents = true
        fetched = try store.fetchTasksAndWait(query: tomorrowQuery).map { $0.id }
        XCTAssert(fetched.contains(allDayRepeatingTask1.id), "failed to fetch all day occurring event")
        XCTAssert(fetched.contains(shortRepeatingTask2.id), "failed to fetch yesterday's day occurring event")
    }

    func testFetchEventAfterEnd() throws {
        let endDate = Date().addingTimeInterval(1_000)
        let afterEndDate = Date().addingTimeInterval(1_030)
        let schedule = OCKSchedule(composing: [
            OCKScheduleElement(start: Date(),
                               end: endDate,
                               interval: DateComponents(second: 1))
        ])
        let task = OCKTask(id: "exercise", title: "Push Ups", carePlanID: nil, schedule: schedule)
        try store.addTaskAndWait(task)

        let interval = DateInterval(start: afterEndDate, end: Date.distantFuture)
        var query = OCKTaskQuery(dateInterval: interval)
        query.excludesTasksWithNoEvents = true
        let tasks = try store.fetchTasksAndWait(query: query)
        XCTAssert(tasks.isEmpty)
    }

    func testFetchEventsRespectsEffectiveDateDate() throws {
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: thisMorning)!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: thisMorning)!

        let scheduleA = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: thisMorning, end: nil, text: nil)
        var versionA = OCKTask(id: "A", title: "a", carePlanID: nil, schedule: scheduleA)
        versionA = try store.addTaskAndWait(versionA)

        let scheduleB = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: nextWeek, end: nil, text: nil)
        var versionB = OCKTask(id: "A", title: "b", carePlanID: nil, schedule: scheduleB)
        versionB.effectiveDate = tomorrow
        versionB = try store.updateTaskAndWait(versionB)

        let interval = DateInterval(start: thisMorning, end: Calendar.current.date(byAdding: .day, value: 5, to: tomorrow)!)
        let query = OCKEventQuery(dateInterval: interval)
        let events = try store.fetchEventsAndWait(taskID: "A", query: query)
        XCTAssert(events.count == 1, "Expected to get 1 event, but got \(events.count)")
        XCTAssert(events.first?.task.title == versionA.title)
    }

    func testFetchEventsReturnsOnlyTheNewerOfTwoEventsWhenTwoVersionsOfATaskHaveEventsAtQueryStart() throws {
        let element = OCKScheduleElement(start: Date(), end: nil, interval: DateComponents(day: 1),
                                         text: nil, targetValues: [], duration: .allDay)
        let schedule = OCKSchedule(composing: [element])
        let versionA = OCKTask(id: "123", title: "A", carePlanID: nil, schedule: schedule)
        try store.addTaskAndWait(versionA)
        var versionB = OCKTask(id: "123", title: "B", carePlanID: nil, schedule: schedule)
        versionB.effectiveDate = schedule[4].start
        try store.updateTaskAndWait(versionB)
        let events = try store.fetchEventsAndWait(taskID: "123", query: .init(for: schedule[4].start))
        XCTAssert(events.count == 1, "Expected 1, but got \(events.count)")
        XCTAssert(events.first?.task.title == "B")
    }

    func testFetchEventsReturnsAnEventForEachVersionOfATaskWhenEventsAreAllDayDuration() throws {
        let midnight = Calendar.current.startOfDay(for: Date())
        let schedule = OCKSchedule.dailyAtTime(hour: 0, minutes: 0, start: midnight, end: nil, text: nil, duration: .allDay, targetValues: [])
        let task = OCKTask(id: "A", title: "Original", carePlanID: nil, schedule: schedule)
        try store.addTaskAndWait(task)
        for i in 1...10 {
            var update = task
            update.effectiveDate = midnight.advanced(by: 10 * TimeInterval(i))
            update.title = "Update \(i)"
            try store.updateTaskAndWait(update)
        }
        let events = try store.fetchEventsAndWait(taskID: "A", query: .init(for: midnight))
        XCTAssert(events.count == 11)
    }

    func testFetchSingleEventSucceedsEvenIfThereIsNoOutcome() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(id: "A", title: "ABC", carePlanID: nil, schedule: schedule))
        XCTAssertNoThrow(try store.fetchEventAndWait(forTask: task, occurrence: 0))
    }

    // MARK: Adherence and Insights

    func testFetchAdherenceAggregatesEventsAcrossTasks() throws {
        let start = Calendar.current.startOfDay(for: Date())
        let twoDaysEarly = Calendar.current.date(byAdding: .day, value: -2, to: start)!
        let twoDaysLater = Calendar.current.date(byAdding: DateComponents(day: 2, second: -1), to: start)!
        let element = OCKScheduleElement(start: start, end: nil, interval: DateComponents(day: 2))
        let schedule = OCKSchedule(composing: [element])
        let task1 = OCKTask(id: "meditate", title: "Medidate", carePlanID: nil, schedule: schedule)
        let task2 = OCKTask(id: "sleep", title: "Nap", carePlanID: nil, schedule: schedule)
        let task = try store.addTasksAndWait([task1, task2]).first!
        let taskID = try task.getLocalID()
        let value = OCKOutcomeValue(20.0, units: "minutes")
        let outcome = OCKOutcome(taskID: taskID, taskOccurrenceIndex: 0, values: [value])
        try store.addOutcomeAndWait(outcome)
        let query = OCKAdherenceQuery(taskIDs: [task1.id, task2.id], dateInterval: DateInterval(start: twoDaysEarly, end: twoDaysLater))
        let adherence = try store.fetchAdherenceAndWait(query: query)
        XCTAssert(adherence == [.noTasks, .noTasks, .progress(0.5), .noEvents])
    }

    func testFetchAdherenceWithCustomAggregator() throws {
        let start = Calendar.current.startOfDay(for: Date())
        let twoDaysEarly = Calendar.current.date(byAdding: .day, value: -2, to: start)!
        let twoDaysLater = Calendar.current.date(byAdding: DateComponents(day: 2, second: -1), to: start)!
        let schedule = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: start, end: nil, text: nil)
        let task = OCKTask(id: "meditate", title: "Medidate", carePlanID: nil, schedule: schedule)
        try store.addTaskAndWait(task)
        var query = OCKAdherenceQuery(taskIDs: [task.id], dateInterval: DateInterval(start: twoDaysEarly, end: twoDaysLater))
        var timesCalled = 0
        query.aggregator = .custom({ _ in
            timesCalled += 1
            return .progress(0.99)
        })
        let adherence = try store.fetchAdherenceAndWait(query: query)
        XCTAssert(adherence == [.noTasks, .noTasks, .progress(0.99), .progress(0.99)])
        XCTAssert(timesCalled == 2)
    }

    func testFetchInsights() throws {
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let aWeekAgo = Calendar.current.date(byAdding: DateComponents(second: 1, weekOfYear: -1), to: thisMorning)!
        let schedule = OCKSchedule.dailyAtTime(hour: 8, minutes: 0, start: aWeekAgo, end: nil, text: nil)
        let task = OCKTask(id: "walk", title: "Walk", carePlanID: nil, schedule: schedule)
        let mockData: [Double] = [10, 20, 30, 40, 50, 60, 70]
        try store.addTaskAndWait(task)
        var index = -1
        let query = OCKInsightQuery(taskID: task.id,
                                    dateInterval: DateInterval(start: aWeekAgo, end: thisMorning),
                                    aggregator: .custom({ _ -> Double in
                index += 1
                return mockData[index]
        }))
        let insights = try store.fetchInsightsAndWait(query: query)
        XCTAssert(insights == mockData)
    }
}
