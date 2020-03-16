//
/*
 Copyright (c) 2020, Apple Inc. All rights reserved.
 
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
import Foundation
import XCTest

// Just testing access level
private class CustomSimpleTaskCategoryViewSynchronizer: OCKSimpleTaskCategoryViewSynchronizer {
    override func makeView() -> OCKSimpleTaskCategoryView {
        return super.makeView()
    }

    override func updateView(_ view: OCKSimpleTaskCategoryView, context: OCKSynchronizationContext<OCKAnyTaskCategory?>) {
        super.updateView(view, context: context)
    }
}

// Just testing access level
private class CustomDetailedTaskCategoryViewSynchronizer: OCKDetailedTaskCategoryViewSynchronizer {
    override func makeView() -> OCKDetailedTaskCategoryView {
        return super.makeView()
    }

    override func updateView(_ view: OCKDetailedTaskCategoryView, context: OCKSynchronizationContext<OCKAnyTaskCategory?>) {
        super.updateView(view, context: context)
    }
}

private class MockTaskCategoryLabel: UILabel, OCKTaskCategoryDisplayable {
    weak var delegate: OCKTaskCategoryViewDelegate?
}

private class CustomTaskCategoryViewSynchronizer: OCKTaskCategoryViewSynchronizerProtocol {
    func makeView() -> MockTaskCategoryLabel {
        return .init()
    }

    func updateView(_ view: MockTaskCategoryLabel, context: OCKSynchronizationContext<OCKAnyTaskCategory?>) {
        view.text = context.viewModel?.title
    }
}

private extension OCKTaskCategory {
    static func mock() -> OCKTaskCategory {
        let taskCategory = OCKTaskCategory(id: "abcd", title: "Medicine", carePlanID: nil)
        return taskCategory
    }
}

class TestCustomTaskCategoryViewSynchronizer: XCTestCase {

    private var viewSynchronizer: CustomTaskCategoryViewSynchronizer!
    private var view: MockTaskCategoryLabel!

    override func setUp() {
        super.setUp()
        viewSynchronizer = .init()
        view = viewSynchronizer.makeView()
    }

    // View should be cleared in the initial state
    func testInitialStateIsEmpty() {
        XCTAssertNil(view.text)
    }

    // View should fill with task category data
    func testDoesUpdate() {
        let taskCategory = OCKTaskCategory.mock()
        viewSynchronizer.updateView(view, context: .init(viewModel: taskCategory, oldViewModel: nil, animated: false))
        XCTAssertEqual(view.text, taskCategory.title)
    }

    // View should be cleared after updating with a nil task category
    func testDoesClear() {
        let taskCategory  = OCKTaskCategory.mock()
        viewSynchronizer.updateView(view, context: .init(viewModel: taskCategory, oldViewModel: nil, animated: false))
        XCTAssertNotNil(view.text)

        // Update with a nil task category
        viewSynchronizer.updateView(view, context: .init(viewModel: nil, oldViewModel: nil, animated: false))
        XCTAssertNil(view.text)
    }
}
