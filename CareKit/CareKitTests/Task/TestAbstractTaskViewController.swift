/*
 Copyright (c) 2019, Apple Inc. All rights reserved.

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
import UIKit
import XCTest

private class MockTaskView: UIView, OCKTaskDisplayable {
    weak var delegate: OCKTaskViewDelegate?
    var buttons = [OCKButton] () {
        didSet { updateButtonTargets() }
    }

    func updateButtonTargets() {
        for button in buttons {
            guard button.allTargets.isEmpty else { continue }
            button.addTarget(self, action: #selector(toggleEvent(_:)), for: .touchUpInside)
        }
    }

    @objc
    func toggleEvent(_ sender: OCKButton) {
        guard let index = buttons.firstIndex(of: sender) else { fatalError("Target not set up properly") }
        delegate?.taskView(self, didCompleteEvent: sender.isSelected, at: index, sender: sender)
    }
}

private class MockTaskViewController: OCKTaskViewController<MockTaskView, OCKStore> {
    override func makeView() -> MockTaskView {
        return .init()
    }

    override func updateView(_ view: MockTaskView, context: OCKSynchronizationContext<[OCKStore.Event]>) {
        view.buttons = context.viewModel?.map {
            let button = OCKButton()
            button.isSelected = $0.outcome != nil
            return button
        } ?? []
    }
}

class TestAbstractTaskViewController: XCTestCase {
    enum Constants {
        static let timeout: TimeInterval = 3
    }

    var storeManager: OCKSynchronizedStoreManager<OCKStore>!
    private var synchronizationDelegate: MockSynchronizationDelegate<[OCKStore.Event]>!
    private var taskDelegate: MockTaskViewControllerDelegate!
    var task: OCKTask!

    override func setUp() {
        super.setUp()
        UIView.setAnimationsEnabled(false)
        storeManager = OCKSynchronizedStoreManager(wrapping: OCKStore(name: "ckstore", type: .inMemory))

        // add new task
        let task = OCKTask(identifier: "doxylamine", title: "Doxylamine", carePlanID: nil,
                           schedule: .mealTimesEachDay(start: Calendar.current.startOfDay(for: Date()), end: nil))
        self.task = try? storeManager.store.addTaskAndWait(task)
        XCTAssertNotNil(self.task)
    }

    private func updateSchedule() throws {
        var task: OCKTask! = self.task
        let startDate = Calendar.current.startOfDay(for: Date())
        let dinner = OCKSchedule.dailyAtTime(hour: 17, minutes: 30, start: startDate, end: nil, text: "Dinner")
        task.schedule = OCKSchedule(composing: [dinner])
        try storeManager.store.updateTaskAndWait(task)
    }

    private func makeViewController() -> MockTaskViewController {
        let query = OCKEventQuery(for: Date())
        let viewController = MockTaskViewController(storeManager: storeManager, task: task, eventQuery: query)
        viewController.updatesViewWithDuplicates = false
        synchronizationDelegate = .init()
        taskDelegate = .init()
        viewController.synchronizationDelegate = synchronizationDelegate
        viewController.delegate = taskDelegate
        return viewController
    }

    func testInitialState() {
        let viewController = makeViewController()
        let initialExpectation = expectation(description: "Initial view")
        synchronizationDelegate.viewModelRecieved = { [weak self] newValue, version in
            guard let self = self else { return }
            switch version {
            case 1:
                self.validateInitialState(for: newValue)
                initialExpectation.fulfill()
            default:
                XCTFail("View was updated too many times")
            }
        }
        viewController.loadViewIfNeeded()
        wait(for: [initialExpectation], timeout: Constants.timeout)
    }

    func testUpdatedEvent() {
        let viewController = makeViewController()
        let initialExpectation = expectation(description: "Initial view")
        let updatedExpectation1 = expectation(description: "Update view once")
        let updatedExpectation2 = expectation(description: "Update view twice")

        synchronizationDelegate.viewModelRecieved = { [weak self] newValue, version in
            guard let self = self else { return }
            switch version {
            case 1:
               self.validateInitialState(for: newValue)

                // toggle the button to trigger an update to the event, then the view
                let button = viewController.synchronizedView.buttons[0]
                button.isSelected.toggle()
                viewController.synchronizedView.toggleEvent(button)
                initialExpectation.fulfill()

            case 2:
                self.validateOutcomeState(for: newValue)

                // Update the event manually to trigger an update to the view
                if let outcome = newValue?.first?.outcome {
                    XCTAssertNoThrow(try self.storeManager.store.deleteOutcomeAndWait(outcome))
                }
                updatedExpectation1.fulfill()

            case 3:
                self.validateInitialState(for: newValue)
                updatedExpectation2.fulfill()

            default:
                XCTFail("View was updated too many times")
            }
        }
        viewController.loadViewIfNeeded()
        wait(for: [initialExpectation, updatedExpectation1, updatedExpectation2], timeout: Constants.timeout)
    }

    func testDeletedTask() {
        let viewController = makeViewController()
        let initialExpectation = expectation(description: "Initial view")
        let deletedExpectation = expectation(description: "Deleted the task")

        synchronizationDelegate.viewModelRecieved = { [weak self] newValue, version in
            guard let self = self else { return }
            switch version {
            case 1:
                self.validateInitialState(for: newValue)

                // Delete the task to trigger an update to the view
                XCTAssertNoThrow(try self.storeManager.store.deleteTaskAndWait(self.task))
                initialExpectation.fulfill()

            case 2:
                self.validateDeletedState(for: newValue)
                deletedExpectation.fulfill()

            default:
                XCTFail("View was updated too many times")
            }
        }
        viewController.loadViewIfNeeded()
        wait(for: [initialExpectation, deletedExpectation], timeout: Constants.timeout)
    }

    func testUpdatedTask() {
        let viewController = makeViewController()
        let initialExpectation = expectation(description: "Initial view")
        let updatedExpectation = expectation(description: "Update schedule")

        synchronizationDelegate.viewModelRecieved = { [weak self] newValue, version in
            guard let self = self else { return }
            switch version {
            case 1:
                self.validateInitialState(for: newValue)

                // Update the schedule to trigger an update for the view
                XCTAssertNoThrow(try self.updateSchedule())
                initialExpectation.fulfill()

            case 2:
                self.validateUpdatedTask(for: newValue)
                updatedExpectation.fulfill()

            default:
                XCTFail("View was updated too many times")
            }
        }

        viewController.loadViewIfNeeded()
        wait(for: [initialExpectation, updatedExpectation], timeout: Constants.timeout)
    }

    /// Three events should exist with no outcomes
    private func validateInitialState(for viewModel: [OCKStore.Event]?) {
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel?.count, 3)
        viewModel?.forEach { XCTAssertNil($0.outcome) }
    }

    /// The events should exist with one outcome
    private func validateOutcomeState(for viewModel: [OCKStore.Event]?) {
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel?.count, 3)
        if let events = viewModel, events.count == 3 {
            XCTAssertNotNil(viewModel?[0].outcome)
            XCTAssertNil(viewModel?[1].outcome)
            XCTAssertNil(viewModel?[2].outcome)
        }
    }

    private func validateDeletedState(for viewModel: [OCKStore.Event]?) {
        XCTAssertNil(viewModel)
    }

    // One event should exist with no outcomes
    private func validateUpdatedTask(for viewModel: [OCKStore.Event]?) {
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel?.count, 1)
        if let event = viewModel?.first {
            XCTAssertNil(event.outcome)
        }
    }
}
