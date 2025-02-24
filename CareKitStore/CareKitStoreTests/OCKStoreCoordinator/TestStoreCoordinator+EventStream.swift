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

import CareKitStore
import Foundation
import XCTest

class TestStoreCoordinatorEventStream: XCTestCase {

    private let storeA = OCKStore(
        name: "TestStoreCoordinatorEventStream.StoreA",
        type: .inMemory
    )

    private let storeB = OCKStore(
        name: "TestStoreCoordinatorEventStream.StoreB",
        type: .inMemory
    )

    private lazy var storeCoordinator: OCKStoreCoordinator = {

        let storeCoordinator = OCKStoreCoordinator()

        storeCoordinator.attach(store: storeA)
        storeCoordinator.attach(store: storeB)

        return storeCoordinator
    }()

    override func setUpWithError() throws {
        try super.setUpWithError()
        try storeCoordinator.reset()
    }

    func testInitialResult_TwoStores() async throws {

        let taskA = makeSampleTask(titleAndID: "taskA", dailyOnHour: 1)
        let taskB = makeSampleTask(titleAndID: "taskB", dailyOnHour: 1)

        _ = try await storeA.addAnyTask(taskA)
        _ = try await storeB.addAnyTask(taskB)

        let query = OCKEventQuery(for: Date())

        let matchingEvents = storeCoordinator.anyEvents(matching: query)

        let accumulatedEvents = try await accumulate(matchingEvents, expectedCount: 1)

        let observedEventCount = accumulatedEvents
            .flatMap { $0 }
            .count

        XCTAssertEqual(observedEventCount, 2)
    }

    func testInitialResult_OneStore() async throws {

        let taskA = makeSampleTask(titleAndID: "taskA", dailyOnHour: 1)

        _ = try await storeA.addAnyTask(taskA)

        let query = OCKEventQuery(for: Date())

        let matchingEvents = storeCoordinator.anyEvents(matching: query)

        let accumulatedEvents = try await accumulate(matchingEvents, expectedCount: 1)

        let observedEventCount = accumulatedEvents
            .flatMap { $0 }
            .count

        XCTAssertEqual(observedEventCount, 1)
    }

    func testResultIsSorted() async throws {

        let taskA = makeSampleTask(titleAndID: "taskA", dailyOnHour: 1)
        let taskB = makeSampleTask(titleAndID: "taskB", dailyOnHour: 2)
        let taskC = makeSampleTask(titleAndID: "taskC", dailyOnHour: 3)
        let taskD = makeSampleTask(titleAndID: "taskD", dailyOnHour: 4)

        _ = try await storeA.addAnyTasks([taskA, taskC])
        _ = try await storeB.addAnyTasks([taskB, taskD])

        let query = OCKEventQuery(for: Date())

        let matchingEvents = storeCoordinator.anyEvents(matching: query)

        let accumulatedEvents = try await accumulate(matchingEvents, expectedCount: 1)

        let expectedScheduleEvents = [
            [
                taskA.schedule[0],
                taskB.schedule[0],
                taskC.schedule[0],
                taskD.schedule[0]
            ]
        ]

        let observedScheduleEvents = accumulatedEvents.map { events in
            events.map(\.scheduleEvent)
        }

        XCTAssertEqual(expectedScheduleEvents, observedScheduleEvents)
    }

    func testResultIsUpdated() async throws {

        let taskA = makeSampleTask(titleAndID: "taskA", dailyOnHour: 1)
        let taskB = makeSampleTask(titleAndID: "taskB", dailyOnHour: 2)

        let storedTaskA = try await storeA.addAnyTask(taskA)
        let storedTaskB = try await storeB.addAnyTask(taskB)

        let query = OCKEventQuery(for: Date())

        let matchingEvents = storeCoordinator.anyEvents(matching: query)

        let accumulatedEvents = try await accumulate(matchingEvents, expectedCount: 3) { iter in

            if iter == 1 {
                _ = try await storeA.deleteAnyTask(storedTaskA)
            } else if iter == 2 {
                _ = try await storeB.deleteAnyTask(storedTaskB)
            }
        }

        let expectedScheduleEvents = [
            [taskA.schedule[0], taskB.schedule[0]],
            [taskB.schedule[0]],
            []
        ]

        let observedScheduleEvents = accumulatedEvents.map { events in
            events.map(\.scheduleEvent)
        }

        XCTAssertEqual(expectedScheduleEvents, observedScheduleEvents)
    }

    // MARK: - Utilities

    private func makeSampleTask(
        titleAndID: String,
        dailyOnHour hour: Int
    ) -> OCKTask {

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let schedule = OCKSchedule.dailyAtTime(hour: hour, minutes: 0, start: startOfDay, end: nil, text: nil)

        let task = OCKTask(
            id: titleAndID,
            title: titleAndID,
            carePlanUUID: nil,
            schedule: schedule
        )

        return task
    }
}
