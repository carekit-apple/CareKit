/*
 Copyright (c) 2020, Apple Inc. All rights reserved.

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

@testable import CareKit
@testable import CareKitStore
import Foundation
import XCTest


class TestTaskEvents: XCTestCase {

    func testInitWithNoEvents() {
        let taskEvents = OCKTaskEvents()
        XCTAssertTrue(taskEvents.isEmpty)
    }

    func testTasks() {
        let doxylamineUUID = UUID()
        let nauseauUUID = UUID()
        let events: [OCKAnyEvent] = [
            OCKAnyEvent.mock(taskUUID: doxylamineUUID, occurrence: 0),
            OCKAnyEvent.mock(taskUUID: doxylamineUUID, occurrence: 1),
            OCKAnyEvent.mock(taskUUID: nauseauUUID, occurrence: 0)
        ]
        let taskEvents = OCKTaskEvents(events: events)

        let expected = [events[0].task, events[2].task]
            .map { $0.id }
        let observed = taskEvents.tasks.map { $0.id }
        XCTAssertEqual(observed, expected)
    }

    func testInitForEventsWithUniqueOccurrences() {
        let doxylamineUUID = UUID()
        let nauseauUUID = UUID()
        let events: [OCKAnyEvent] = [
            OCKAnyEvent.mock(taskUUID: doxylamineUUID, occurrence: 0),
            OCKAnyEvent.mock(taskUUID: doxylamineUUID, occurrence: 1),
            OCKAnyEvent.mock(taskUUID: nauseauUUID, occurrence: 0)
        ]
        let taskEvents = OCKTaskEvents(events: events)

        let expected = events.map { $0.id }
        let observed = taskEvents.flatMap { $0.map(\.id) }
        XCTAssertEqual(observed, expected)
    }

    func testInitForEventsWithDuplicateOccurrences() {
        let doxylamineUUID = UUID()
        let events: [OCKAnyEvent] = [
            OCKAnyEvent.mock(taskUUID: doxylamineUUID, occurrence: 0),
            OCKAnyEvent.mock(taskUUID: doxylamineUUID, occurrence: 0)
        ]
        let taskEvents = OCKTaskEvents(events: events)

        let expected = events
            .map { $0.id }
            .dropLast()
            .array()
        let observed = taskEvents.flatMap { $0.map(\.id) }
        XCTAssertEqual(observed, expected)
    }

    func testContains() {
        let doxylamineUUID = UUID()
        let nauseauUUID = UUID()
        let events: [OCKAnyEvent] = [
            OCKAnyEvent.mock(taskUUID: doxylamineUUID, occurrence: 0),
            OCKAnyEvent.mock(taskUUID: doxylamineUUID, occurrence: 1),
            OCKAnyEvent.mock(taskUUID: nauseauUUID, occurrence: 0)
        ]
        let taskEvents = OCKTaskEvents(events: events)

        XCTAssertTrue(taskEvents.contains(event: events[0]))
        XCTAssertTrue(taskEvents.contains(event: events[1]))
        XCTAssertTrue(taskEvents.contains(event: events[2]))
    }

    func testDoesNotContain() {
        let doxylamineUUID = UUID()
        let nauseauUUID = UUID()
        let events: [OCKAnyEvent] = [
            OCKAnyEvent.mock(taskUUID: doxylamineUUID, occurrence: 0),
            OCKAnyEvent.mock(taskUUID: doxylamineUUID, occurrence: 1),
            OCKAnyEvent.mock(taskUUID: nauseauUUID, occurrence: 0)
        ]
        let taskEvents = OCKTaskEvents()

        XCTAssertFalse(taskEvents.contains(event: events[0]))
        XCTAssertFalse(taskEvents.contains(event: events[1]))
        XCTAssertFalse(taskEvents.contains(event: events[2]))
    }

    func testAppendForEventsWithUniqueOccurrences() {
        let doxylamineUUID = UUID()
        let nauseauUUID = UUID()
        let events: [OCKAnyEvent] = [
            OCKAnyEvent.mock(taskUUID: doxylamineUUID, occurrence: 0),
            OCKAnyEvent.mock(taskUUID: doxylamineUUID, occurrence: 1),
            OCKAnyEvent.mock(taskUUID: nauseauUUID, occurrence: 0)
        ]
        var taskEvents = OCKTaskEvents()
        let results = events.map { taskEvents.append(event: $0) }

        // Test the underlying data
        let expected = events.map { $0.id }
        let observed = taskEvents.flatMap { $0.map(\.id) }
        XCTAssertEqual(observed, expected)

        // Test the data returned from the function call
        XCTAssertEqual(results.count, events.count)
        zip(results, events).forEach { result, expectedEvent in
            XCTAssertEqual(result.0?.id, expectedEvent.id)
            XCTAssertTrue(result.1)
        }
    }

    func testAppendForEventsWithDuplicateOccurrences() {
        let doxylamineUUID = UUID()
        let events: [OCKAnyEvent] = [
            OCKAnyEvent.mock(taskUUID: doxylamineUUID, occurrence: 0),
            OCKAnyEvent.mock(taskUUID: doxylamineUUID, occurrence: 0)
        ]
        var taskEvents = OCKTaskEvents()
        let results = events.map { taskEvents.append(event: $0) }

        // Test the underlying data
        let expected = events
            .map { $0.id }
            .dropLast()
            .array()
        let observed = taskEvents.flatMap { $0.map(\.id) }
        XCTAssertEqual(observed, expected)

        // Test the data returned from the function call
        XCTAssertEqual(results.count, events.count)
        if results.count == events.count {
            XCTAssertEqual(results[0].0?.id, events[0].id)
            XCTAssertTrue(results[0].1)

            XCTAssertEqual(results[1].0?.id, events[1].id)
            XCTAssertFalse(results[1].1)
        }
    }

    func testAppendForEventWithNoTaskIdentity() {
        let events: [OCKAnyEvent] = [OCKAnyEvent.mock(taskUUID: nil, occurrence: 0)]
        var taskEvents = OCKTaskEvents()
        let results = events.map { taskEvents.append(event: $0) }

        // Test the underlying data
        XCTAssertTrue(taskEvents.isEmpty)

        // Test the data returned from the function call
        XCTAssertEqual(results.count, 1)
        if let result = results.first {
            XCTAssertNil(result.0?.id)
            XCTAssertFalse(result.1)
        }
    }

    func testRemoveSucceeds() {
        let doxylamineUUID = UUID()
        let nauseauUUID = UUID()
        let events: [OCKAnyEvent] = [
            OCKAnyEvent.mock(taskUUID: doxylamineUUID, occurrence: 0),
            OCKAnyEvent.mock(taskUUID: doxylamineUUID, occurrence: 1),
            OCKAnyEvent.mock(taskUUID: nauseauUUID, occurrence: 0)
        ]
        var taskEvents = OCKTaskEvents(events: events)

        // Test the underlying data
        let removedEvents = events.map { taskEvents.remove(event: $0) }
        XCTAssertTrue(taskEvents.isEmpty)

        // Test the data returned from the function call
        XCTAssertEqual(removedEvents.count, events.count)
        if removedEvents.count == events.count {
            XCTAssertEqual(removedEvents[0]?.id, events[0].id)
            XCTAssertEqual(removedEvents[1]?.id, events[1].id)
            XCTAssertEqual(removedEvents[2]?.id, events[2].id)
        }
    }

    func testRemoveFails() {
        let doxylamineUUID = UUID()
        let events: [OCKAnyEvent] = [
            OCKAnyEvent.mock(taskUUID: doxylamineUUID, occurrence: 0),
            OCKAnyEvent.mock(taskUUID: doxylamineUUID, occurrence: 1)
        ]
        var taskEvents = OCKTaskEvents(events: [events[0]])

        // Test the underlying data
        let removedEvents = events.compactMap { taskEvents.remove(event: $0) }
        XCTAssertTrue(taskEvents.isEmpty)

        // Test the data returned from the function call
        XCTAssertEqual(removedEvents.count, 1)
        if removedEvents.count == 1 {
            XCTAssertEqual(removedEvents[0].id, events[0].id)
        }
    }

    func testUpdateSucceeds() {
        let doxylamineUUID = UUID()
        let oldEvent = OCKAnyEvent.mock(taskUUID: doxylamineUUID, occurrence: 0, hasOutcome: false)
        let newEvent = OCKAnyEvent.mock(taskUUID: doxylamineUUID, occurrence: 0, hasOutcome: true)
        var taskEvents = OCKTaskEvents(events: [oldEvent])

        let updatedEvent = taskEvents.update(event: newEvent)

        XCTAssertNotNil(taskEvents.first?.first?.outcome)
        XCTAssertNotNil(updatedEvent?.outcome)
    }

    func testUpdateFailsAndInsertsEvent() {
        let doxylamineUUID = UUID()
        let event = OCKAnyEvent.mock(taskUUID: doxylamineUUID, occurrence: 0, hasOutcome: true)
        var taskEvents = OCKTaskEvents()

        let updatedEvent = taskEvents.update(event: event)

        XCTAssertNotNil(taskEvents.first?.first?.outcome)
        XCTAssertNotNil(updatedEvent?.outcome)
    }

    func testUpdateFailsForEventWithNoTaskIdentity() {
        let doxylamineUUID = UUID()
        let event = OCKAnyEvent.mock(taskUUID: doxylamineUUID, occurrence: 0)
        let newEvent = OCKAnyEvent.mock(taskUUID: nil, occurrence: 0)
        var taskEvents = OCKTaskEvents(events: [event])
        let updatedEvent = taskEvents.update(event: newEvent)
        XCTAssertNil(updatedEvent)
    }

    func testEventsForTaskReturnsEvents() {
        let doxylamineUUID = UUID()
        let nauseauUUID = UUID()
        let events: [OCKAnyEvent] = [
            OCKAnyEvent.mock(taskUUID: doxylamineUUID, occurrence: 0),
            OCKAnyEvent.mock(taskUUID: doxylamineUUID, occurrence: 1),
            OCKAnyEvent.mock(taskUUID: nauseauUUID, occurrence: 0)
        ]
        let taskEvents = OCKTaskEvents(events: events)

        let result = taskEvents.events(forTask: events[0].task)
        XCTAssertEqual(result.count, 2)
        if result.count == 2 {
            XCTAssertEqual(result[0].id, events[0].id)
            XCTAssertEqual(result[1].id, events[1].id)
        }
    }

    func testEventsForTaskReturnNoEvents() {
        let doxylamineUUID = UUID()
        let nauseauUUID = UUID()
        let events: [OCKAnyEvent] = [
            OCKAnyEvent.mock(taskUUID: doxylamineUUID, occurrence: 0),
            OCKAnyEvent.mock(taskUUID: nauseauUUID, occurrence: 0)
        ]
        let taskEvents = OCKTaskEvents(events: [events[0]])

        let result = taskEvents.events(forTask: events[1].task)
        XCTAssertEqual(result.count, 0)
    }

    func testMatches() {
        let doxylamineUUID = UUID()
        let nauseauUUID = UUID()
        let events: [OCKAnyEvent] = [
            OCKAnyEvent.mock(taskUUID: doxylamineUUID, occurrence: 0),
            OCKAnyEvent.mock(taskUUID: nauseauUUID, occurrence: 0)
        ]
        let taskEvents1 = OCKTaskEvents(events: events)
        let taskEvents2 = OCKTaskEvents(events: events)
        XCTAssertEqual(taskEvents1.id, taskEvents2.id)
    }

    func testDoesNotMatch() {
        let doxylamineUUID = UUID()
        let nauseauUUID = UUID()
        let events: [OCKAnyEvent] = [
            OCKAnyEvent.mock(taskUUID: doxylamineUUID, occurrence: 0),
            OCKAnyEvent.mock(taskUUID: nauseauUUID, occurrence: 0)
        ]
        let taskEvents1 = OCKTaskEvents(events: events)
        let taskEvents2 = OCKTaskEvents(events: [events[0]])
        XCTAssertNotEqual(taskEvents1.id, taskEvents2.id)
    }

    // `OCKTaskEvents` relies on standard implementations for all `Collection` methods except that it uses a custom subsequence type.
    func testSubSequence() {
        let doxylamineUUID = UUID()
        let nauseauUUID = UUID()
        let events: [OCKAnyEvent] = [
            OCKAnyEvent.mock(taskUUID: doxylamineUUID, occurrence: 0),
            OCKAnyEvent.mock(taskUUID: nauseauUUID, occurrence: 0)
        ]
        let taskEvents = OCKTaskEvents(events: events)
        let slice = taskEvents.prefix(1)
        let event = slice.first?.first
        XCTAssertEqual(slice.count, 1)
        XCTAssertNotNil(event)
        event.map { XCTAssertEqual($0.id, events.first!.id) }
    }
}

private extension OCKAnyEvent {

    static func mock(taskUUID: UUID?, occurrence: Int, hasOutcome: Bool = false) -> Self {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let schedule = OCKSchedule.dailyAtTime(hour: 1, minutes: 0, start: startOfDay, end: nil, text: nil)
        var task = OCKTask(id: taskUUID?.uuidString ?? "", title: nil, carePlanUUID: nil, schedule: schedule)
        task.uuid = taskUUID

        let outcome = hasOutcome ?
            OCKOutcome(taskUUID: task.uuid!, taskOccurrenceIndex: occurrence, values: []) :
            nil

        let event = OCKAnyEvent(task: task, outcome: outcome, scheduleEvent: schedule.event(forOccurrenceIndex: occurrence)!)
        return event
    }
}

private extension ArraySlice {
    func array() -> [Element] {
        return Array(self)
    }
}

