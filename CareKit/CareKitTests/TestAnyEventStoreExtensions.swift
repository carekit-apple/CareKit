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

@testable import CareKit
@testable import CareKitStore

import Foundation
import XCTest

class TestAnyEventStoreExtensions: XCTestCase {

    private var store: MockStore!

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
}
