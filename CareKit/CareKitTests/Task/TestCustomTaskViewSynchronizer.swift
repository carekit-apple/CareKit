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
import CareKitStore
import CareKitUI
import Foundation
import XCTest

// Just testing access level
private class CustomSimpleTaskViewSynchronizer: OCKSimpleTaskViewSynchronizer {
    override func makeView() -> OCKSimpleTaskView {
        return super.makeView()
    }

    override func updateView(_ view: OCKSimpleTaskView, context: OCKSynchronizationContext<OCKTaskEvents>) {
        super.updateView(view, context: context)
    }
}

// Just testing access level
private class CustomInstructionsTaskViewSynchronizer: OCKInstructionsTaskViewSynchronizer {
    override func makeView() -> OCKInstructionsTaskView {
        return super.makeView()
    }

    override func updateView(_ view: OCKInstructionsTaskView, context: OCKSynchronizationContext<OCKTaskEvents>) {
        super.updateView(view, context: context)
    }
}

// Just testing access level
private class CustomButtonLogTaskViewSynchronizer: OCKButtonLogTaskViewSynchronizer {
    override func makeView() -> OCKButtonLogTaskView {
        return super.makeView()
    }

    override func updateView(_ view: OCKButtonLogTaskView, context: OCKSynchronizationContext<OCKTaskEvents>) {
        super.updateView(view, context: context)
    }
}

// Just testing access level
private class CustomChecklistTaskViewSynchronizer: OCKChecklistTaskViewSynchronizer {
    override func makeView() -> OCKChecklistTaskView {
        return super.makeView()
    }

    override func updateView(_ view: OCKChecklistTaskView, context: OCKSynchronizationContext<OCKTaskEvents>) {
        super.updateView(view, context: context)
    }
}

// Just testing access level
private class CustomGridTaskViewSynchronizer: OCKGridTaskViewSynchronizer {
    override func makeView() -> OCKGridTaskView {
        return super.makeView()
    }

    override func updateView(_ view: OCKGridTaskView, context: OCKSynchronizationContext<OCKTaskEvents>) {
        super.updateView(view, context: context)
    }
}

private class MockTaskLabel: UILabel, OCKTaskDisplayable {
    weak var delegate: OCKTaskViewDelegate?
}

private class CustomTaskViewSynchronizer: OCKTaskViewSynchronizerProtocol {
    func makeView() -> MockTaskLabel {
        return .init()
    }

    func updateView(_ view: MockTaskLabel, context: OCKSynchronizationContext<OCKTaskEvents>) {
        view.text = context.viewModel.first?.first?.task.title
    }
}

class TestCustomTaskViewSynchronizer: XCTestCase {

    private var viewSynchronizer: CustomTaskViewSynchronizer!
    private var view: MockTaskLabel!

    override func setUp() {
        super.setUp()
        viewSynchronizer = .init()
        view = viewSynchronizer.makeView()
    }

    func testViewIsClearInInitialState() {
        XCTAssertNil(view.text)
    }

    func testViewDoesUpdate() {
        let taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: false, occurrences: 1)
        viewSynchronizer.updateView(view, context: .init(viewModel: taskEvents, oldViewModel: .init(), animated: false))
        XCTAssertEqual(view.text, "Doxylamine")
    }

    func testViewDoesClearAfterUpdate() {
        let taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: false, occurrences: 1)
        viewSynchronizer.updateView(view, context: .init(viewModel: taskEvents, oldViewModel: .init(), animated: false))
        XCTAssertNotNil(view.text)

        // Update with a nil contact
        viewSynchronizer.updateView(view, context: .init(viewModel: .init(), oldViewModel: .init(), animated: false))
        XCTAssertNil(view.text)
    }
}
