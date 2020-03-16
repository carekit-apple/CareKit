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
import Contacts
import Foundation
import XCTest

private extension OCKContact {
    static func mock() -> OCKContact {
        var contact = OCKContact(id: "lexi-torres", givenName: "Lexi", familyName: "Torres", carePlanID: nil)
        contact.role = "Dr. Torres is a family practice doctor with over 20 years of experience."
        let phoneNumbers = [OCKLabeledValue(label: "work", value: "2135558479")]
        contact.phoneNumbers = phoneNumbers
        contact.title = "Family Practice"
        contact.messagingNumbers = phoneNumbers
        contact.emailAddresses = [OCKLabeledValue(label: "work", value: "lexitorres@icloud.com")]
        let address = OCKPostalAddress()
        address.street = "26 E Centerline Rd"
        address.city = "Victor"
        address.state = "MI"
        address.postalCode = "48848"
        contact.address = address
        return contact
    }
}

class TestDetailedContactViewSynchronizer: XCTestCase {

    let nameFormatter: PersonNameComponentsFormatter = {
        let nameFormatter = PersonNameComponentsFormatter()
        nameFormatter.style = .medium
        return nameFormatter
    }()

    let addressFormatter: CNPostalAddressFormatter = {
        let formatter = CNPostalAddressFormatter()
        formatter.style = .mailingAddress
        return formatter
    }()

    var viewSynchronizer: OCKDetailedContactViewSynchronizer!
    var view: OCKDetailedContactView!

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
        XCTAssertNil(view.instructionsLabel.text)
        XCTAssertNil(view.addressButton.detailLabel.text)
        XCTAssertFalse(view.addressButton.isHidden)
        XCTAssertFalse(view.callButton.isHidden)
        XCTAssertFalse(view.emailButton.isHidden)
        XCTAssertFalse(view.messageButton.isHidden)
    }

    // View should fill with contact data
    func testDoesUpdate() {
        let contact = OCKContact.mock()
        viewSynchronizer.updateView(view, context: .init(viewModel: contact, oldViewModel: nil, animated: false))
        XCTAssertEqual(view.headerView.titleLabel.text, nameFormatter.string(from: contact.name))
        XCTAssertEqual(view.headerView.detailLabel.text, contact.title)
        XCTAssertEqual(view.headerView.iconImageView?.image, UIImage(systemName: "person.crop.circle"))
        XCTAssertEqual(view.instructionsLabel.text, contact.role)
        XCTAssertEqual(view.addressButton.detailLabel.text, addressFormatter.string(from: contact.address!))
        XCTAssertFalse(view.addressButton.isHidden)
        XCTAssertFalse(view.callButton.isHidden)
        XCTAssertFalse(view.emailButton.isHidden)
        XCTAssertFalse(view.messageButton.isHidden)
    }

    // Contact button should hide when the corresponding data is missing
    func testHidesContactButtons() {
        var contact = OCKContact.mock()

        contact.address = nil
        viewSynchronizer.updateView(view, context: .init(viewModel: contact, oldViewModel: nil, animated: false))
        XCTAssertTrue(view.addressButton.isHidden)
        XCTAssertFalse(view.callButton.isHidden)
        XCTAssertFalse(view.emailButton.isHidden)
        XCTAssertFalse(view.messageButton.isHidden)

        contact.messagingNumbers = nil
        viewSynchronizer.updateView(view, context: .init(viewModel: contact, oldViewModel: nil, animated: false))
        XCTAssertTrue(view.addressButton.isHidden)
        XCTAssertFalse(view.callButton.isHidden)
        XCTAssertFalse(view.emailButton.isHidden)
        XCTAssertTrue(view.messageButton.isHidden)

        contact.phoneNumbers = nil
        viewSynchronizer.updateView(view, context: .init(viewModel: contact, oldViewModel: nil, animated: false))
        XCTAssertTrue(view.addressButton.isHidden)
        XCTAssertTrue(view.callButton.isHidden)
        XCTAssertFalse(view.emailButton.isHidden)
        XCTAssertTrue(view.messageButton.isHidden)

        contact.emailAddresses = nil
        viewSynchronizer.updateView(view, context: .init(viewModel: contact, oldViewModel: nil, animated: false))
        XCTAssertTrue(view.addressButton.isHidden)
        XCTAssertTrue(view.callButton.isHidden)
        XCTAssertTrue(view.emailButton.isHidden)
        XCTAssertTrue(view.messageButton.isHidden)
    }

    // View should be cleared after updating with a nil contact
    func testDoesClear() {
        let contact = OCKContact.mock()
        viewSynchronizer.updateView(view, context: .init(viewModel: contact, oldViewModel: nil, animated: false))
        XCTAssertNotNil(view.headerView.titleLabel.text)
        XCTAssertNotNil(view.headerView.detailLabel.text)
        XCTAssertEqual(view.headerView.iconImageView?.image, UIImage(systemName: "person.crop.circle"))
        XCTAssertNotNil(view.instructionsLabel.text)
        XCTAssertNotNil(view.addressButton.detailLabel.text)
        XCTAssertFalse(view.addressButton.isHidden)
        XCTAssertFalse(view.callButton.isHidden)
        XCTAssertFalse(view.emailButton.isHidden)
        XCTAssertFalse(view.messageButton.isHidden)

        // Update with a nil contact
        viewSynchronizer.updateView(view, context: .init(viewModel: nil, oldViewModel: nil, animated: false))
        XCTAssertNil(view.headerView.titleLabel.text)
        XCTAssertNil(view.headerView.detailLabel.text)
        XCTAssertEqual(view.headerView.iconImageView?.image, UIImage(systemName: "questionmark.circle.fill"))
        XCTAssertNil(view.instructionsLabel.text)
        XCTAssertNil(view.addressButton.detailLabel.text)
        XCTAssertTrue(view.addressButton.isHidden)
        XCTAssertTrue(view.callButton.isHidden)
        XCTAssertTrue(view.emailButton.isHidden)
        XCTAssertTrue(view.messageButton.isHidden)
    }
}
