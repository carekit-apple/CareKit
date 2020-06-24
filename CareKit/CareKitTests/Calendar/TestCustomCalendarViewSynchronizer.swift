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

import CareKit
import CareKitUI
import Foundation
import XCTest

// Just testing access level
private class CustomWeekCalendarViewSynchronizer: OCKWeekCalendarViewSynchronizer {
    override func makeView() -> OCKWeekCalendarView {
        return super.makeView()
    }

    override func updateView(_ view: OCKWeekCalendarView, context: OCKSynchronizationContext<[OCKCompletionState]>) {
        super.updateView(view, context: context)
    }
}

private class MockCalendarView: UILabel, OCKCalendarDisplayable {
    weak var delegate: OCKCalendarViewDelegate?
    var completionStates: [OCKCompletionState] = []
}

private class CustomCalendarViewSynchronizer: OCKCalendarViewSynchronizerProtocol {
    func makeView() -> MockCalendarView {
        return .init()
    }

    func updateView(_ view: MockCalendarView, context: OCKSynchronizationContext<[OCKCompletionState]>) {
        view.completionStates = context.viewModel
    }
}

class TestCustomCalendarViewSynchronizer: XCTestCase {

    private var viewSynchronizer: CustomCalendarViewSynchronizer!
    private var view: MockCalendarView!

    override func setUp() {
        super.setUp()
        viewSynchronizer = .init()
        view = viewSynchronizer.makeView()
    }

    // View should be cleared in the initial state
    func testInitialStateIsEmpty() {
        XCTAssertTrue(view.completionStates.isEmpty)
    }

    // View should fill with data
    func testDoesUpdate() {
        let states: [OCKCompletionState] = Array(repeating: .empty, count: 7)
        viewSynchronizer.updateView(view, context: .init(viewModel: states, oldViewModel: [], animated: false))
        XCTAssertEqual(view.completionStates, states)
    }

    // View should be cleared after updating with a no data
    func testDoesClear() {
       let states: [OCKCompletionState] = Array(repeating: .empty, count: 7)
        viewSynchronizer.updateView(view, context: .init(viewModel: states, oldViewModel: [], animated: false))
        XCTAssertFalse(view.completionStates.isEmpty)

        // Update with a no data
        viewSynchronizer.updateView(view, context: .init(viewModel: [], oldViewModel: [], animated: false))
        XCTAssertTrue(view.completionStates.isEmpty)
    }
}
