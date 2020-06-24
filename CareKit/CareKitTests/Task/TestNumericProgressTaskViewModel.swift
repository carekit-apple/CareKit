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
import CareKitUI
import Combine
import Foundation
import SwiftUI
import XCTest

class TestNumericProgressTaskViewModel: XCTestCase {

    var controller: OCKNumericProgressTaskController!
    var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        let store = OCKStore(name: "carekit-store", type: .inMemory)
        controller = .init(storeManager: .init(wrapping: store))
    }

    func testViewModelCreation() {
        let taskEvents = OCKTaskEvents.mock(outcomeValue: 0, targetValue: 0)
        controller.taskEvents = taskEvents
        let updated = expectation(description: "updated view model")

        controller.$viewModel
            .compactMap { $0 }
            .sink { viewModel in
                XCTAssertEqual("title", viewModel.title)
                XCTAssertEqual("instructions", viewModel.instructions)
                XCTAssertEqual("Anytime", viewModel.detail)
                XCTAssertEqual("0", viewModel.goal)
                XCTAssertEqual("0", viewModel.progress)
                updated.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [updated], timeout: 1)
    }

    func testViewModelMismatchingProgressAndGoalValueTypes() {
        let targetValue: Double = 100
        let progressValue: Int = 50
        let taskEvents = OCKTaskEvents.mock(outcomeValue: progressValue, targetValue: targetValue)
        controller.taskEvents = taskEvents
        let updated = expectation(description: "updated view model")

        controller.$viewModel
            .compactMap { $0 }
            .sink { viewModel in
                XCTAssertEqual("100", viewModel.goal)
                XCTAssertEqual("50", viewModel.progress)
                updated.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [updated], timeout: 1)
    }

    func testViewModelRemovesExtraneousDecimalForProgressAndGoalValues() {
        let targetValue: Double = 100.0
        let progressValue: Double = 50.0
        let taskEvents = OCKTaskEvents.mock(outcomeValue: progressValue, targetValue: targetValue)
        controller.taskEvents = taskEvents
        let updated = expectation(description: "updated view model")

        controller.$viewModel
            .compactMap { $0 }
            .sink { viewModel in
                XCTAssertEqual("100", viewModel.goal)
                XCTAssertEqual("50", viewModel.progress)
                updated.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [updated], timeout: 1)
    }

    func testViewModelRoundsDecimalForProgressAndGoalValues() {
        let targetValue: Double = 100.111_1
        let progressValue: Double = 50.111_1
        let taskEvents = OCKTaskEvents.mock(outcomeValue: progressValue, targetValue: targetValue)
        controller.taskEvents = taskEvents
        let updated = expectation(description: "updated view model")

        controller.$viewModel
            .compactMap { $0 }
            .sink { viewModel in
                let decimal = NSLocale.current.decimalSeparator ?? "."
                XCTAssertEqual("100\(decimal)11", viewModel.goal)
                XCTAssertEqual("50\(decimal)11", viewModel.progress)
                updated.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [updated], timeout: 1)
    }

    func testViewModelIsNotCompleteValue() {
        let taskEvents = OCKTaskEvents.mock(outcomeValue: 0, targetValue: 100)
        controller.taskEvents = taskEvents
        let updated = expectation(description: "updated view model")

        controller.$viewModel
            .compactMap { $0 }
            .sink { viewModel in
                XCTAssertFalse(viewModel.isComplete)
                updated.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [updated], timeout: 1)
    }

    func testConfigurationIsCompleteValue() {
        let taskEvents1 = OCKTaskEvents.mock(outcomeValue: 100, targetValue: 100)
        let taskEvents2 = OCKTaskEvents.mock(outcomeValue: 101, targetValue: 100)

        let updated = expectation(description: "updated view model")
        updated.expectedFulfillmentCount = 2

        controller.$viewModel
            .compactMap { $0 }
            .sink { viewModel in
                XCTAssertTrue(viewModel.isComplete)
                updated.fulfill()
            }
            .store(in: &cancellables)

        controller.taskEvents = taskEvents1
        controller.taskEvents = taskEvents2
        wait(for: [updated], timeout: 1)
    }
}

private extension OCKTaskEvents {

    static func mock(outcomeValue: OCKOutcomeValueUnderlyingType, targetValue: OCKOutcomeValueUnderlyingType) -> OCKTaskEvents {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let element = OCKScheduleElement(start: startOfDay, end: nil, interval: .init(day: 1), text: nil,
                                         targetValues: [.init(targetValue)], duration: .allDay)

        var task = OCKTask(id: "task", title: "title", carePlanUUID: nil, schedule: .init(composing: [element]))
        task.uuid = UUID()
        task.instructions = "instructions"

        let scheduleEvent = task.schedule.event(forOccurrenceIndex: 0)!
        let outcome = OCKOutcome(taskUUID: task.uuid!, taskOccurrenceIndex: 0, values: [.init(outcomeValue)])
        let event = OCKAnyEvent(task: task, outcome: outcome, scheduleEvent: scheduleEvent)
        var taskEvents = OCKTaskEvents()
        taskEvents.append(event: event)
        return taskEvents
    }
}
