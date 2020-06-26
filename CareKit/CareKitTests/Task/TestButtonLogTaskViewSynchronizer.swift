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

class TestButtonLogTaskViewSynchronizer: XCTestCase {

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    var viewSynchronizer: OCKButtonLogTaskViewSynchronizer!
    var view: OCKButtonLogTaskView!
    var taskEvents: OCKTaskEvents!

    override func setUp() {
        super.setUp()
        viewSynchronizer = .init()
        view = viewSynchronizer.makeView()
    }

    func testViewIsClearInInitialState() {
        XCTAssertNil(view.headerView.titleLabel.text)
        XCTAssertNil(view.headerView.detailLabel.text)
        XCTAssertNil(view.instructionsLabel.text)
        XCTAssertEqual(view.items.count, 0)
    }

    func testDoesUpdateView() {
        taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: false, occurrences: 1)
        viewSynchronizer.updateView(view, context: .init(viewModel: taskEvents, oldViewModel: .init(), animated: false))
        let event = taskEvents.first?.first
        XCTAssertEqual(view.headerView.titleLabel.text, event?.task.title)
        XCTAssertEqual(view.headerView.detailLabel.text, OCKScheduleUtility.scheduleLabel(for: event!))
        XCTAssertEqual(view.instructionsLabel.text, event?.task.instructions)
    }

    func testItemsDoUpdateWithNoOutcome() {
        taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: false, occurrences: 1)
        viewSynchronizer.updateView(view, context: .init(viewModel: taskEvents, oldViewModel: .init(), animated: false))
        XCTAssertEqual(view.items.count, 0)
    }

    func testItemsDoUpdateWithOutcome() {
        taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: true, occurrences: 1)
        viewSynchronizer.updateView(view, context: .init(viewModel: taskEvents, oldViewModel: .init(), animated: false))
        let event = taskEvents.first?.first
        XCTAssertEqual(view.items.count, 1)
        XCTAssertEqual(loc("COMPLETED"), view.items.first?.titleLabel.text)
        XCTAssertEqual(OCKScheduleUtility.completedTimeLabel(for: event!), view.items.first?.detailLabel.text)
    }

    func testViewDoesClearAfterUpdate() {
        taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: true)
        viewSynchronizer.updateView(view, context: .init(viewModel: taskEvents, oldViewModel: .init(), animated: false))
        XCTAssertNotNil(view.headerView.titleLabel.text)
        XCTAssertNotNil(view.headerView.detailLabel.text)
        XCTAssertNotNil(view.instructionsLabel.text)
        XCTAssertNotEqual(view.items.count, 0)

        viewSynchronizer.updateView(view, context: .init(viewModel: .init(), oldViewModel: .init(), animated: false))
        XCTAssertNil(view.headerView.titleLabel.text)
        XCTAssertNil(view.headerView.detailLabel.text)
        XCTAssertNil(view.instructionsLabel.text)
        XCTAssertEqual(view.items.count, 0)
    }

    func testUpdateTrimsItems() {
        taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: false, occurrences: 1)
        viewSynchronizer.updateView(view, context: .init(viewModel: taskEvents, oldViewModel: .init(), animated: false))
        XCTAssertEqual(view.items.count, 0)
        taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: true, occurrences: 1)
        viewSynchronizer.updateView(view, context: .init(viewModel: taskEvents, oldViewModel: .init(), animated: false))
        XCTAssertEqual(view.items.count, 1)
    }

    func testUpdateAppendsItems() {
        taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: true, occurrences: 1)
        viewSynchronizer.updateView(view, context: .init(viewModel: taskEvents, oldViewModel: .init(), animated: false))
        XCTAssertEqual(view.items.count, 1)
        taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: false, occurrences: 1)
        viewSynchronizer.updateView(view, context: .init(viewModel: taskEvents, oldViewModel: .init(), animated: false))
        XCTAssertEqual(view.items.count, 0)
    }
}
