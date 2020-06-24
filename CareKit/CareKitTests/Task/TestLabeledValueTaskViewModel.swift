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

class TestLabeledValueTaskViewModel: XCTestCase {

    var controller: OCKLabeledValueTaskController!
    var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        let store = OCKStore(name: "carekit-store", type: .inMemory)
        controller = .init(storeManager: .init(wrapping: store))
    }

    func testViewModelCreation() {
        let taskEvents = OCKTaskEvents.mock(underlyingValue: nil, units: nil)
        controller.taskEvents = taskEvents
        let updated = expectation(description: "updated view model")

        controller.$viewModel
            .compactMap { $0 }
            .sink { viewModel in
                XCTAssertEqual("title", viewModel.title)
                XCTAssertEqual("Anytime", viewModel.detail)
                updated.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [updated], timeout: 1)
    }

    func testIsComplete() {
        let taskEvents = OCKTaskEvents.mock(underlyingValue: 5, units: "BPM")
        controller.taskEvents = taskEvents
        let updated = expectation(description: "updated view model")

        controller.$viewModel
            .compactMap { $0 }
            .sink { viewModel in
                switch viewModel.state {
                case let .complete(value, label):
                    XCTAssertEqual(value, "5")
                    XCTAssertEqual(label, "BPM")
                case .incomplete:
                    XCTFail("State should be `complete`")
                }
                updated.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [updated], timeout: 1)
    }

    func testIsIncomplete() {
        let taskEvents = OCKTaskEvents.mock(underlyingValue: nil, units: nil)
        controller.taskEvents = taskEvents
        let updated = expectation(description: "updated view model")

        controller.$viewModel
            .compactMap { $0 }
            .sink { viewModel in
                switch viewModel.state {
                case .complete:
                    XCTFail("State should be `incomplete`")
                case .incomplete(let label):
                    XCTAssertEqual(label, loc("NO_DATA").uppercased())
                }
                updated.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [updated], timeout: 1)
    }
}

private extension OCKTaskEvents {

    static func mock(underlyingValue: OCKOutcomeValueUnderlyingType?, units: String?) -> OCKTaskEvents {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let element = OCKScheduleElement(start: startOfDay, end: nil, interval: .init(day: 1), text: nil, targetValues: [], duration: .allDay)

        var task = OCKTask(id: "task", title: "title", carePlanUUID: nil, schedule: .init(composing: [element]))
        task.uuid = UUID()
        task.instructions = "instructions"

        let outcome = underlyingValue.map { underlyingValue -> OCKOutcome in
            var outcomeValue = OCKOutcomeValue(underlyingValue)
            outcomeValue.units = units
            return OCKOutcome(taskUUID: task.uuid!, taskOccurrenceIndex: 0, values: [outcomeValue])
        }

        let scheduleEvent = task.schedule.event(forOccurrenceIndex: 0)!
        let event = OCKAnyEvent(task: task, outcome: outcome, scheduleEvent: scheduleEvent)
        var taskEvents = OCKTaskEvents()
        taskEvents.append(event: event)
        return taskEvents
    }
}
