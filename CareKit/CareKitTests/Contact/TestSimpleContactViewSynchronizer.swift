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

#if !os(watchOS) && !os(macOS) && !os(visionOS)
import CareKit
import CareKitStore
import CareKitUI
import Foundation
import XCTest

private extension OCKContact {
    static func mock() -> OCKContact {
        var contact = OCKContact(id: "lexi-torres", givenName: "Lexi", familyName: "Torres", carePlanUUID: nil)
        contact.title = "Family Practice"
        return contact
    }
}

class TestSimpleContactViewSynchronizer: XCTestCase {

    let nameFormatter: PersonNameComponentsFormatter = {
        let nameFormatter = PersonNameComponentsFormatter()
        nameFormatter.style = .medium
        return nameFormatter
    }()

    var viewSynchronizer: OCKSimpleContactViewSynchronizer!
    var view: OCKSimpleContactView!

    override func setUp() {
        super.setUp()
        viewSynchronizer = .init()
        view = viewSynchronizer.makeView()
    }

    // View should be cleared in the initial state
    func testInitialStateIsEmpty() {
        XCTAssertNil(view.headerView.titleLabel.text)
        XCTAssertNil(view.headerView.detailLabel.text)
        XCTAssertEqual(view.headerView.iconImageView?.image, UIImage(systemName: "person.crop.circle"))
    }

    // View should fill with contact data
    func testDoesUpdate() {
        let contact = OCKContact.mock()
        viewSynchronizer.updateView(view, context: .init(viewModel: contact, oldViewModel: nil, animated: false))
        XCTAssertEqual(view.headerView.titleLabel.text, nameFormatter.string(from: contact.name))
        XCTAssertEqual(view.headerView.detailLabel.text, contact.title)
        XCTAssertEqual(view.headerView.iconImageView?.image, UIImage(systemName: "person.crop.circle"))
    }

    // View should be cleared after updating with a nil contact
    func testDoesClear() {
        let contact = OCKContact.mock()
        viewSynchronizer.updateView(view, context: .init(viewModel: contact, oldViewModel: nil, animated: false))
        XCTAssertNotNil(view.headerView.titleLabel.text)
        XCTAssertNotNil(view.headerView.detailLabel.text)
        XCTAssertNotNil(view.headerView.iconImageView)

        // Update with a nil contact
        viewSynchronizer.updateView(view, context: .init(viewModel: nil, oldViewModel: nil, animated: false))
        XCTAssertNil(view.headerView.titleLabel.text)
        XCTAssertNil(view.headerView.detailLabel.text)
        XCTAssertEqual(view.headerView.iconImageView?.image, UIImage(systemName: "person.crop.circle"))
    }
}
#endif
