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
@testable import CareKitStore
import Contacts
import XCTest

private class MockContactView: UIView, OCKContactDisplayable {
    weak var delegate: OCKContactViewDelegate?
    var contact: OCKContact?
}

private class MockContactViewController: OCKContactViewController<MockContactView, OCKStore> {
    override func makeView() -> MockContactView {
        return .init()
    }

    override func updateView(_ view: MockContactView, context: OCKSynchronizationContext<OCKContact>) {
        view.contact = context.viewModel
    }
}

class TestAbstractContactViewController: XCTestCase {
    private enum Constants {
        static let timeout: TimeInterval = 3
    }

    private var mockSynchronizationDelegate: MockSynchronizationDelegate<OCKContact>!
    private var mockContactDelegate: MockContactViewControllerDelegate!
    private var storeManager: OCKSynchronizedStoreManager<OCKStore>!
    private var contact: OCKContact!

    override func setUp() {
        super.setUp()
        UIView.setAnimationsEnabled(false)

        // add a new contact
        storeManager = OCKSynchronizedStoreManager(wrapping: OCKStore(name: "ckstore", type: .inMemory))
        let contact = makeContact()
        self.contact = try? storeManager.store.addContactAndWait(contact)
        XCTAssertNotNil(self.contact)
    }

    func makeContact() -> OCKContact {
        var contact = OCKContact(identifier: "lexi-torres", givenName: "Lexi", familyName: "Torres", carePlanID: nil)
        contact.role = "Dr. Torres is a family practice doctor with over 20 years of experience."
        return contact
    }

    private func makeViewController() -> MockContactViewController {
        let viewController = MockContactViewController(storeManager: storeManager, contactIdentifier: contact.identifier, query: nil)
        viewController.updatesViewWithDuplicates = false

        mockSynchronizationDelegate = .init()
        mockContactDelegate = .init()
        viewController.synchronizationDelegate = mockSynchronizationDelegate
        viewController.delegate = mockContactDelegate
        return viewController
    }

    func testInitWithIdentifier() {
        let viewController = makeViewController()
        let loadedExpectation = expectation(description: "Task was loaded")
        mockContactDelegate.didFinishQueryingCompletion = { [weak self] in
            guard let self = self else { return }
            self.validateInitialState(for: viewController.viewModel)
            loadedExpectation.fulfill()
        }
        viewController.loadViewIfNeeded()
        wait(for: [loadedExpectation], timeout: Constants.timeout)
    }

    func testInitialContact() {
        // Setup expectation to validate the view
        let viewController = makeViewController()
        let viewExpectation = expectation(description: "Validate view")
        mockSynchronizationDelegate.viewModelRecieved = { [weak self] newValue, version in
            guard let self = self else { return }
            switch version {
            case 1:
                self.validateInitialState(for: newValue)
                viewExpectation.fulfill()
            default:
                XCTFail("View updated more times than expected")
            }
        }

        // Load the view to initiate the subscription
        viewController.loadViewIfNeeded()
        wait(for: [viewExpectation], timeout: Constants.timeout)
    }

    func testUpdatedContact() {
        // Setup expectation to validate the view
        let viewController = makeViewController()
        let initialExpectation = expectation(description: "initial view")
        let updatedExpectation = expectation(description: "updated view")
        mockSynchronizationDelegate.viewModelRecieved = { [weak self] newValue, version in
            guard let self = self else { return }
            switch version {
            case 1:
               self.validateInitialState(for: newValue)
                XCTAssertNoThrow(try self.updateContact())  // update the contact to trigger an update to the view
                initialExpectation.fulfill()
            case 2:
                self.validateUpdatedContact(for: newValue)
                updatedExpectation.fulfill()
            default:
                XCTFail("View updated more times than expected")
            }
        }
        viewController.loadViewIfNeeded()
        wait(for: [initialExpectation, updatedExpectation], timeout: Constants.timeout)
    }

    func testDeletedContact() {
        // Setup expectation to validate the view
        let viewController = makeViewController()
        let initialExpectation = expectation(description: "initial view")
        let updatedExpectation = expectation(description: "updated view")
        mockSynchronizationDelegate.viewModelRecieved = { [weak self] newValue, version in
            guard let self = self else { return }
            switch version {
            case 1:
                self.validateInitialState(for: newValue)

                // update the contact to trigger an update to the view
                XCTAssertNoThrow(try self.storeManager.store.deleteContactAndWait(self.contact))
                initialExpectation.fulfill()
            case 2:
                self.validateDeletedContact(for: newValue)
                updatedExpectation.fulfill()
            default:
                XCTFail("View updated more times than expected")
            }
        }
        viewController.loadViewIfNeeded()
        wait(for: [initialExpectation, updatedExpectation], timeout: Constants.timeout)
    }

    private func updateContact() throws {
        var newContact: OCKContact! = contact
        newContact.role = "Cardiologist"
        try storeManager.store.updateContactAndWait(newContact)
    }

    private func validateInitialState(for viewModel: OCKStore.Contact?) {
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel?.identifier, contact.identifier)
    }

    // contact exists with a new role
    private func validateUpdatedContact(for viewModel: OCKStore.Contact?) {
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel?.identifier, contact.identifier)
        XCTAssertEqual(viewModel?.role, "Cardiologist")
    }

    private func validateDeletedContact(for viewModel: OCKStore.Contact?) {
        XCTAssertNil(viewModel)
    }
}
