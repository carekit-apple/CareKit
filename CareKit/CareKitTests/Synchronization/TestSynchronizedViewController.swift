/*
 Copyright (c) 2021, Apple Inc. All rights reserved.
 
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

import AsyncAlgorithms
import XCTest

class TestSynchronizedViewController: XCTestCase {

    func testInitialValue() {

        let initialValue = 0
        let values = [Int]().async

        let viewController = MockSynchronizedViewController(
            initialViewModel: initialValue,
            viewModels: values,
            viewSynchronizer: MockViewSynchronizer()
        )

        XCTAssertEqual(viewController.viewModel, initialValue)
    }

    func testViewModelUpdates() {

        let viewModels = [1, 2, 3]

        let expectedContexts = [
            OCKSynchronizationContext(viewModel: 1, oldViewModel: 1, animated: false),
            OCKSynchronizationContext(viewModel: 2, oldViewModel: 1, animated: true),
            OCKSynchronizationContext(viewModel: 3, oldViewModel: 2, animated: true)
        ]

        let didUpdateView = XCTestExpectation(description: "View updated")
        didUpdateView.assertForOverFulfill = true
        didUpdateView.expectedFulfillmentCount = expectedContexts.count

        var observedContexts: [OCKSynchronizationContext<Int>] = []

        let viewSynchronizer = MockViewSynchronizer { _, context in
            observedContexts.append(context)
            didUpdateView.fulfill()
        }

        let viewController = MockSynchronizedViewController(
            initialViewModel: viewModels.first!,
            viewModels: viewModels.dropFirst().async,
            viewSynchronizer: viewSynchronizer
        )

        viewController.loadViewIfNeeded()

        wait(for: [didUpdateView], timeout: 2)

        XCTAssertEqual(observedContexts, expectedContexts)
    }

    func testCreatesView() {

        let viewController = MockSynchronizedViewController(
            initialViewModel: 0,
            viewModels: [Int]().async,
            viewSynchronizer: MockViewSynchronizer()
        )

        XCTAssertNotNil(viewController.view as? MockViewSynchronizer.View)
    }

    func testResetView() {

        let expectedContexts = [
            OCKSynchronizationContext(viewModel: 0, oldViewModel: 0, animated: false),
            OCKSynchronizationContext(viewModel: 0, oldViewModel: 0, animated: false)
        ]

        let didUpdateView = XCTestExpectation(description: "View updated")
        didUpdateView.assertForOverFulfill = true
        didUpdateView.expectedFulfillmentCount = expectedContexts.count

        var observedContexts: [OCKSynchronizationContext<Int>] = []

        let viewSynchronizer = MockViewSynchronizer { _, context in
            observedContexts.append(context)
            didUpdateView.fulfill()
        }

        let viewController = MockSynchronizedViewController(
            initialViewModel: 0,
            viewModels: [Int]().async,
            viewSynchronizer: viewSynchronizer
        )

        viewController.loadViewIfNeeded()

        let failure: Result<Int, Error> = .failure(MockError())
        viewController.resetViewOnError(result: failure)

        XCTAssertEqual(observedContexts, expectedContexts)
    }
}

private struct MockViewSynchronizer: ViewSynchronizing {

    let updateView: (MockView, OCKSynchronizationContext<Int>) -> Void

    init(
        updateView: @escaping (MockView, OCKSynchronizationContext<Int>) -> Void = { _, _ in }
    ) {
        self.updateView = updateView
    }

    func makeView() -> MockView {
        return MockView()
    }

    func updateView(
        _ view: MockView,
        context: OCKSynchronizationContext<Int>
    ) {
        updateView(view, context)
    }
}

private class MockSynchronizedViewController: SynchronizedViewController<MockViewSynchronizer> {}

private class MockView: UIView {}

private struct MockError: Error {}
