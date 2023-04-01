/*
 Copyright (c) 2021, Apple Inc. All rights reserved.
 
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
import CareKitStore
import CareKitUI
import Foundation
import XCTest

class TestContactListViewSynchronizer: XCTestCase {

    func testUpdateView_EmptyList() {
        let contactViewSynchronizer = OCKSimpleContactViewSynchronizer()
        let listSynchronizer = _OCKContactsListViewSynchronizer(
            contactViewSynchronizer: contactViewSynchronizer
        )

        let context = OCKSynchronizationContext<[OCKAnyContact]>(viewModel: [], oldViewModel: [], animated: false)
        let view = listSynchronizer.makeView()
        listSynchronizer.updateView(view, context: context)

        let observedContactViewCount = (view as? OCKListView)?.stackView.arrangedSubviews.count
        XCTAssertEqual(observedContactViewCount, 0)
    }

    func testUpdateView_NonEmptyList() {
        let contactViewSynchronizer = OCKSimpleContactViewSynchronizer()
        let listSynchronizer = _OCKContactsListViewSynchronizer(
            contactViewSynchronizer: contactViewSynchronizer
        )

        let contacts = Array(repeating: OCKContact.sample(), count: 10)
        let context = OCKSynchronizationContext<[OCKAnyContact]>(viewModel: contacts, oldViewModel: [], animated: false)
        let view = listSynchronizer.makeView()
        listSynchronizer.updateView(view, context: context)

        let observedContactViewCount = (view as? OCKListView)?.stackView.arrangedSubviews.count
        XCTAssertEqual(observedContactViewCount, 10)
    }

    func testUpdateView_TrimsExtraContactViews() {
        let contactViewSynchronizer = OCKSimpleContactViewSynchronizer()
        let listSynchronizer = _OCKContactsListViewSynchronizer(
            contactViewSynchronizer: contactViewSynchronizer
        )

        let firstContacts = Array(repeating: OCKContact.sample(), count: 5)
        let secondContacts = Array(firstContacts.prefix(3))
        let firstContext = OCKSynchronizationContext<[OCKAnyContact]>(viewModel: firstContacts, oldViewModel: [], animated: false)
        let secondContext = OCKSynchronizationContext<[OCKAnyContact]>(viewModel: secondContacts, oldViewModel: firstContacts, animated: false)
        let view = listSynchronizer.makeView()
        listSynchronizer.updateView(view, context: firstContext)
        listSynchronizer.updateView(view, context: secondContext)

        let observedContactViewCount = (view as? OCKListView)?.stackView.arrangedSubviews.count
        XCTAssertEqual(observedContactViewCount, 3)
    }

    func testUpdateView_AddsExtraContactViews() {
        let contactViewSynchronizer = OCKSimpleContactViewSynchronizer()
        let listSynchronizer = _OCKContactsListViewSynchronizer(
            contactViewSynchronizer: contactViewSynchronizer
        )

        let firstContacts = Array(repeating: OCKContact.sample(), count: 3)
        let secondContacts = Array(repeating: OCKContact.sample(), count: 5)
        let firstContext = OCKSynchronizationContext<[OCKAnyContact]>(viewModel: firstContacts, oldViewModel: [], animated: false)
        let secondContext = OCKSynchronizationContext<[OCKAnyContact]>(viewModel: secondContacts, oldViewModel: firstContacts, animated: false)
        let view = listSynchronizer.makeView()
        listSynchronizer.updateView(view, context: firstContext)
        listSynchronizer.updateView(view, context: secondContext)

        let observedContactViewCount = (view as? OCKListView)?.stackView.arrangedSubviews.count
        XCTAssertEqual(observedContactViewCount, 5)
    }

    func testUpdateView_UpdatesViews() {
        let didUpdateViews = XCTestExpectation(description: "Did update views")
        didUpdateViews.expectedFulfillmentCount = 10

        let contactViewSynchronizer = MockViewSynchronizer {
            didUpdateViews.fulfill()
        }

        let listSynchronizer = _OCKContactsListViewSynchronizer(
            contactViewSynchronizer: contactViewSynchronizer
        )

        let contacts = Array(repeating: OCKContact.sample(), count: 10)
        let context = OCKSynchronizationContext<[OCKAnyContact]>(viewModel: contacts, oldViewModel: [], animated: false)
        let view = listSynchronizer.makeView()
        listSynchronizer.updateView(view, context: context)

        wait(for: [didUpdateViews], timeout: 2)
    }

    func testUpdateView_DoesNotUpdateViewsWhenContactsDoNotChange() {
        let didUpdateViews = XCTestExpectation(description: "Did update views")
        didUpdateViews.expectedFulfillmentCount = 10

        let contactViewSynchronizer = MockViewSynchronizer {
            didUpdateViews.fulfill()
        }

        let listSynchronizer = _OCKContactsListViewSynchronizer(
            contactViewSynchronizer: contactViewSynchronizer
        )

        let contacts = Array(repeating: OCKContact.sample(), count: 10)
        let firstContext = OCKSynchronizationContext<[OCKAnyContact]>(viewModel: contacts, oldViewModel: [], animated: false)
        let secondContext = OCKSynchronizationContext<[OCKAnyContact]>(viewModel: contacts, oldViewModel: contacts, animated: false)
        let view = listSynchronizer.makeView()
        listSynchronizer.updateView(view, context: firstContext)
        listSynchronizer.updateView(view, context: secondContext)

        wait(for: [didUpdateViews], timeout: 2)
    }

    func testUpdateView_PropertiesOnViewAreSet() {
        let contactViewSynchronizer = OCKSimpleContactViewSynchronizer()
        let delegate = OCKContactViewResponder(
            presenter: UIViewController(),
            contactForView: { _ in nil }
        )

        let listSynchronizer = _OCKContactsListViewSynchronizer(
            contactViewSynchronizer: contactViewSynchronizer
        )
        listSynchronizer.contactViewDelegate = delegate

        let contacts = Array(repeating: OCKContact.sample(), count: 10)
        let context = OCKSynchronizationContext<[OCKAnyContact]>(viewModel: contacts, oldViewModel: [], animated: false)
        let view = listSynchronizer.makeView()
        listSynchronizer.updateView(view, context: context)

        let contactViews = (view as? OCKListView)?.stackView.arrangedSubviews
        XCTAssertNotNil(contactViews)
        contactViews?.enumerated().forEach { index, contactView in
            let typedContactView = contactView as? OCKSimpleContactView
            XCTAssertTrue(typedContactView?.delegate === delegate)
            XCTAssertEqual(contactView.tag, index)
        }
    }
}

private extension OCKContact {

    static func sample() -> OCKAnyContact {
        return OCKContact(id: "", name: PersonNameComponents(), carePlanUUID: nil)
    }
}

private class MockViewSynchronizer: ViewSynchronizing {

    private let didUpdateView: () -> Void

    init(didUpdateView: @escaping () -> Void) {
        self.didUpdateView = didUpdateView
    }

    func makeView() -> OCKSimpleContactView {
        return OCKSimpleContactView()
    }

    func updateView(
        _ view: OCKSimpleContactView,
        context: OCKSynchronizationContext<OCKAnyContact?>
    ) {
        didUpdateView()
    }
}
