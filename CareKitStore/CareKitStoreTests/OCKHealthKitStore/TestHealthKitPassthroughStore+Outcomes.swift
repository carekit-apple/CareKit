/*
 Copyright (c) 2023, Apple Inc. All rights reserved.
 
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

import HealthKit
import XCTest

@available(iOS 15, watchOS 8, macOS 13.0, *)
class TestHealthKitPassthroughStoreOutcomes: XCTestCase {

    private let cdStore = OCKStore(
        name: "TestEvents.Store",
        type: .inMemory
    )

    private lazy var passthroughStore = OCKHealthKitPassthroughStore(store: cdStore)

    override func setUpWithError() throws {
        try super.setUpWithError()
        try passthroughStore.reset()
    }

    func testAbilityToDeleteOutcomes_FailsWhenNoValuesAreFromHealthKit() async throws {

        let stepsTask = makeStepsTask()

        _ = try await passthroughStore.addTask(stepsTask)

        let healthKitOutcome = OCKHealthKitOutcome(
            taskUUID: stepsTask.uuid,
            taskOccurrenceIndex: 0,
            values: [OCKOutcomeValue(1)],
            isOwnedByApp: true,
            healthKitUUIDs: [[UUID()]]
        )

        let nonHealthKitOutcome = OCKHealthKitOutcome(
            taskUUID: stepsTask.uuid,
            taskOccurrenceIndex: 0,
            values: [OCKOutcomeValue(1)],
            isOwnedByApp: true,
            healthKitUUIDs: []
        )

        let outcomes = [healthKitOutcome, nonHealthKitOutcome]

        XCTAssertThrowsError(
            try passthroughStore.checkAbilityToDelete(outcomes: outcomes)
        ) { error in

            let expectedMessage = "Not all outcomes have been retrieved from HealthKit."
            let doesContainMessage = error.localizedDescription.contains(expectedMessage)
            XCTAssertTrue(doesContainMessage)
        }
    }

    func testAbilityToDeleteOutcomes_FailsWhenSomeValuesAreNotFromHealthKit() async throws {

        let stepsTask = makeStepsTask()

        _ = try await passthroughStore.addTask(stepsTask)

        let healthKitOutcome = OCKHealthKitOutcome(
            taskUUID: stepsTask.uuid,
            taskOccurrenceIndex: 0,
            values: [OCKOutcomeValue(1)],
            isOwnedByApp: true,
            healthKitUUIDs: [[UUID()]]
        )

        let nonHealthKitOutcome = OCKHealthKitOutcome(
            taskUUID: stepsTask.uuid,
            taskOccurrenceIndex: 0,
            values: [OCKOutcomeValue(1), OCKOutcomeValue(1)],
            isOwnedByApp: true,
            healthKitUUIDs: [[UUID()]]
        )

        let outcomes = [healthKitOutcome, nonHealthKitOutcome]

        XCTAssertThrowsError(
            try passthroughStore.checkAbilityToDelete(outcomes: outcomes)
        ) { error in

            let expectedMessage = "Not all outcomes have been retrieved from HealthKit."
            let doesContainMessage = error.localizedDescription.contains(expectedMessage)
            XCTAssertTrue(doesContainMessage)
        }
    }

    func testAbilityToDeleteOutcomes_SucceedsWhenValuesAreFromHealthKit() async throws {

        let stepsTask = makeStepsTask()

        _ = try await passthroughStore.addTask(stepsTask)

        let healthKitOutcomeA = OCKHealthKitOutcome(
            taskUUID: stepsTask.uuid,
            taskOccurrenceIndex: 0,
            values: [OCKOutcomeValue(1)],
            isOwnedByApp: true,
            healthKitUUIDs: [[UUID()]]
        )

        let healthKitOutcomeB = OCKHealthKitOutcome(
            taskUUID: stepsTask.uuid,
            taskOccurrenceIndex: 0,
            values: [OCKOutcomeValue(1), OCKOutcomeValue(1)],
            isOwnedByApp: true,
            healthKitUUIDs: [[UUID()], [UUID()]]
        )

        let outcomes = [healthKitOutcomeA, healthKitOutcomeB]

        try passthroughStore.checkAbilityToDelete(outcomes: outcomes)
    }

    func testTaskQueryDefaultsToCurrentDayDateInterval() async throws {
        let outcomeTaskQuery = OCKOutcomeQuery()
        let taskQuery = passthroughStore.makeTaskQuery(from: outcomeTaskQuery)
        let currentDayDateInterval = Calendar.current.dateInterval(of: .day, for: Date())!

        XCTAssertEqual(
            taskQuery.dateInterval?.start,
            currentDayDateInterval.start
        )
        XCTAssertEqual(
            taskQuery.dateInterval?.end,
            currentDayDateInterval.end
        )
        XCTAssertEqual(taskQuery.ids, outcomeTaskQuery.taskIDs)
        XCTAssertEqual(taskQuery.remoteIDs, outcomeTaskQuery.taskRemoteIDs)
        XCTAssertEqual(taskQuery.uuids, outcomeTaskQuery.taskUUIDs)
        XCTAssertTrue(taskQuery.sortDescriptors.isEmpty)
    }

    func testTaskQueryPropertiesAdoptsOutcomeQueryProperties() async throws {
        let yesterday = Calendar.current.date(
            byAdding: .day,
            value: -1,
            to: Date()
        )!
        let yesterdayDateInterval = Calendar.current.dateInterval(
            of: .day,
            for: yesterday
        )!
        var outcomeTaskQuery = OCKOutcomeQuery(
            dateInterval: yesterdayDateInterval
        )
        outcomeTaskQuery.taskIDs = ["id"]
        outcomeTaskQuery.taskRemoteIDs = ["remoteID"]
        outcomeTaskQuery.taskUUIDs = [UUID()]
        outcomeTaskQuery.sortDescriptors = [
            .effectiveDate(ascending: true),
            .groupIdentifier(ascending: true)
        ]
        let taskQuery = passthroughStore.makeTaskQuery(from: outcomeTaskQuery)
        let expectedTaskSortDescriptors: [OCKTaskQuery.SortDescriptor] = [
            .effectiveDate(ascending: true),
            .groupIdentifier(ascending: true)
        ]

        XCTAssertEqual(taskQuery.dateInterval, outcomeTaskQuery.dateInterval)
        XCTAssertEqual(taskQuery.ids, outcomeTaskQuery.taskIDs)
        XCTAssertEqual(taskQuery.remoteIDs, outcomeTaskQuery.taskRemoteIDs)
        XCTAssertEqual(taskQuery.uuids, outcomeTaskQuery.taskUUIDs)
        XCTAssertEqual(taskQuery.sortDescriptors, expectedTaskSortDescriptors)
    }

    // MARK: - Utilities

    private func makeStepsTask() -> OCKHealthKitTask {

        let stepsLinkage = OCKHealthKitLinkage(
            quantityIdentifier: .stepCount,
            quantityType: .cumulative,
            unit: .count()
        )

        let stepsTask = OCKHealthKitTask(
            id: "steps",
            title: nil,
            carePlanUUID: nil,
            schedule: .dailyAtTime(hour: 8, minutes: 0, start: Date(), end: nil, text: nil),
            healthKitLinkage: stepsLinkage
        )

        return stepsTask
    }
}
