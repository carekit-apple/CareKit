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

private class MockChartView: UIView, OCKChartDisplayable {
    weak var delegate: OCKChartViewDelegate?
    var dataSeries: [OCKDataSeries]?
}

private class MockChartViewController: OCKChartViewController<MockChartView, OCKStore> {
    override func makeView() -> MockChartView {
        return .init()
    }

    override func updateView(_ view: MockChartView, context: OCKSynchronizationContext<[OCKDataSeries]>) {
        view.dataSeries = context.viewModel
    }
}

class TestAbstractChartViewController: XCTestCase {
    private enum Constants {
        static let timeout: TimeInterval = 3
        static let taskIdentifier = "doxylamine"
    }

    private var mockSynchronizationDelegate: MockSynchronizationDelegate<[OCKDataSeries]>!
    private var mockChartDelegate: MockChartViewControllerDelegate!
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
        let interval = Calendar.current.dateInterval(of: .weekOfYear, for: Date())!
        return OCKTask(identifier: Constants.taskIdentifier, title: Constants.taskIdentifier.capitalized, carePlanID: nil,
                       schedule: .mealTimesEachDay(start: interval.start, end: nil))
    }

    private func makeViewController() -> MockChartViewController {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let dataSeries = OCKDataSeriesConfiguration<OCKStore>(taskIdentifier: Constants.taskIdentifier, legendTitle: "",
                                                              gradientStartColor: .red, gradientEndColor: .red,
                                                              markerSize: 1, eventAggregator: .countOutcomes)
        let viewController = MockChartViewController(storeManager: storeManager, dataSeriesConfigurations: [dataSeries], date: startOfDay)
        viewController.updatesViewWithDuplicates = false

        mockSynchronizationDelegate = .init()
        mockChartDelegate = .init()
        viewController.delegate = mockChartDelegate
        viewController.synchronizationDelegate = mockSynchronizationDelegate
        return viewController
    }

    func testInitialStates() {
        // Setup expectation to validate the view
        let viewController = makeViewController()
        let initialExpectation = expectation(description: "initial setup")
        mockSynchronizationDelegate.viewModelRecieved = { [weak self] newValue, version in
            guard let self = self else { return }
            switch version {
            case 1:
                self.validateInitialState(for: newValue)
                initialExpectation.fulfill()
            default:
                XCTFail("View updated too many times")
            }
        }

        // Load the view to initiate the subscription
        viewController.loadViewIfNeeded()
        wait(for: [initialExpectation], timeout: Constants.timeout)
    }

    func testDeleteTask() {
        // Setup expectation to validate the view
        let viewController = makeViewController()
        let initialExpectation = expectation(description: "initial setup")
        let deletedExpectation = expectation(description: "deleted task")
        mockSynchronizationDelegate.viewModelRecieved = { [weak self] newValue, version in
            guard let self = self else { return }
            switch version {
            case 1:
                self.validateInitialState(for: newValue)
                XCTAssertNoThrow(try self.storeManager.store.deleteTaskAndWait(self.task))
                initialExpectation.fulfill()
            case 2:
                self.validateDeletedState(for: newValue)
                deletedExpectation.fulfill()
            default:
                XCTFail("View updated too many times")
            }
        }

        // Load the view to initiate the subscription
        viewController.loadViewIfNeeded()
        wait(for: [initialExpectation, deletedExpectation], timeout: Constants.timeout)
    }

    func testUpdatedTask() {
        // Setup expectation to validate the view
        let viewController = makeViewController()
        viewController.updatesViewWithDuplicates = true     // The update in case 2 will contain the same data series
        let initialExpectation = expectation(description: "initial setup")
        let updatedExpectation = expectation(description: "updated task")
        mockSynchronizationDelegate.viewModelRecieved = { [weak self] newValue, version in
            guard let self = self else { return }
            switch version {
            case 1:
                self.validateInitialState(for: newValue)
                XCTAssertNoThrow(try self.updateSchedule())
                initialExpectation.fulfill()
            case 2:
                self.validateInitialState(for: newValue)
                updatedExpectation.fulfill()
            default:
                XCTFail("View updated too many times")
            }
        }

        // Load the view to initiate the subscription
        viewController.loadViewIfNeeded()
        wait(for: [initialExpectation, updatedExpectation], timeout: Constants.timeout)
    }

    func testAddedOutcome() {
        // Setup expectation to validate the view
        let viewController = makeViewController()
        let initialExpectation = expectation(description: "initial setup")
        let updatedExpectation = expectation(description: "added outcome")
        mockSynchronizationDelegate.viewModelRecieved = { [weak self] newValue, version in
            guard let self = self else { return }
            switch version {
            case 1:
                self.validateInitialState(for: newValue)
                XCTAssertNoThrow(try self.addOutcomes(count: 1))
                initialExpectation.fulfill()
            case 2:
                self.validateOutcomeState(for: newValue, expectedOutcomesForFirstEvent: 1)
                updatedExpectation.fulfill()
            default:
                XCTFail("View updated too many times")
            }
        }

        // Load the view to initiate the subscription
        viewController.loadViewIfNeeded()
        wait(for: [initialExpectation, updatedExpectation], timeout: Constants.timeout)
    }

    func testDeletedOutcome() throws {
        try addOutcomes(count: 1)

        // Setup expectation to validate the view
        let viewController = makeViewController()
        let initialExpectation = expectation(description: "initial setup")
        let updatedExpectation = expectation(description: "added outcome")
        mockSynchronizationDelegate.viewModelRecieved = { [weak self] newValue, version in
            guard let self = self else { return }
            switch version {
            case 1:
                self.validateOutcomeState(for: newValue, expectedOutcomesForFirstEvent: 1)
                XCTAssertNoThrow(try self.deleteOutcomes(count: 1))
                initialExpectation.fulfill()
            case 2:
                self.validateInitialState(for: newValue)
                updatedExpectation.fulfill()
            default:
                XCTFail("View updated too many times")
            }
        }

        // Load the view to initiate the subscription
        viewController.loadViewIfNeeded()
        wait(for: [initialExpectation, updatedExpectation], timeout: Constants.timeout)
    }

    func testUpdatedOutcome() throws {
        try addOutcomes(count: 1)

        // Setup expectation to validate the view
        let viewController = makeViewController()
        viewController.updatesViewWithDuplicates = true
        let initialExpectation = expectation(description: "initial setup")
        let updatedExpectation = expectation(description: "added outcome")
        mockSynchronizationDelegate.viewModelRecieved = { [weak self] newValue, version in
            guard let self = self else { return }
            switch version {
            case 1:
                self.validateOutcomeState(for: newValue, expectedOutcomesForFirstEvent: 1)
                XCTAssertNoThrow(try self.updateOutcomes(count: 1))
                initialExpectation.fulfill()
            case 2:
                self.validateOutcomeState(for: newValue, expectedOutcomesForFirstEvent: 1)
                updatedExpectation.fulfill()
            default:
                XCTFail("View updated too many times")
            }
        }

        // Load the view to initiate the subscription
        viewController.loadViewIfNeeded()
        wait(for: [initialExpectation, updatedExpectation], timeout: Constants.timeout)
    }

    // initial states should have one value with 7 data points
    private func validateInitialState(for dataSeries: [OCKDataSeries]?) {
        XCTAssertNotNil(dataSeries)
        XCTAssertEqual(dataSeries?.count, 1)
        XCTAssertEqual(dataSeries?.first?.dataPoints.count, 7)
        if let dataPoints = dataSeries?.first?.dataPoints, dataPoints.count == 7 {
            for index in 0..<dataPoints.count {
                XCTAssertEqual(dataPoints[index], CGPoint(x: index, y: 0))
            }
        }
    }

    private func validateOutcomeState(for dataSeries: [OCKDataSeries]?, expectedOutcomesForFirstEvent count: Int) {
        XCTAssertNotNil(dataSeries)
        XCTAssertEqual(dataSeries?.count, 1)
        XCTAssertEqual(dataSeries?.first?.dataPoints.count, 7)
        if let dataPoints = dataSeries?.first?.dataPoints, dataPoints.count == 7 {
            for index in 0..<dataPoints.count {
                index == 0 ?
                    XCTAssertEqual(dataPoints[index], CGPoint(x: index, y: count)) :
                    XCTAssertEqual(dataPoints[index], CGPoint(x: index, y: 0))
            }
        }
    }

    private func validateDeletedState(for dataSeries: [OCKDataSeries]?) {
        XCTAssertNotNil(dataSeries)
        if let dataSeries = dataSeries {
            XCTAssertTrue(dataSeries.isEmpty)
        }
    }

    private func updateSchedule() throws {
        var task: OCKTask! = self.task
        let startDate = Calendar.current.startOfDay(for: Date())
        let dinner = OCKSchedule.dailyAtTime(hour: 17, minutes: 30, start: startDate, end: nil, text: "Dinner")
        task.schedule = OCKSchedule(composing: [dinner])
        try storeManager.store.updateTaskAndWait(task)
    }

    // update outcomes for the first `n` events
    private func updateOutcomes(count: Int) throws {
        let events = try getEvents(count: count)
        for event in events {
            guard var outcome = event.outcome else { continue }
            outcome.values = [OCKOutcomeValue(true)]
            try storeManager.store.updateOutcomeAndWait(outcome)
        }
    }

    /// Add outcomes to the first `n` events
    private func addOutcomes(count: Int) throws {
        let events = try getEvents(count: count)
        for event in events {
            let outcome = OCKOutcome(taskID: task.versionID, taskOccurenceIndex: event.scheduleEvent.occurence, values: [])
            try storeManager.store.addOutcomeAndWait(outcome)
        }
    }

    // Delete the first `n` outcomes
    private func deleteOutcomes(count: Int) throws {
        let events = try getEvents(count: count)
        for event in events {
            guard let outcome = event.outcome else { continue }
            try storeManager.store.deleteOutcomeAndWait(outcome)
        }
    }

    // get the first `n` events
    private func getEvents(count: Int) throws -> [OCKStore.Event] {
        let interval = Calendar.current.dateInterval(of: .weekOfYear, for: Date())!
        let events = try storeManager.store.fetchEventsAndWait(taskIdentifier: task.identifier, query: OCKEventQuery(dateInterval: interval))
        let sortedEvents = events.sorted { $0.scheduleEvent.start < $1.scheduleEvent.start }
        guard count < sortedEvents.count else { fatalError("Asked for too many events") }
        return Array(sortedEvents.prefix(count))
    }
}
