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

private extension OCKTaskCategory {
    static func mock() -> OCKTaskCategory {
        let taskCategory = OCKTaskCategory(id: "M", title: "Medicine", carePlanID: nil)
        return taskCategory
    }
}

class TestDetailedTaskCategoryViewSynchronizer: XCTestCase {

    let nameFormatter: PersonNameComponentsFormatter = {
        let nameFormatter = PersonNameComponentsFormatter()
        nameFormatter.style = .medium
        return nameFormatter
    }()

    var viewSynchronizer: OCKDetailedTaskCategoryViewSynchronizer!
    var view: OCKDetailedTaskCategoryView!

    override func setUp() {
        super.setUp()
        viewSynchronizer = .init()
        view = viewSynchronizer.makeView()
    }

    // View should be cleared in the initial state
    func testInitialStateIsEmpty() {
        XCTAssertNil(view.headerView.titleLabel.text)
        XCTAssertEqual(view.headerView.iconImageView?.image, UIImage(systemName: "questionmark.circle.fill"))
    }

    // View should fill with task category data
    func testDoesUpdate() {
        let taskCategory = OCKTaskCategory.mock()
        viewSynchronizer.updateView(view, context: .init(viewModel: taskCategory, oldViewModel: nil, animated: false))
        XCTAssertEqual(view.headerView.iconImageView?.image, UIImage(systemName: "questionmark.circle.fill"))
    }

    // View should be cleared after updating with a nil task category
    func testDoesClear() {
        let taskCategory = OCKTaskCategory.mock()
        viewSynchronizer.updateView(view, context: .init(viewModel: taskCategory, oldViewModel: nil, animated: false))
        XCTAssertNotNil(view.headerView.titleLabel.text)
        XCTAssertEqual(view.headerView.iconImageView?.image, UIImage(systemName: "questionmark.circle.fill"))

        // Update with a nil task category
        viewSynchronizer.updateView(view, context: .init(viewModel: nil, oldViewModel: nil, animated: false))
        XCTAssertNil(view.headerView.titleLabel.text)
        XCTAssertEqual(view.headerView.iconImageView?.image, UIImage(systemName: "questionmark.circle.fill"))
    }
}
