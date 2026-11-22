/*
 Copyright (c) 2016-2025, Apple Inc. All rights reserved.
 Copyright (c) 2026, Snehal Mehta.

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
import Synchronization
import XCTest

class TestAnyEventStoreExtensions: XCTestCase {

    private var store: MockStore!

    private var queuesToTest: [DispatchQueue] = [
        DispatchQueue.main,
        DispatchQueue(label: "WorkQueue")
    ]

    override func setUp() {
        super.setUp()
        store = MockStore(name: UUID().uuidString)
    }

    func testToggleBooleanOutcome_OutcomeIsCreated() async throws {
        let task = OCKTask.sample(uuid: UUID(), id: "taskA")
        let storedTask = try await store.store.addTask(task)
        let storedEvent = try await store.fetchEvent(forTask: storedTask, occurrence: 0)
        let outcome = try await store.toggleBooleanOutcome(for: storedEvent.anyEvent)
        XCTAssertEqual(outcome.values.count, 1)
        XCTAssertEqual(outcome.values.first?.booleanValue, true)
    }

    func testToggleBooleanOutcome_OutcomeIsDeleted() async throws {
        let task = OCKTask.sample(uuid: UUID(), id: "taskA")
        let storedTask = try await store.store.addTask(task)
        let storedEvent = try await store.fetchEvent(forTask: storedTask, occurrence: 0)
        let addedOutcome = try await store.toggleBooleanOutcome(for: storedEvent.anyEvent)
        let deletedOutcome = try await store.toggleBooleanOutcome(for: storedEvent.anyEvent)
        XCTAssertEqual(deletedOutcome.values.count, 1)
        XCTAssertEqual(deletedOutcome.values.first?.booleanValue, true)
        XCTAssertEqual(addedOutcome.id, deletedOutcome.id)
    }

    func testToggleBooleanOutcome_Fails() async throws {
        let task = OCKTask.sample(uuid: UUID(), id: "taskA")
        let storedTask = try await store.store.addTask(task)
        let storedEvent = try await store.fetchEvent(forTask: storedTask, occurrence: 0)
        store.errorOverride = OCKStoreError.fetchFailed(reason: "Error override")
        let addedOutcome = try? await store.toggleBooleanOutcome(for: storedEvent.anyEvent)
        XCTAssertNil(addedOutcome)
    }

    // CareKit supplies a stream of events, streaming data whenever the events
    // are changed. The implementation uses an `NSFetchedResultsController`.
    // In the past, due to some internal implementation details for the controller,
    // fetching outcomes crashes due to malformed NSPredicate logic. The crash
    // doesn't happen when fetching outcomes directly, so the best place to test
    // for the issue is here in an integration test, simulating a user tapping
    // a button many times.
    func testToggleBooleanOutcomeForPublishedEvent() async throws {

        let task = OCKTask.sample(uuid: UUID(), id: "taskA")
        _ = try await store.addTask(task)

        let didUpdate = XCTestExpectation(description: "Did Update")
        didUpdate.expectedFulfillmentCount = 10

        let eventsOccurringToday = OCKEventQuery(for: Date())

        let events = store
            .events(matching: eventsOccurringToday)
            .prefix(10)

        for try await events in events {

            // Ensure we are always working with the same occurrence of
            // the task (IE the same event)

            guard let event = events.first else {
                XCTFail("No events found")
                return
            }

            XCTAssertEqual(event.scheduleEvent.occurrence, 0)

            // Toggle the event completion again and again...Toggling the event
            // won't always succeed due to a data race. It is possible that two
            // calls to `toggleBooleanOutcome(for:)` could pile up before the first
            // is executed. If both lead to adding an outcome, we may attempt to
            // add a duplicate outcome to the store. The store protects against
            // that case by ensuring an outcome is unique before adding it to the
            // store. If an outcome isn't unique, the store throws an error.

            _ = try await store.toggleBooleanOutcome(for: event.anyEvent)

            didUpdate.fulfill()
        }

        /*
         TODO: Remove in the future when macOS 13 image release for GitHub actions.
         GitHub actions currently only supports macOS 12 and Xcode 14.2.
         */
        #if compiler(>=5.8.0)
        await fulfillment(of: [didUpdate], timeout: 2)
        #else
        wait(for: [didUpdate], timeout: 2)
        #endif
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

    func testFetchAdherenceSucceedsWithEmptyResult() {

        for queue in queuesToTest {

            let completionFired = XCTestExpectation(description: "completion fired")

            let query = OCKAdherenceQuery(
                taskIDs: [],
                dateInterval: DateInterval()
            )

            store.fetchAdherence(
                query: query,
                callbackQueue: queue
            ) { result in

                dispatchPrecondition(condition: .onQueue(queue))

                switch result {
                case let .success(adherence):
                    XCTAssertEqual(adherence, [])
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                }

                completionFired.fulfill()
            }

            wait(for: [completionFired], timeout: 2)
        }
    }

    func testFetchAdherenceReturnsOneValuePerDayWhenTheIntervalEndsAtMidnight() async throws {
        let start = Calendar.current.date(byAdding: .day, value: -3, to: Calendar.current.startOfDay(for: Date()))!
        let threeDaysLater = Calendar.current.date(byAdding: .day, value: 3, to: start)!
        let schedule = OCKSchedule.dailyAtTime(hour: 9, minutes: 0, start: start, end: nil, text: nil)
        let task = try await store.addTask(OCKTask(id: "pill", title: "Pill", carePlanUUID: nil, schedule: schedule))

        let query = OCKAdherenceQuery(taskIDs: [task.id], dateInterval: DateInterval(start: start, end: threeDaysLater))
        let adherence = try await store.fetchAdherence(query: query)

        XCTAssertEqual(adherence, [.progress(0), .progress(0), .progress(0)])
    }

    func testFetchAdherencePlacesEventsOnTheirDayWhenTheIntervalStartsAtNoon() async throws {
        let calendar = Calendar.current
        let day1 = calendar.date(byAdding: .day, value: -5, to: calendar.startOfDay(for: Date()))!
        let schedule = OCKSchedule.dailyAtTime(hour: 9, minutes: 0, start: day1, end: nil, text: nil)
        let task = try await store.addTask(OCKTask(id: "pill", title: "Pill", carePlanUUID: nil, schedule: schedule))
        try await store.addOutcome(OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: 1, values: [OCKOutcomeValue(true)]))

        let noonOnDay1 = calendar.date(byAdding: .hour, value: 12, to: day1)!
        let threeDaysLater = calendar.date(byAdding: .day, value: 3, to: noonOnDay1)!
        let query = OCKAdherenceQuery(taskIDs: [task.id], dateInterval: DateInterval(start: noonOnDay1, end: threeDaysLater))
        let adherence = try await store.fetchAdherence(query: query)

        // Day 1's 9:00 event is before the interval, and the completed event is on day 2.
        XCTAssertEqual(adherence, [.noEvents, .progress(1), .progress(0)])
    }

    func testFetchAdherenceHandlesEventsThatStartedBeforeTheInterval() async throws {
        let calendar = Calendar.current
        let day0 = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: Date()))!
        let element = OCKScheduleElement(
            start: calendar.date(byAdding: .hour, value: 9, to: day0)!,
            end: nil,
            interval: DateComponents(day: 3),
            duration: .hours(48)
        )
        let task = try await store.addTask(
            OCKTask(id: "longTask", title: "Long task", carePlanUUID: nil, schedule: OCKSchedule(composing: [element]))
        )

        // The first event started more than a day before the interval and is still in progress.
        let start = calendar.date(byAdding: .day, value: 2, to: day0)!
        let end = calendar.date(byAdding: .day, value: 3, to: start)!
        let query = OCKAdherenceQuery(taskIDs: [task.id], dateInterval: DateInterval(start: start, end: end))
        let adherence = try await store.fetchAdherence(query: query)

        XCTAssertEqual(adherence, [.noEvents, .progress(0), .noEvents])
    }
}
