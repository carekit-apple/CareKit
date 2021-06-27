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

import OTFCareKit
import OTFCareKitStore
import OTFCareKitUI
import Foundation
import XCTest

// Just testing access level
private class CustomSimpleContactViewSynchronizer: OCKSimpleContactViewSynchronizer {
    override func makeView() -> OCKSimpleContactView {
        return super.makeView()
    }

    override func updateView(_ view: OCKSimpleContactView, context: OCKSynchronizationContext<OCKAnyContact?>) {
        super.updateView(view, context: context)
    }
}

// Just testing access level
private class CustomDetailedContactViewSynchronizer: OCKDetailedContactViewSynchronizer {
    override func makeView() -> OCKDetailedContactView {
        return super.makeView()
    }

    override func updateView(_ view: OCKDetailedContactView, context: OCKSynchronizationContext<OCKAnyContact?>) {
        super.updateView(view, context: context)
    }
}

private class MockContactLabel: UILabel, OCKContactDisplayable {
    weak var delegate: OCKContactViewDelegate?
}

private class CustomContactViewSynchronizer: OCKContactViewSynchronizerProtocol {
    func makeView() -> MockContactLabel {
        return .init()
    }

    func updateView(_ view: MockContactLabel, context: OCKSynchronizationContext<OCKAnyContact?>) {
        view.text = context.viewModel?.title
    }
}

private extension OCKContact {
    static func mock() -> OCKContact {
        var contact = OCKContact(id: "lexi-torres", givenName: "Lexi", familyName: "Torres", carePlanUUID: nil)
        contact.title = "Family Practice"
        return contact
    }
}

class TestCustomContactViewSynchronizer: XCTestCase {

    private var viewSynchronizer: CustomContactViewSynchronizer!
    private var view: MockContactLabel!

    override func setUp() {
        super.setUp()
        viewSynchronizer = .init()
        view = viewSynchronizer.makeView()
    }

    // View should be cleared in the initial state
    func testInitialStateIsEmpty() {
        XCTAssertNil(view.text)
    }

    // View should fill with contact data
    func testDoesUpdate() {
        let contact = OCKContact.mock()
        viewSynchronizer.updateView(view, context: .init(viewModel: contact, oldViewModel: nil, animated: false))
        XCTAssertEqual(view.text, contact.title)
    }

    // View should be cleared after updating with a nil contact
    func testDoesClear() {
        let contact = OCKContact.mock()
        viewSynchronizer.updateView(view, context: .init(viewModel: contact, oldViewModel: nil, animated: false))
        XCTAssertNotNil(view.text)

        // Update with a nil contact
        viewSynchronizer.updateView(view, context: .init(viewModel: nil, oldViewModel: nil, animated: false))
        XCTAssertNil(view.text)
    }
}
