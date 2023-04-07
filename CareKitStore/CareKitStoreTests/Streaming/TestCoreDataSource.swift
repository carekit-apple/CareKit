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

import Combine
import Foundation
import XCTest
/*
@testable import CareKitStore

class TestCoreDataQueryPublisher: XCTestCase {

    private let store = OCKStore(
        name: "CoreDataExecutorTests.Store",
        type: .inMemory
    )

    override func setUpWithError() throws {
        try super.setUpWithError()
        try store.reset()
    }

    func testInitialResultIsForwardedAndSorted() throws {

        // Add tasks to the store

        let expectedTasks = [
            makeSampleTask(idAndTitle: "taskA"),
            makeSampleTask(idAndTitle: "taskB")
        ]

        try store.addTasksAndWait(expectedTasks)

        // Validate the initial published result

        let didReceiveResult = XCTestExpectation(description: "Received result")
        didReceiveResult.assertForOverFulfill = true

        let coreDataSource = CoreDataSource(
            OCKCDTask.self,
            predicate: NSPredicate(value: true),
            sortDescriptors: [NSSortDescriptor(keyPath: \OCKCDTask.title, ascending: true)],
            context: store.context
        )

        let cancellable = QueryPublisher(dataSource: coreDataSource)
            // Should never fail
            .catch { error -> Empty<[OCKCDTask], Never> in
                XCTFail(error.localizedDescription)
                return Empty()
            }
            .sink { observedTasks in

                let expectedTitles = expectedTasks.map(\.title)
                let observedTitles = observedTasks.map(\.title)
                XCTAssertEqual(expectedTitles, observedTitles)

                didReceiveResult.fulfill()
            }

        wait(for: [didReceiveResult], timeout: 2)
        cancellable.cancel()
    }

    func testResultIsForwardedWhenAddOccurs() throws {

        let expectedTasks = [
            makeSampleTask(idAndTitle: "taskA"),
            makeSampleTask(idAndTitle: "taskB")
        ]

        var didAddTasks = false

        let didReceiveResult = XCTestExpectation(description: "Result received")
        didReceiveResult.assertForOverFulfill = true
        didReceiveResult.expectedFulfillmentCount = 2

        let coreDataSource = CoreDataSource(
            OCKCDTask.self,
            predicate: NSPredicate(value: true),
            sortDescriptors: [NSSortDescriptor(keyPath: \OCKCDTask.title, ascending: true)],
            context: store.context
        )

        let cancellable = QueryPublisher(dataSource: coreDataSource)
            // Should never fail
            .catch { error -> Empty<[OCKCDTask], Never> in
                XCTFail(error.localizedDescription)
                return Empty()
            }
            .sink { observedTasks in

                // Add the tasks if they have not yet been added
                if !didAddTasks {

                    XCTAssertEqual(observedTasks.count, 0)

                    try! self.store.addTasksAndWait(expectedTasks)
                    didAddTasks = true

                // Validate the newly added tasks
                } else {

                    let expectedTitles = expectedTasks.map(\.title)
                    let observedTitles = observedTasks.map(\.title)
                    XCTAssertEqual(expectedTitles, observedTitles)
                }
                didReceiveResult.fulfill()
            }

        wait(for: [didReceiveResult], timeout: 2)
        cancellable.cancel()
    }

    func testResultIsForwardedWhenDeleteOccurs() throws {

        // Add tasks to the store

        let expectedTasks = [
            makeSampleTask(idAndTitle: "taskA"),
            makeSampleTask(idAndTitle: "taskB")
        ]

        try store.addTasksAndWait(expectedTasks)

        // Stream tasks from the store

        var didDeleteTasks = false

        let didReceiveResult = XCTestExpectation(description: "Result received")
        didReceiveResult.assertForOverFulfill = true
        didReceiveResult.expectedFulfillmentCount = 2

        let coreDataSource = CoreDataSource(
            OCKCDTask.self,
            predicate: NSPredicate(value: true),
            sortDescriptors: [NSSortDescriptor(keyPath: \OCKCDTask.title, ascending: true)],
            context: store.context
        )

        let cancellable = QueryPublisher(dataSource: coreDataSource)
            // Should never fail
            .catch { error -> Empty<[OCKCDTask], Never> in
                XCTFail(error.localizedDescription)
                return Empty()
            }
            .sink { observedTasks in

                // Add the tasks if they have not yet been added
                if !didDeleteTasks {

                    XCTAssertEqual(observedTasks.count, expectedTasks.count)

                    try! self.store.reset()
                    didDeleteTasks = true

                // Validate the newly deleted tasks
                } else {

                    XCTAssertEqual(observedTasks.count, 0)
                }
                didReceiveResult.fulfill()
            }

        wait(for: [didReceiveResult], timeout: 2)
        cancellable.cancel()
    }

    func testResultIsForwardedWhenUpdateOccurs() throws {

        // Add tasks to the store

        let originalTasks = [
            makeSampleTask(idAndTitle: "taskA"),
            makeSampleTask(idAndTitle: "taskB")
        ]

        let updatedTitles = ["taskC", "taskD"]

        try store.addTasksAndWait(originalTasks)

        // Stream tasks from the store

        var didUpdateTasks = false

        let didReceiveResult = XCTestExpectation(description: "Result received")
        didReceiveResult.assertForOverFulfill = true
        didReceiveResult.expectedFulfillmentCount = 2

        let coreDataSource = CoreDataSource(
            OCKCDTask.self,
            predicate: NSPredicate(value: true),
            sortDescriptors: [NSSortDescriptor(keyPath: \OCKCDTask.title, ascending: true)],
            context: store.context
        )

        let cancellable = QueryPublisher(dataSource: coreDataSource)
            // Should never fail
            .catch { error -> Empty<[OCKCDTask], Never> in
                XCTFail(error.localizedDescription)
                return Empty()
            }
            .sink { observedTasks in

                // Update the tasks in the store
                if !didUpdateTasks {

                    XCTAssertEqual(observedTasks.count, originalTasks.count)

                    let updatedTasks = observedTasks
                        .map { $0.makeTask() }
                        .enumerated()
                        .map { index, task -> OCKTask in
                            var updatedTask = task
                            updatedTask.title = updatedTitles[index]
                            updatedTask.effectiveDate = Date()
                            return updatedTask
                        }

                    try! self.store.updateTasksAndWait(updatedTasks)

                    didUpdateTasks = true

                // Validate the newly updated tasks
                } else {

                    let expectedTitles =
                        originalTasks.map(\.title) +
                        updatedTitles

                    let observedTitles = observedTasks.map(\.title)

                    XCTAssertEqual(expectedTitles, observedTitles)
                }

                didReceiveResult.fulfill()
            }

        wait(for: [didReceiveResult], timeout: 2)
        cancellable.cancel()
    }

    func testIrrelevantChangeDoesNotTriggerResult() throws {

        // Add tasks to the store

        let tasks = [
            makeSampleTask(idAndTitle: "taskA"),
            makeSampleTask(idAndTitle: "taskB")
        ]

        try store.addTasksAndWait(tasks)

        // Stream tasks from the store

        let didReceiveResult = XCTestExpectation(description: "Result received")
        didReceiveResult.assertForOverFulfill = true

        let coreDataSource = CoreDataSource(
            OCKCDTask.self,
            predicate: NSPredicate(value: false),
            sortDescriptors: [],
            context: store.context
        )

        let cancellable = QueryPublisher(dataSource: coreDataSource)
            // Should never fail
            .catch { error -> Empty<[OCKCDTask], Never> in
                XCTFail(error.localizedDescription)
                return Empty()
            }
            .sink { _ in

                try! self.store.reset()

                didReceiveResult.fulfill()
            }

        wait(for: [didReceiveResult], timeout: 2)
        cancellable.cancel()
    }

    func testCancelledStreamDoesNotTriggerResult() throws {

        // Add tasks to the store

        let tasks = [
            makeSampleTask(idAndTitle: "taskA"),
            makeSampleTask(idAndTitle: "taskB")
        ]

        try store.addTasksAndWait(tasks)

        // Stream tasks from the store

        let didReceiveResult = XCTestExpectation(description: "Result received")
        didReceiveResult.assertForOverFulfill = true

        let coreDataSource = CoreDataSource(
            OCKCDTask.self,
            predicate: NSPredicate(value: true),
            sortDescriptors: [],
            context: store.context
        )

        let cancellable = QueryPublisher(dataSource: coreDataSource)
            // Should never fail
            .catch { error -> Empty<[OCKCDTask], Never> in
                XCTFail(error.localizedDescription)
                return Empty()
            }
            .sink { _ in
                didReceiveResult.fulfill()
            }

        wait(for: [didReceiveResult], timeout: 2)
        cancellable.cancel()

        // Trigger a change to the observed tasks. SInk block
        // should not get called.
        try store.reset()
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
*/
