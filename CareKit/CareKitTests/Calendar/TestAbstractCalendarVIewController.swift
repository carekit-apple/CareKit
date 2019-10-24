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
import Contacts
import XCTest

private class MockCalendarView: UIView, OCKCalendarDisplayable {
    static var intervalComponent: Calendar.Component = .day
    var dateInterval = DateInterval()
    var selectedDate = Date()
    weak var delegate: OCKCalendarViewDelegate?
    var states: [OCKCompletionRingButton.CompletionState] = []

    func selectDate(_ date: Date) {}
    func showDate(_ date: Date) {}
}

private class MockCalendarViewController: OCKCalendarViewController<MockCalendarView, OCKStore> {
    override func makeView() -> MockCalendarView {
        return .init()
    }

    override func updateView(_ view: MockCalendarView, context: OCKSynchronizationContext<[OCKCompletionRingButton.CompletionState]>) {
        view.states = context.viewModel ?? []
    }
}

class TestAbstractCalendarViewController: XCTestCase {
    private enum Constants {
        static let timeout: TimeInterval = 3
    }

    private var mockSynchronizationDelegate: MockSynchronizationDelegate<[OCKCompletionRingButton.CompletionState]>!
    private var mockCalendarDelegate: MockCalendarViewControllerDelegate!
    private var storeManager: OCKSynchronizedStoreManager<OCKStore>!
    var task: OCKTask!

    override func setUp() {
        super.setUp()
        UIView.setAnimationsEnabled(false)

        // add and fetch new task
        storeManager = OCKSynchronizedStoreManager(wrapping: OCKStore(name: "ckstore", type: .inMemory))
        let task = makeTask()
        self.task = try? storeManager.store.addTaskAndWait(task)
        XCTAssertNotNil(self.task)
    }

    func makeTask() -> OCKTask {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return OCKTask(identifier: "doxylamine", title: "Doxylamine", carePlanID: nil,
                       schedule: .mealTimesEachDay(start: startOfDay, end: nil))
    }

    private func makeViewController() -> MockCalendarViewController {
        let viewController = MockCalendarViewController(storeManager: storeManager, date: Date(), aggregator: .countOutcomes)
        viewController.updatesViewWithDuplicates = false

        mockSynchronizationDelegate = .init()
        mockCalendarDelegate = .init()
        viewController.delegate = mockCalendarDelegate
        viewController.synchronizationDelegate = mockSynchronizationDelegate
        return viewController
    }

    func testInitialStates() {
        // Setup expectation to validate the view
        let viewController = makeViewController()
        let viewExpectation = expectation(description: "Validate view")
        mockSynchronizationDelegate.viewModelRecieved = { [weak self] newValue, version in
            guard let self = self else { return }
            switch version {
            case 1:
                self.validateInitialState(for: newValue)
                viewExpectation.fulfill()
            default:
                XCTFail("View updated too many times.")
            }
        }

        // Load the view to initiate the subscription
        viewController.loadViewIfNeeded()
        wait(for: [viewExpectation], timeout: Constants.timeout)
    }

    func testAddedOutcome() {
        // Setup expectation to validate the view
        let viewController = makeViewController()
        let initialExpectation = expectation(description: "initial view")
        let updatedExpectation = expectation(description: "updated view")
        mockSynchronizationDelegate.viewModelRecieved = { [weak self] newValue, version in
            guard let self = self else { return }
            switch version {
            case 1:
                self.validateInitialState(for: newValue)
                XCTAssertNoThrow(try self.addOutcomes())    // complete the task to trigger a new update to the view
                initialExpectation.fulfill()

            // Ensure 100% progress. We only get one callback and not three (three outcomes were added so we expect three callbacks) because the
            // the `addOutcomesAndWait` method blocks the main thread, and thus all outcomes will be added before the view controller registers the
            // change and re-fetches adherence. The view controller will then fetch adherence three times, but the value will be 100% each time.
            case 2:
                self.validateOutcomesState(for: newValue)
                updatedExpectation.fulfill()
            default:
                XCTFail("Updated view too many times")
            }
        }

        // Load the view to initiate the subscription
        viewController.loadViewIfNeeded()
        wait(for: [initialExpectation, updatedExpectation], timeout: Constants.timeout)
    }

    func testDeleteOutcomes() throws {
        try addOutcomes()
        let viewController = makeViewController()

        // Setup expectation to validate the view
        let initialExpectation = expectation(description: "initial view")
        let updatedExpectation = expectation(description: "updated view")
        mockSynchronizationDelegate.viewModelRecieved = { [weak self] newValue, version in
            guard let self = self else { return }
            switch version {
            case 1:
                self.validateOutcomesState(for: newValue)
                XCTAssertNoThrow(try self.deleteOutcomes())    // delete the outcomes to trigger a new update to the view
                initialExpectation.fulfill()
            case 2:
                self.validateInitialState(for: newValue)
                updatedExpectation.fulfill()
            default:
                XCTFail("Updated view too many times")
            }
        }

        // Load the view to initiate the subscription
        viewController.loadViewIfNeeded()
        wait(for: [initialExpectation, updatedExpectation], timeout: Constants.timeout)
    }

    // complete the task events
    private func addOutcomes() throws {
        let events = try storeManager.store.fetchEventsAndWait(taskIdentifier: task.identifier, query: .init(for: Date()))
        let outcomes = events.map {
            return OCKOutcome(taskID: task.versionID, taskOccurenceIndex: $0.scheduleEvent.occurence, values: [])
        }
        try storeManager.store.addOutcomesAndWait(outcomes)
    }

    private func deleteOutcomes() throws {
        let events = try storeManager.store.fetchEventsAndWait(taskIdentifier: task.identifier, query: .init(for: Date()))
        let outcomes = events.compactMap { $0.outcome }
        try storeManager.store.deleteOutcomesAndWait(outcomes)
    }

    // One state should exist with zero progress
    private func validateInitialState(for viewModel: [OCKCompletionRingButton.CompletionState]?) {
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel?.count, 1)
        if let state = viewModel?.first {
            switch state {
            case .zero: break
            default: XCTFail("Unexpected state.")
            }
        }
    }

    private func validateOutcomesState(for viewModel: [OCKCompletionRingButton.CompletionState]?) {
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel?.count, 1)
        if let state = viewModel?.first {
            switch state {
            case .progress(let value): XCTAssertEqual(value, 1)
            default: XCTFail("Unexpected state.")
            }
        }
    }
}
