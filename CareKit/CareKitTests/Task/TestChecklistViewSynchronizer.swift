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

class TestChecklistTaskViewSynchronizer: XCTestCase {

    var viewSynchronizer: OCKChecklistTaskViewSynchronizer!
    var view: OCKChecklistTaskView!
    var taskEvents: OCKTaskEvents!

    override func setUp() {
        super.setUp()
        viewSynchronizer = .init()
        view = viewSynchronizer.makeView()
    }

    func testViewIsClearedInInitialState() {
        XCTAssertNil(view.instructionsLabel.text)
        XCTAssertNil(view.headerView.titleLabel.text)
        XCTAssertNil(view.headerView.detailLabel.text)
        XCTAssertEqual(view.items.count, 0)
    }

    func testViewDoesUpdate() {
        taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: false)
        viewSynchronizer.updateView(view, context: .init(viewModel: taskEvents, oldViewModel: .init(), animated: false))
        XCTAssertEqual(view.instructionsLabel.text, taskEvents.first?.first?.task.instructions)
        XCTAssertEqual(view.headerView.titleLabel.text, taskEvents.first?.first?.task.title)
        XCTAssertEqual(view.headerView.detailLabel.text, OCKScheduleUtility.scheduleLabel(for: taskEvents.first!))
    }

    func testViewDoesUpdateWithNoOutcome() {
        taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: false)
        viewSynchronizer.updateView(view, context: .init(viewModel: taskEvents, oldViewModel: .init(), animated: false))

        XCTAssertEqual(view.items.count, 3)
        XCTAssertEqual(view.items.element(at: 0)?.label.text, "1")
        XCTAssertEqual(view.items.element(at: 1)?.label.text, "2")
        XCTAssertEqual(view.items.element(at: 2)?.label.text, "3")
        view.items.forEach { XCTAssertFalse($0.isSelected) }
    }

    func testViewDoesUpdateWithOutcome() {
        taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: true)
        viewSynchronizer.updateView(view, context: .init(viewModel: taskEvents, oldViewModel: .init(), animated: false))

        XCTAssertEqual(view.items.count, 3)
        XCTAssertEqual(view.items.element(at: 0)?.label.text, "1")
        XCTAssertEqual(view.items.element(at: 1)?.label.text, "2")
        XCTAssertEqual(view.items.element(at: 2)?.label.text, "3")
        view.items.forEach { XCTAssertTrue($0.isSelected) }
    }

    func testViewDoesClearAfterUpdate() {
        taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: false)
        viewSynchronizer.updateView(view, context: .init(viewModel: taskEvents, oldViewModel: .init(), animated: false))
        XCTAssertNotNil(view.instructionsLabel.text)
        XCTAssertNotNil(view.headerView.titleLabel.text)
        XCTAssertNotNil(view.headerView.detailLabel.text)
        XCTAssertNotEqual(view.items.count, 0)

        viewSynchronizer.updateView(view, context: .init(viewModel: .init(), oldViewModel: .init(), animated: false))
        XCTAssertNil(view.instructionsLabel.text)
        XCTAssertNil(view.headerView.titleLabel.text)
        XCTAssertNil(view.headerView.detailLabel.text)
        XCTAssertEqual(view.items.count, 0)
    }

    // Number of items should decrease as occurrences decreases
    func testUpdateTrimsItems() {
        taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: false, occurrences: 3)
        viewSynchronizer.updateView(view, context: .init(viewModel: taskEvents, oldViewModel: .init(), animated: false))
        XCTAssertEqual(view.items.count, 3)
        taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: false, occurrences: 2)
        viewSynchronizer.updateView(view, context: .init(viewModel: taskEvents, oldViewModel: .init(), animated: false))
        XCTAssertEqual(view.items.count, 2)
    }

    // Number of items should increase as occurrences increases
    func testUpdateAppendsItems() {
        taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: false, occurrences: 2)
        viewSynchronizer.updateView(view, context: .init(viewModel: taskEvents, oldViewModel: .init(), animated: false))
        XCTAssertEqual(view.items.count, 2)
        taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: false, occurrences: 3)
        viewSynchronizer.updateView(view, context: .init(viewModel: taskEvents, oldViewModel: .init(), animated: false))
        XCTAssertEqual(view.items.count, 3)
    }
}
