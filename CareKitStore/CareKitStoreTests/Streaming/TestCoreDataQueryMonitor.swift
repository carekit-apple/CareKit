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

import AsyncAlgorithms
import Foundation
import XCTest

@testable import CareKitStore

class TestCoreDataQueryMonitor: XCTestCase {

    private let store = OCKStore(
        name: "TestCoreDataQueryMonitor.Store",
        type: .inMemory
    )

    override func setUpWithError() throws {
        try super.setUpWithError()
        try store.reset()
    }

    func testInitialResultIsProducedAndSorted() async throws {

        // Add tasks to the store

        let sampleTasks = [
            makeSampleTask(idAndTitle: "taskA"),
            makeSampleTask(idAndTitle: "taskB")
        ]

        let storedTasks = try await store.addTasks(sampleTasks)

        let expectedTitles = [
            storedTasks.map(\.title)
        ]

        // Validate the initial result

        let tasks = AsyncStreamFactory.coreDataResults(
            OCKCDTask.self,
            predicate: NSPredicate(value: true),
            sortDescriptors: [NSSortDescriptor(keyPath: \OCKCDTask.title, ascending: true)],
            context: store.context
        )
        .map { $0 as! [OCKTask] }

        let accumulatedTasks = try await accumulate(tasks, expectedCount: 1)

        let observedTitles = accumulatedTasks.map {
            $0.map(\.title)
        }

        XCTAssertEqual(expectedTitles, observedTitles)
    }

    func testResultIsProducedWhenAddOccurs() async throws {

        let sampleTasks = [
            makeSampleTask(idAndTitle: "taskA"),
            makeSampleTask(idAndTitle: "taskB")
        ]

        let expectedTitles = [
            [],
            sampleTasks.map(\.title)
        ]

        let tasks = AsyncStreamFactory.coreDataResults(
            OCKCDTask.self,
            predicate: NSPredicate(value: true),
            sortDescriptors: [NSSortDescriptor(keyPath: \OCKCDTask.title, ascending: true)],
            context: store.context
        )
        .map { $0 as! [OCKTask] }

        let accumulatedTasks = try await accumulate(tasks, expectedCount: 2) { iter in

            guard iter == 1 else { return }
            try await store.addTasks(sampleTasks)
        }

        let observedTitles = accumulatedTasks.map {
            $0.map(\.title)
        }

        XCTAssertEqual(expectedTitles, observedTitles)
    }

    func testResultProducedWhenDeleteOccurs() async throws {

        // Add tasks to the store

        let sampleTasks = [
            makeSampleTask(idAndTitle: "taskA"),
            makeSampleTask(idAndTitle: "taskB")
        ]

        let expectedTitles = [
            sampleTasks.map(\.title),
            []
        ]

        _ = try await store.addTasks(sampleTasks)

        // Stream tasks from the store

        let tasks = AsyncStreamFactory.coreDataResults(
            OCKCDTask.self,
            predicate: NSPredicate(value: true),
            sortDescriptors: [NSSortDescriptor(keyPath: \OCKCDTask.title, ascending: true)],
            context: store.context
        )
        .map { $0 as! [OCKTask] }

        let accumulatedTasks = try await accumulate(tasks, expectedCount: 2) { iter in

            guard iter == 1 else { return }
            try self.store.reset()
        }

        let observedTitles = accumulatedTasks.map {
            $0.map(\.title)
        }

        XCTAssertEqual(expectedTitles, observedTitles)
    }

