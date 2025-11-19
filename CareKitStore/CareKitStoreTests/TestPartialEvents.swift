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

@testable import CareKitStore
import XCTest

class TestPartialEvents: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)

    private let store = OCKStore(
        name: "TestPartialEventFetcher.Store",
        type: .inMemory
    )

    private var startOfDay: Date {
        Calendar.current.startOfDay(for: Date())
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        try store.reset()
    }

    func testEmptyResult() async throws {

        let query = OCKTaskQuery()

        // Fetch events
        let fetchedEvents = try await [fetchPartialEvents(query: query)]

        // Accumulate streamed events
        let eventsStream = store.partialEvents(matching: query)
        let streamedEvents = try await accumulate(eventsStream, expectedCount: 1)

        // Ensure the results are equal
        XCTAssertEqual(fetchedEvents.first?.count, 0)
        XCTAssertEqual(fetchedEvents, streamedEvents)
    }

    func testSingleTask() async throws {

        // Add a task to the store
        let mealtimesSchedule = OCKSchedule.mealTimesEachDay(start: startOfDay, end: nil)
        let task = OCKTask(id: "task", title: nil, carePlanUUID: nil, schedule: mealtimesSchedule)
        let storedTask = try await store.addTask(task)

        let expectedEvents = [
            [
                PartialEvent(task: storedTask, scheduleEvent: mealtimesSchedule[0]),
                PartialEvent(task: storedTask, scheduleEvent: mealtimesSchedule[1]),
                PartialEvent(task: storedTask, scheduleEvent: mealtimesSchedule[2])
            ]
        ]

        let query = OCKTaskQuery()

        // Fetch events
        let fetchedEvents = try await [fetchPartialEvents(query: query)]

        // Accumulate streamed events
        let eventsStream = store.partialEvents(matching: query)
        let streamedEvents = try await accumulate(eventsStream, expectedCount: 1)

        // Ensure the results are equal
        XCTAssertEqual(expectedEvents, fetchedEvents)
        XCTAssertEqual(fetchedEvents, streamedEvents)
    }

    func testVersionedTask() async throws {

        // Create the initial task
        let mealtimesSchedule = OCKSchedule.mealTimesEachDay(start: startOfDay, end: nil)
        let taskV1 = OCKTask(id: "task", title: nil, carePlanUUID: nil, schedule: mealtimesSchedule)
        let storedTaskV1 = try await store.addTask(taskV1)

        // Update the task schedule. It should occur once at the end of the day
        var taskV2 = storedTaskV1
        let dailySchedule = OCKSchedule.dailyAtTime(hour: 23, minutes: 59, start: startOfDay, end: nil, text: nil)
        taskV2.schedule = dailySchedule
        taskV2.effectiveDate = mealtimesSchedule[1].start
        try await store.updateTask(taskV2)

        // Fetch both task versions
        let tasks = try await store.fetchTasks(query: OCKTaskQuery())
        guard tasks.count == 2 else {
            XCTFail("Unexpected tasks")
            return
        }

        let expectedEvents = [
            [
                PartialEvent(task: tasks[0], scheduleEvent: mealtimesSchedule[0]),
                PartialEvent(task: tasks[1], scheduleEvent: dailySchedule[0])
            ]
        ]

        let query = OCKTaskQuery()

        // Fetch events
        let fetchedEvents = try await [fetchPartialEvents(query: query)]

        // Accumulate streamed events
        let eventsStream = store.partialEvents(matching: query)
        let streamedEvents = try await accumulate(eventsStream, expectedCount: 1)

        // Ensure the results are equal
        XCTAssertEqual(expectedEvents, fetchedEvents)
        XCTAssertEqual(fetchedEvents, streamedEvents)
    }

    func testMultipleTasks() async throws {

        // Add the tasks to the store
        let mealtimesSchedule = OCKSchedule.mealTimesEachDay(start: startOfDay, end: nil)
        let taskA = OCKTask(id: "taskA", title: nil, carePlanUUID: nil, schedule: mealtimesSchedule)
        let taskB = OCKTask(id: "taskB", title: nil, carePlanUUID: nil, schedule: mealtimesSchedule)
        let storedTaskA = try await store.addTask(taskA)
        let storedTaskB = try await store.addTask(taskB)

        let expectedEventsArray = [
            PartialEvent(task: storedTaskB, scheduleEvent: mealtimesSchedule[0]),
            PartialEvent(task: storedTaskB, scheduleEvent: mealtimesSchedule[1]),
            PartialEvent(task: storedTaskB, scheduleEvent: mealtimesSchedule[2]),
            PartialEvent(task: storedTaskA, scheduleEvent: mealtimesSchedule[0]),
            PartialEvent(task: storedTaskA, scheduleEvent: mealtimesSchedule[1]),
            PartialEvent(task: storedTaskA, scheduleEvent: mealtimesSchedule[2])
        ]
        .sorted()

        let expectedEvents = [
            expectedEventsArray
        ]

        let query = OCKTaskQuery()

        // Fetch events
        let fetchedEvents = try await [fetchPartialEvents(query: query)]

        // Accumulate streamed events
        let eventsStream = store.partialEvents(matching: query)
        let streamedEvents = try await accumulate(eventsStream, expectedCount: 1)

        // Ensure the results are equal
        XCTAssertEqual(expectedEvents, fetchedEvents)

        guard let streamedEventsArray = streamedEvents.first else {
            XCTFail("Should have atleast one item")
            return
        }

        XCTAssertEqual(expectedEventsArray.count, streamedEventsArray.count)
        // Streamed tasks are not always in order, check for each one.
        for streamedEvent in streamedEventsArray {
            XCTAssertTrue(expectedEventsArray.contains(streamedEvent))
        }
    }

    func testAllDayScheduleDoesNotReturnEventsAfterScheduleEnd() async throws {

        let now = Date(timeIntervalSinceReferenceDate: 0)

        let schedule = OCKScheduleElement(
            start: now,
            end: nil,
            interval: DateComponents(day: 1),
            text: nil,
            targetValues: [],
            duration: .allDay
        )

        let taskA = OCKTask(id: "task", title: nil, carePlanUUID: nil, schedule: OCKSchedule(composing: [schedule]))
        let persistedTaskA = try await store.addTask(taskA)

        let updatedDate = now + 10
        var endedSchedule = schedule
        endedSchedule.end = updatedDate
        var taskB = persistedTaskA
        taskB.schedule = OCKSchedule(composing: [endedSchedule])
        taskB.effectiveDate = updatedDate
        _ = try await store.updateTask(taskB)

        // Storing new version taskB causes a change to taskA. Fetch the changes.
        let updatedTaskA = try await store
            .fetchTasks(query: OCKTaskQuery())
            .first { $0.uuid == taskA.uuid }
            ?? persistedTaskA

        let queryInterval = DateInterval(
            start: now,
            end: calendar.date(byAdding: .year, value: 1, to: now)!
        )

        let query = OCKTaskQuery(dateInterval: queryInterval)
        let fetchedEvents = try await [fetchPartialEvents(query: query)]
        let eventsStream = store.partialEvents(matching: query)
        let streamedEvents = try await accumulate(eventsStream, expectedCount: 1)
        let expectedEvents = [[PartialEvent(task: updatedTaskA, scheduleEvent: schedule[0])]]

        XCTAssertEqual(fetchedEvents, expectedEvents)
        XCTAssertEqual(streamedEvents, expectedEvents)
    }

    func testLimitedDurationScheduleDoesNotReturnEventsAfterScheduleEnd() async throws {

        let now = Date(timeIntervalSinceReferenceDate: 0)

        let schedule = OCKScheduleElement(
            start: now,
            end: nil,
            interval: DateComponents(day: 1),
            text: nil,
            targetValues: [],
            duration: .seconds(100)
        )

        let taskA = OCKTask(id: "task", title: nil, carePlanUUID: nil, schedule: OCKSchedule(composing: [schedule]))
        let persistedTaskA = try await store.addTask(taskA)

        let updatedDate = now + 10
        var endedSchedule = schedule
        endedSchedule.end = updatedDate
        var taskB = persistedTaskA
        taskB.schedule = OCKSchedule(composing: [endedSchedule])
        taskB.effectiveDate = updatedDate
        _ = try await store.updateTask(taskB)

        // Storing new version taskB causes a change to taskA. Fetch the changes.
        let updatedTaskA = try await store
            .fetchTasks(query: OCKTaskQuery())
            .first { $0.uuid == taskA.uuid }
            ?? persistedTaskA

        let queryInterval = DateInterval(
            start: now,
            end: calendar.date(byAdding: .year, value: 1, to: now)!
        )

        let query = OCKTaskQuery(dateInterval: queryInterval)
        let fetchedEvents = try await [fetchPartialEvents(query: query)]
        let eventsStream = store.partialEvents(matching: query)
        let streamedEvents = try await accumulate(eventsStream, expectedCount: 1)
        let expectedEvents = [[PartialEvent(task: updatedTaskA, scheduleEvent: schedule[0])]]

        XCTAssertEqual(fetchedEvents, expectedEvents)
        XCTAssertEqual(streamedEvents, expectedEvents)
    }

    // MARK: - Utilities

    private func fetchPartialEvents(query: OCKTaskQuery) async throws -> [PartialEvent<OCKTask>] {

        return try await withCheckedThrowingContinuation { [store] continuation in
            store.fetchPartialEvents(
                query: query,
                callbackQueue: .main,
                completion: { result in
                    continuation.resume(with: result)
                }
            )
        }
    }
}
