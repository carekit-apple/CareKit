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

        let taskV1 = OCKTask(identifier: "task", title: "Version 1", carePlanID: nil, schedule: schedule1)
        let taskV2 = OCKTask(identifier: "task", title: "Version 2", carePlanID: nil, schedule: schedule2)

        let query = OCKEventQuery(start: queryStart, end: endDate)
        try store.addTaskAndWait(taskV1)
        try store.updateTaskAndWait(taskV2)
        let events = try store.fetchEventsAndWait(taskIdentifier: "task", query: query)
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

        let taskV1 = OCKTask(identifier: "task", title: "Version 1", carePlanID: nil, schedule: schedule1)
        let taskV2 = OCKTask(identifier: "task", title: "Version 2", carePlanID: nil, schedule: schedule2)

        let query = OCKEventQuery(start: date2, end: date4)
        try store.addTaskAndWait(taskV1)
        try store.updateTaskAndWait(taskV2)
        let events = try store.fetchEventsAndWait(taskIdentifier: "task", query: query)
        guard events.count == 4 else { XCTFail("Expected 4 events, but got \(events.count)"); return }
        for index in 0..<1 { XCTAssert(events[index].task.title == taskV1.title) }
        for index in 1..<4 { XCTAssert(events[index].task.title == taskV2.title) }
    }

    func testFetchEventsReturnsEventsWithTheCorrectOccurenceIndex() throws {
        let beginningOfDay = Calendar.current.startOfDay(for: Date())
        let date1 = Calendar.current.date(byAdding: .day, value: -3, to: beginningOfDay)!
        let date2 = Calendar.current.date(byAdding: .day, value: -1, to: beginningOfDay)!
        let date3 = Calendar.current.date(byAdding: .day, value: 3, to: beginningOfDay)!

        let schedule = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: date1, end: nil, text: nil)
        var task = OCKTask(identifier: "task", title: "Medication", carePlanID: nil, schedule: schedule)
        task = try store.addTaskAndWait(task)
        let outcome = OCKOutcome(taskID: task.localDatabaseID, taskOccurenceIndex: 3, values: [])
        try store.addOutcomeAndWait(outcome)

        let query = OCKEventQuery(start: date2, end: date3)
        let events = try store.fetchEventsAndWait(taskIdentifier: task.identifier, query: query)
        XCTAssert(events.count == 4)
        XCTAssert(events[0].scheduleEvent.occurence == 2)
        XCTAssert(events[1].scheduleEvent.occurence == 3)
        XCTAssert(events[2].scheduleEvent.occurence == 4)
        XCTAssert(events[3].scheduleEvent.occurence == 5)
        XCTAssert(events[1].outcome?.taskOccurenceIndex == 3)
    }

    func testFetchSingleEvent() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task = OCKTask(identifier: "exercise", title: "Push Ups", carePlanID: nil, schedule: schedule)
        task = try store.addTaskAndWait(task)
        guard let taskID = task.versionID else { XCTFail("task version ID should not be nil"); return }
        var outcome = OCKOutcome(taskID: taskID, taskOccurenceIndex: 5, values: [])
        outcome = try store.addOutcomeAndWait(outcome)
        let event = try store.fetchEventAndWait(taskVersionID: taskID, occurenceIndex: 5)
        XCTAssert(event.outcome == outcome)
    }

    // tests on an event that only repeats every other day
    // uses excludesTasksWithNoEvents == true on task queries.
    func testFetchEventsEveryOtherDay() throws {
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let startDate = Calendar.current.date(byAdding: DateComponents(day: -1, minute: 5), to: thisMorning)!
        let allDayEveryOtherDay = OCKSchedule(composing: [
            OCKScheduleElement(start: startDate,
                               end: nil,
                               interval: DateComponents(day: 2),
                               text: nil,
                               isAllDay: true)
        ])

        let oneSecondEveryOtherDay = OCKSchedule(composing: [
            OCKScheduleElement(start: startDate,
                               end: nil,
                               interval: DateComponents(day: 2),
                               text: nil,
                               duration: 1)
        ])
        let allDayRepeatingTask1 = OCKTask(identifier: "task1", title: "task1", carePlanID: nil, schedule: allDayEveryOtherDay)
        let shortRepeatingTask2 = OCKTask(identifier: "task2", title: "task2", carePlanID: nil, schedule: oneSecondEveryOtherDay)

        try store.addTaskAndWait(allDayRepeatingTask1)
        try store.addTaskAndWait(shortRepeatingTask2)

        // get yesterday's tasks - there should be 2
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        var yesterdayQuery = OCKTaskQuery(for: yesterday)
        yesterdayQuery.excludesTasksWithNoEvents = true
        var fetched = try store.fetchTasksAndWait(nil, query: yesterdayQuery).map { $0.identifier }
        XCTAssert(fetched.contains(allDayRepeatingTask1.identifier), "failed to fetch all day occurring event")
        XCTAssert(fetched.contains(shortRepeatingTask2.identifier), "failed to fetch yesterday's day occurring event")

        // get today's tasks - there shouldn't be any
        var todayQuery = OCKTaskQuery(for: Date())
        todayQuery.excludesTasksWithNoEvents = true
        fetched = try store.fetchTasksAndWait(nil, query: todayQuery).map { $0.identifier }
        XCTAssert(fetched.isEmpty, "failed to fetch all day occurring event")

        // get tomorrow's tasks - there should be two
        var tomorrowQuery = OCKTaskQuery(for: Date().addingTimeInterval(24 * 60 * 60))
        tomorrowQuery.excludesTasksWithNoEvents = true
        fetched = try store.fetchTasksAndWait(nil, query: tomorrowQuery).map { $0.identifier }
        XCTAssert(fetched.contains(allDayRepeatingTask1.identifier), "failed to fetch all day occurring event")
        XCTAssert(fetched.contains(shortRepeatingTask2.identifier), "failed to fetch yesterday's day occurring event")
    }

    func testFetchEventAfterEnd() throws {
        let endDate = Date().addingTimeInterval(1_000)
        let afterEndDate = Date().addingTimeInterval(1_030)
        let schedule = OCKSchedule(composing: [
            OCKScheduleElement(start: Date(),
                               end: endDate,
                               interval: DateComponents(second: 1))
        ])
        let task = OCKTask(identifier: "exercise", title: "Push Ups", carePlanID: nil, schedule: schedule)
        try store.addTaskAndWait(task)

        var query = OCKTaskQuery(start: afterEndDate, end: Date.distantFuture)
        query.excludesTasksWithNoEvents = true
        let tasks = try store.fetchTasksAndWait(nil, query: query)
        XCTAssert(tasks.isEmpty)
    }

    func testFetchEventsRespectseffectiveDateDate() throws {
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: thisMorning)!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: thisMorning)!

        let scheduleA = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: thisMorning, end: nil, text: nil)
        var versionA = OCKTask(identifier: "A", title: "a", carePlanID: nil, schedule: scheduleA)
        versionA = try store.addTaskAndWait(versionA)

        let scheduleB = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: nextWeek, end: nil, text: nil)
        var versionB = OCKTask(identifier: "A", title: "b", carePlanID: nil, schedule: scheduleB)
        versionB.effectiveDate = tomorrow
        versionB = try store.updateTaskAndWait(versionB)

        let query = OCKEventQuery(start: thisMorning,
                                  end: Calendar.current.date(byAdding: .day, value: 5, to: tomorrow)!)
        let events = try store.fetchEventsAndWait(taskIdentifier: "A", query: query)
        XCTAssert(events.count == 1)
        XCTAssert(events.first?.task.title == versionA.title)
    }

    // MARK: - fetchCompletion

    func testFetchAdherenceAggregatesEventsAcrossTasks() throws {
        let start = Calendar.current.startOfDay(for: Date())
        let twoDaysEarly = Calendar.current.date(byAdding: .day, value: -2, to: start)!
        let twoDaysLater = Calendar.current.date(byAdding: DateComponents(day: 2, second: -1), to: start)!
        let schedule = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: start, end: nil, text: nil)
        let task1 = OCKTask(identifier: "meditate", title: "Medidate", carePlanID: nil, schedule: schedule)
        let task2 = OCKTask(identifier: "sleep", title: "Nap", carePlanID: nil, schedule: schedule)
        let task = try store.addTasksAndWait([task1, task2]).first
        let value = OCKOutcomeValue(20.0, units: "minutes")
        let outcome = OCKOutcome(taskID: task?.localDatabaseID, taskOccurenceIndex: 0, values: [value])
        try store.addOutcomeAndWait(outcome)
        let query = OCKAdherenceQuery<OCKStore.Event>(start: twoDaysEarly, end: twoDaysLater)
        let adherence = try store.fetchAdherenceAndWait(query: query)
        XCTAssert(adherence == [.noEvents, .noEvents, .progress(0.5), .progress(0)])
    }

    func testFetchAdherenceWithCustomAggregator() throws {
        let start = Calendar.current.startOfDay(for: Date())
        let twoDaysEarly = Calendar.current.date(byAdding: .day, value: -2, to: start)!
        let twoDaysLater = Calendar.current.date(byAdding: DateComponents(day: 2, second: -1), to: start)!
        let schedule = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: start, end: nil, text: nil)
        let task = OCKTask(identifier: "meditate", title: "Medidate", carePlanID: nil, schedule: schedule)
        try store.addTaskAndWait(task)
        var query = OCKAdherenceQuery<OCKStore.Event>(start: twoDaysEarly, end: twoDaysLater)
        var timesCalled = 0
        query.aggregator = .custom({ _ in
            timesCalled += 1
            return .progress(0.99)
        })
        let adherence = try store.fetchAdherenceAndWait(query: query)
        XCTAssert(adherence == [.progress(0.99), .progress(0.99), .progress(0.99), .progress(0.99)])
        XCTAssert(timesCalled == 4)
    }

    func testFetchInsights() throws {
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let aWeekAgo = Calendar.current.date(byAdding: DateComponents(second: 1, weekOfYear: -1), to: thisMorning)!
        let schedule = OCKSchedule.dailyAtTime(hour: 8, minutes: 0, start: aWeekAgo, end: nil, text: nil)
        let task = OCKTask(identifier: "walk", title: "Walk", carePlanID: nil, schedule: schedule)
        let mockData: [Double] = [10, 20, 30, 40, 50, 60, 70]
        try store.addTaskAndWait(task)
        var index = -1
        let query = OCKInsightQuery<OCKStore.Event>(
            start: aWeekAgo, end: thisMorning,
            aggregator: .custom({ _ -> Double in
                index += 1
                return mockData[index]
        }))
        let insights = try store.fetchInsightsAndWait(forTask: task.identifier, query: query)
        XCTAssert(insights == mockData)
    }
}
