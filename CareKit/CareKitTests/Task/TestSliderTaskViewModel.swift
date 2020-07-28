
@testable import CareKit
@testable import CareKitStore
import CareKitUI
import Combine
import Foundation
import SwiftUI
import XCTest

class TestSliderTaskViewModel: XCTestCase {

    var controller: OCKSliderTaskController!
    var cancellables: Set<AnyCancellable> = []
    @State var value: CGFloat = 3

    override func setUp() {
        super.setUp()
        let store = OCKStore(name: "carekit-store", type: .inMemory)
        controller = .init(storeManager: .init(wrapping: store))
    }

    func testViewModelCreation() {
        let taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: false, occurrences: 1)
        controller.taskEvents = taskEvents
        let updated = expectation(description: "updated view model")

        controller.$viewModel
            .compactMap { $0 }
            .sink { viewModel in
                XCTAssertEqual("Doxylamine", viewModel.title)
                XCTAssertEqual("Take the tablet with a glass of water.", viewModel.instructions)
                XCTAssertEqual("1", viewModel.detail)
                XCTAssertEqual(false, viewModel.isComplete)
                updated.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [updated], timeout: 1)
    }
/*
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
    }*/
}

