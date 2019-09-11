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

private class MockEventView: UIView, OCKEventDisplayable {
    let segmentedControl: UISegmentedControl = {
        let items = ["complete", "not complete"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        return control
    }()

    weak var delegate: OCKEventViewDelegate?

    init() {
        super.init(frame: .zero)
        addSubview(segmentedControl)
        segmentedControl.addTarget(self, action: #selector(indexChanged(_:)), for: .valueChanged)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func indexChanged(_ sender: UISegmentedControl) {
        var isComplete = false
        switch sender.selectedSegmentIndex {
        case 0: isComplete = false
        case 1: isComplete = true
        default: break
        }
        delegate?.eventView(self, didCompleteEvent: isComplete, sender: sender)
    }
}

private class MockEventViewController: OCKEventViewController<MockEventView, OCKStore> {
    override func makeView() -> MockEventView {
        return .init()
    }

    override func updateView(_ view: MockEventView, context: OCKSynchronizationContext<OCKStore.Event>) {
        let isComplete = context.viewModel?.outcome != nil
        view.segmentedControl.selectedSegmentIndex = isComplete ? 0 : 1
    }
}

class TestAbstractEventViewController: XCTestCase {
    enum Constants {
        static let timeout: TimeInterval = 3
    }

    var storeManager: OCKSynchronizedStoreManager<OCKStore>!
    private var synchronizationDelegate: MockSynchronizationDelegate<OCKStore.Event>!
    private var eventDelegate: MockEventViewControllerDelegate!
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

    private func makeViewController() -> MockEventViewController {
        let query = OCKEventQuery(for: Date())
        let viewController = MockEventViewController(storeManager: storeManager, task: task, eventQuery: query)
        viewController.updatesViewWithDuplicates = false
        synchronizationDelegate = .init()
        eventDelegate = .init()
        viewController.synchronizationDelegate = synchronizationDelegate
        viewController.delegate = eventDelegate
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

                // Update the segmented control to trigger an update to the event, then the view
                viewController.synchronizedView.segmentedControl.selectedSegmentIndex = 1
                viewController.synchronizedView.indexChanged(viewController.synchronizedView.segmentedControl)
                initialExpectation.fulfill()

            case 2:
                self.validateOutcomeState(for: newValue)

                // Update the event manually to trigger an update to the view
                if let outcome = newValue?.outcome {
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

    private func validateInitialState(for viewModel: OCKStore.Event?) {
        XCTAssertNotNil(viewModel)
        XCTAssertNil(viewModel?.outcome)
    }

    private func validateOutcomeState(for viewModel: OCKStore.Event?) {
        XCTAssertNotNil(viewModel)
        XCTAssertNotNil(viewModel?.outcome)
    }
}
