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
import CareKitUI
import Foundation
import XCTest

class TestSimpleTaskViewSynchronizer: XCTestCase {

    var viewSynchronizer: OCKSimpleTaskViewSynchronizer!
    var view: OCKSimpleTaskView!
    var taskEvents: OCKTaskEvents!

    override func setUp() {
        super.setUp()
        viewSynchronizer = .init()
        view = viewSynchronizer.makeView()
    }

    func testViewIsClearedInInitialState() {
        XCTAssertNil(view.headerView.titleLabel.text)
        XCTAssertNil(view.headerView.detailLabel.text)
        XCTAssertFalse(view.completionButton.isSelected)
    }

    func testViewDoesUpdate() {
        taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: false)
        viewSynchronizer.updateView(view, context: .init(viewModel: taskEvents, oldViewModel: .init(), animated: false))
        XCTAssertEqual(view.headerView.titleLabel.text, taskEvents.first?.first?.task.title)
        XCTAssertEqual(view.headerView.detailLabel.text, OCKScheduleUtility.scheduleLabel(for: taskEvents.first?.first))
        XCTAssertFalse(view.completionButton.isSelected)
    }

    func testCompletionButtonDoesUpdateWithNoOutcome() {
        taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: false)
        viewSynchronizer.updateView(view, context: .init(viewModel: taskEvents, oldViewModel: .init(), animated: false))
        XCTAssertFalse(view.completionButton.isSelected)
        XCTAssertEqual(view.accessibilityValue, loc("INCOMPLETE"))
    }

    func testCompletionButtonDoesUpdateWithOutcome() {
        taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: true)
        viewSynchronizer.updateView(view, context: .init(viewModel: taskEvents, oldViewModel: .init(), animated: false))
        XCTAssertTrue(view.completionButton.isSelected)
        XCTAssertEqual(view.accessibilityValue, loc("COMPLETED"))
    }

    func testViewDoesClearAfterUpdate() {
        taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: true)
        viewSynchronizer.updateView(view, context: .init(viewModel: taskEvents, oldViewModel: .init(), animated: false))
        XCTAssertNotNil(view.headerView.titleLabel.text)
        XCTAssertNotNil(view.headerView.detailLabel.text)
        XCTAssertTrue(view.completionButton.isSelected)
        XCTAssertEqual(view.accessibilityValue, loc("COMPLETED"))

        viewSynchronizer.updateView(view, context: .init(viewModel: .init(), oldViewModel: .init(), animated: false))
        XCTAssertNil(view.headerView.titleLabel.text)
        XCTAssertNil(view.headerView.detailLabel.text)
        XCTAssertFalse(view.completionButton.isSelected)
        XCTAssertNil(view.accessibilityValue)
    }
}
