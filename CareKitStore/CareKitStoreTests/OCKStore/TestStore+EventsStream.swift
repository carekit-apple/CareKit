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

@testable import CareKitStore
import Foundation
import XCTest

class TestStoreEventsStream: XCTestCase {

    private let store = OCKStore(
        name: "TestStoreEventsStream.CDStore",
        type: .inMemory
    )

    override func setUpWithError() throws {
        try super.setUpWithError()

        try store.reset()
    }

    func testInitialEvents() async throws {

        // Add a task to the store

        let task = OCKTask(
            id: "TaskA",
            title: nil,
            carePlanUUID: nil,
            schedule: .mealTimesEachDay(start: Date(), end: nil)
        )

        let storedTask = try store.addTaskAndWait(task)

        let expectedEvents = [
            [
                Event(taskUUID: storedTask.uuid, outcome: nil, scheduleEvent: storedTask.schedule[0]),
                Event(taskUUID: storedTask.uuid, outcome: nil, scheduleEvent: storedTask.schedule[1]),
                Event(taskUUID: storedTask.uuid, outcome: nil, scheduleEvent: storedTask.schedule[2])
            ]
        ]

        // Stream and validate the events from the store

        let eventsOccurringToday = OCKEventQuery(for: Date())

        let events = store.events(matching: eventsOccurringToday)

        let accumulatedEvents = try await accumulate(events, expectedCount: 1)

        let observedEvents = accumulatedEvents.map { events in
            events.map(makeEvent)
        }

        XCTAssertEqual(expectedEvents, observedEvents)
    }

    func testEventsFromDifferentTaskVersions() async throws {

        // Store the initial task

        let task = OCKTask(
            id: "task",
            title: "taskA",
            carePlanUUID: nil,
            schedule: .mealTimesEachDay(start: Date(), end: nil)
        )

        let storedTask = try store.addTaskAndWait(task)

        // Update the task, effective after the first event

        var updatedTask = storedTask
        updatedTask.effectiveDate = task.schedule[1].start
        updatedTask.title = "taskB"

        let storedUpdatedTask = try store.updateTaskAndWait(updatedTask)

        let expectedEvents = [
            [
                Event(taskUUID: storedTask.uuid, outcome: nil, scheduleEvent: storedTask.schedule[0]),
                Event(taskUUID: storedUpdatedTask.uuid, outcome: nil, scheduleEvent: storedUpdatedTask.schedule[1]),
                Event(taskUUID: storedUpdatedTask.uuid, outcome: nil, scheduleEvent: storedUpdatedTask.schedule[2])
            ]
        ]

        // Stream and validate the events from the store

        let eventsOccurringToday = OCKEventQuery(for: Date())

        let events = store.events(matching: eventsOccurringToday)

        let accumulatedEvents = try await accumulate(events, expectedCount: 1)

        let observedEvents = accumulatedEvents.map {
            $0.map(makeEvent)
        }

        XCTAssertEqual(expectedEvents, observedEvents)
    }

    func testEventsReceivedWhenTasksChange() async throws {

        // Add a task to the store

        let task = OCKTask(
            id: "TaskA",
            title: nil,
            carePlanUUID: nil,
            schedule: .mealTimesEachDay(start: Date(), end: nil)
        )

        let storedTask = try store.addTaskAndWait(task)

        let expectedEvents = [
            [
                Event(taskUUID: storedTask.uuid, outcome: nil, scheduleEvent: storedTask.schedule[0]),
                Event(taskUUID: storedTask.uuid, outcome: nil, scheduleEvent: storedTask.schedule[1]),
                Event(taskUUID: storedTask.uuid, outcome: nil, scheduleEvent: storedTask.schedule[2])
            ],
            []
        ]

        // Stream and validate the events from the store

        let eventsOccurringToday = OCKEventQuery(for: Date())

        let events = store.events(matching: eventsOccurringToday)

        let accumulatedEvents = try await accumulate(events, expectedCount: 2) { iter in

            guard iter == 1 else { return }
            store.deleteAnyTask(storedTask)
        }

        let observedEvents = accumulatedEvents.map {
            $0.map(makeEvent)
        }

        XCTAssertEqual(expectedEvents, observedEvents)
    }

    func testEventsReceivedWhenOutcomesChange() async throws {

        // Add a task to the store

        let task = OCKTask(
            id: "TaskA",
            title: nil,
            carePlanUUID: nil,
            schedule: .mealTimesEachDay(start: Date(), end: nil)
        )

        let storedTask = try store.addTaskAndWait(task)

        // Stream and validate the events from the store

        let newOutcome = OCKOutcome(
            taskUUID: storedTask.uuid,
            taskOccurrenceIndex: 0,
            values: []
        )

        var storedOutcome: OCKOutcome?

        let eventsOccurringToday = OCKEventQuery(for: Date())

        let events = store.events(matching: eventsOccurringToday)

        let accumulatedEvents = try await accumulate(events, expectedCount: 2) { iter in

            guard iter == 1 else { return }
            storedOutcome = try await store.addOutcome(newOutcome)
        }

        let expectedEvents = [
            [
                Event(taskUUID: storedTask.uuid, outcome: nil, scheduleEvent: storedTask.schedule[0]),
                Event(taskUUID: storedTask.uuid, outcome: nil, scheduleEvent: storedTask.schedule[1]),
                Event(taskUUID: storedTask.uuid, outcome: nil, scheduleEvent: storedTask.schedule[2])
            ],
            [
                Event(taskUUID: storedTask.uuid, outcome: storedOutcome, scheduleEvent: storedTask.schedule[0]),
                Event(taskUUID: storedTask.uuid, outcome: nil, scheduleEvent: storedTask.schedule[1]),
                Event(taskUUID: storedTask.uuid, outcome: nil, scheduleEvent: storedTask.schedule[2])
            ]
        ]

        let observedEvents = accumulatedEvents.map { events in
            events.map(makeEvent)
        }

        XCTAssertNotNil(storedOutcome)
        XCTAssertEqual(expectedEvents, observedEvents)
    }

    private func makeEvent(from event: OCKStore.Event) -> Event {

        let event = Event(
            taskUUID: event.task.uuid,
            outcome: event.outcome,
            scheduleEvent: event.scheduleEvent
        )

        return event
    }
}

private struct Event: Equatable {

    var taskUUID: UUID
    var outcome: OCKOutcome?
    var scheduleEvent: OCKScheduleEvent
}
