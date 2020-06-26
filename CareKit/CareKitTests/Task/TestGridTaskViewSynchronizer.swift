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

class TestGridTaskViewSynchronizer: XCTestCase {

    var viewSynchronizer: OCKGridTaskViewSynchronizer!
    var view: OCKGridTaskView!
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
    }

    func testCellIsClearedInInitialState() {
        let cell = OCKGridTaskView.DefaultCellType()
        XCTAssertFalse(cell.completionButton.isSelected)
        XCTAssertNil(cell.completionButton.label.text)
    }

    func testViewDoesUpdate() {
        taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: false)
        viewSynchronizer.updateView(view, context: .init(viewModel: taskEvents, oldViewModel: .init(), animated: false))
        XCTAssertEqual(view.instructionsLabel.text, taskEvents.first?.first?.task.instructions)
        XCTAssertEqual(view.headerView.titleLabel.text, taskEvents.first?.first?.task.title)
        XCTAssertEqual(view.headerView.detailLabel.text, OCKScheduleUtility.scheduleLabel(for: taskEvents.first!))
    }

    func testCellDoesUpdateWithNoOutcomes() {
        taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: false)
        let itemCount = taskEvents.first?.count
        for index in 0..<(itemCount ?? 0) {
            let cell = OCKGridTaskView.DefaultCellType()
            cell.updateWith(event: taskEvents[0][index], animated: false)
            XCTAssertFalse(cell.completionButton.isSelected)
            XCTAssertEqual(cell.completionButton.label.text,
                           OCKScheduleUtility.timeLabel(for: taskEvents[0][index], includesEnd: false))

            // Accessibility
            XCTAssertEqual(cell.accessibilityLabel, cell.completionButton.label.text)
            XCTAssertEqual(cell.accessibilityValue, loc("INCOMPLETE"))
        }
    }

    func testCellDoesUpdateWithOutcomes() {
        taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: true)
        let itemCount = taskEvents.first?.count
        for index in 0..<(itemCount ?? 0) {
            let cell = OCKGridTaskView.DefaultCellType()
            cell.updateWith(event: taskEvents[0][index], animated: false)
            XCTAssertTrue(cell.completionButton.isSelected)
            XCTAssertEqual(cell.completionButton.label.text,
                           OCKScheduleUtility.completedTimeLabel(for: taskEvents[0][index]))

            // Accessibility
            XCTAssertEqual(cell.accessibilityLabel, cell.completionButton.label.text)
            XCTAssertEqual(cell.accessibilityValue, loc("COMPLETED"))
        }
    }

    func testViewDoesClearAfterUpdate() {
        taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: false)
        viewSynchronizer.updateView(view, context: .init(viewModel: taskEvents, oldViewModel: .init(), animated: false))
        XCTAssertNotNil(view.instructionsLabel.text)
        XCTAssertNotNil(view.headerView.titleLabel.text)
        XCTAssertNotNil(view.headerView.detailLabel.text)

        viewSynchronizer.updateView(view, context: .init(viewModel: .init(), oldViewModel: .init(), animated: false))
        XCTAssertNil(view.instructionsLabel.text)
        XCTAssertNil(view.headerView.titleLabel.text)
        XCTAssertNil(view.headerView.detailLabel.text)
    }
}