    func testResultIsProducedWhenUpdateOccurs() async throws {

        // Add tasks to the store

        let sampleTasks = [
            makeSampleTask(idAndTitle: "taskA"),
            makeSampleTask(idAndTitle: "taskB")
        ]

        let originalTitles = sampleTasks.map(\.title)
        let updatedTitles = ["taskC", "taskD"]

        let expectedTitles = [
            originalTitles,
            originalTitles + updatedTitles
        ]

        let storedTasks = try await store.addTasks(sampleTasks)

        let updatedTasks = storedTasks
            .enumerated()
            .map { index, task -> OCKTask in
                var updatedTask = task
                updatedTask.title = updatedTitles[index]
                updatedTask.effectiveDate = Date()
                return updatedTask
            }

        // Stream tasks from the store

        let tasks = AsyncStreamFactory.coreDataResults(
            OCKCDTask.self,
            predicate: NSPredicate(value: true),
            sortDescriptors: [NSSortDescriptor(keyPath: \OCKCDTask.title, ascending: true)],
            context: store.context
        )
        .map { $0 as! [OCKTask] }

        let accumulatedTasks = try await accumulate(tasks, expectedCount: 2) { iter in

            guard iter == 1 else { return }
            try await self.store.updateTasks(updatedTasks)
        }

        let observedTitles = accumulatedTasks.map {
            $0.map(\.title)
        }

        XCTAssertEqual(expectedTitles, observedTitles)
    }

    /*
     TODO: Remove in the future when macOS 13 image release for GitHub actions.
     GitHub actions currently only supports macOS 12 and Xcode 14.2.
     */
    #if compiler(>=5.8.0)
    func testIrrelevantChangeDoesNotProduceResult() async throws {

        // Add tasks to the store

        let irrelevantTasks = [
            makeSampleTask(idAndTitle: "taskA"),
            makeSampleTask(idAndTitle: "taskB")
        ]

        let relevantTasks = [
            makeSampleTask(idAndTitle: "taskC")
        ]

        let storedIrrelevantTasks = try await store.addTasks(irrelevantTasks)
        try await store.addTasks(relevantTasks)

        let predicate = NSPredicate(
            format: "%K == %@",
            #keyPath(OCKCDTask.id),
            "taskC"
        )

        let didProduceResult = expectation(description: "Produced result")
        didProduceResult.expectedFulfillmentCount = 1
        didProduceResult.assertForOverFulfill = true

        let didDeleteTasks = expectation(description: "Tasks deleted")

        let monitor = CoreDataQueryMonitor(
            OCKCDTask.self,
            predicate: predicate,
            sortDescriptors: [],
            context: store.context,
            resultHandler: { [store] result in
                store.deleteTasks(storedIrrelevantTasks) { result in
                    let didSucceed = (try? result.get()) != nil
                    XCTAssertTrue(didSucceed)
                    didDeleteTasks.fulfill()
                }

                didProduceResult.fulfill()
            }
        )

        monitor.startQuery()

        await fulfillment(of: [didProduceResult, didDeleteTasks], timeout: 2)

        monitor.stopQuery()
    }
    #endif
    
    func testCancelledStreamDoesNotProduceResult() async throws {

        // Add tasks to the store

        let careTasks = [
            makeSampleTask(idAndTitle: "taskA"),
            makeSampleTask(idAndTitle: "taskB")
        ]

        try await store.addTasks(careTasks)

        let predicate = NSPredicate(value: true)

        let didProduceResult = expectation(description: "Produced result")
        didProduceResult.expectedFulfillmentCount = 1
        didProduceResult.assertForOverFulfill = true

        var monitor: CoreDataQueryMonitor<OCKCDTask>!

        monitor = CoreDataQueryMonitor(
            OCKCDTask.self,
            predicate: predicate,
            sortDescriptors: [],
            context: store.context
        )

        monitor.resultHandler = { [weak monitor, store] _ in

            didProduceResult.fulfill()
            monitor?.stopQuery()

            // Resetting the store should not trigger the `resultHandler`
            // because the query has been stopped
            do {
                try store.reset()
            } catch {
                XCTFail(error.localizedDescription)
            }
        }

        monitor.startQuery()

        await fulfillment(of: [didProduceResult], timeout: 2)
    }

    // MARK: Utilities

    private func makeSampleTask(idAndTitle: String) -> OCKTask {

        let startOfDay = Calendar.current.startOfDay(for: Date())

        let schedule = OCKSchedule
            .dailyAtTime(hour: 7, minutes: 0, start: startOfDay, end: nil, text: nil)

        let task = OCKTask(
            id: idAndTitle,
            title: idAndTitle,
            carePlanUUID: nil,
            schedule: schedule
        )

        return task
    }
}
