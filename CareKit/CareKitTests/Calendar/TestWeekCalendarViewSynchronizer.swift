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

class TestWeekCalendarViewSynchronizer: XCTestCase {

    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        return dateFormatter
    }()

    var viewSynchronizer: OCKWeekCalendarViewSynchronizer!
    var view: OCKWeekCalendarView!

    override func setUp() {
        super.setUp()
        viewSynchronizer = .init(weekOfDate: Date())
        view = viewSynchronizer.makeView()
    }

    // View should be cleared in the initial state
    func testInitialStateIsEmpty() {
        view.completionRingButtons.forEach {
            XCTAssertEqual($0.completionState, .dimmed)
        }
    }

    // View should fill with data
    func testDoesUpdate() {
        var states: [OCKCompletionState] = Array(repeating: .empty, count: 7)
        viewSynchronizer.updateView(view, context: .init(viewModel: states, oldViewModel: [], animated: false))
        view.completionRingButtons.forEach {
            XCTAssertEqual($0.completionState, .empty)
        }

        states =
            Array(repeating: .empty, count: 3) +
            Array(repeating: .progress(0.5), count: 4)
        viewSynchronizer.updateView(view, context: .init(viewModel: states, oldViewModel: [], animated: false))
        view.completionRingButtons.enumerated().forEach {
            XCTAssertEqual($1.completionState, states[$0])
        }
    }

    // View should be cleared after updating with no data
    func testDoesClear() {
        let states: [OCKCompletionState] = Array(repeating: .empty, count: 7)
        viewSynchronizer.updateView(view, context: .init(viewModel: states, oldViewModel: [], animated: false))
        view.completionRingButtons.forEach {
            XCTAssertNotEqual($0.completionState, .dimmed)
        }

        viewSynchronizer.updateView(view, context: .init(viewModel: [], oldViewModel: [], animated: false))
        view.completionRingButtons.forEach {
            XCTAssertEqual($0.completionState, .dimmed)
        }
    }

    func testAccessibilityInInitialState() {
        view.accessibilityHint = loc("THREE_FINGER_SWIPE_WEEK")
        view.completionRingButtons.enumerated().forEach {
            XCTAssertNil($1.accessibilityValue)
            XCTAssertNil($1.accessibilityLabel)
            XCTAssertEqual($1.accessibilityTraits, .none)
        }
    }

    func testAccessibilityValueAfterUpdate() {
        var states: [OCKCompletionState] = Array(repeating: .empty, count: 7)
        viewSynchronizer.updateView(view, context: .init(viewModel: states, oldViewModel: [], animated: false))
        view.completionRingButtons.forEach {
            XCTAssertEqual($0.accessibilityValue, loc("NO_EVENTS"))
        }

        states = Array(repeating: .dimmed, count: 7)
        viewSynchronizer.updateView(view, context: .init(viewModel: states, oldViewModel: [], animated: false))
        view.completionRingButtons.forEach {
            XCTAssertEqual($0.accessibilityValue, loc("NO_TASKS"))
        }

        states = Array(repeating: .zero, count: 7)
        viewSynchronizer.updateView(view, context: .init(viewModel: states, oldViewModel: [], animated: false))
        view.completionRingButtons.forEach {
            XCTAssertEqual($0.accessibilityValue, loc("0"))
        }

        states = Array(repeating: .progress(0.5), count: 7)
        viewSynchronizer.updateView(view, context: .init(viewModel: states, oldViewModel: [], animated: false))
        view.completionRingButtons.forEach {
            XCTAssertEqual($0.accessibilityValue, loc("50%"))
        }
    }

    func testAccessibilityAfterUpdate() {
        let states: [OCKCompletionState] = Array(repeating: .empty, count: 7)
        viewSynchronizer.updateView(view, context: .init(viewModel: states, oldViewModel: [], animated: false))
        view.completionRingButtons.enumerated().forEach {
            let date = Calendar.current.date(byAdding: DateComponents(day: $0), to: view.dateInterval.start)!
            XCTAssertEqual($1.accessibilityLabel, dateFormatter.string(from: date))
            XCTAssertEqual($1.accessibilityTraits, $1.isSelected ? [.button, .selected] : [.button])
        }
    }
}
