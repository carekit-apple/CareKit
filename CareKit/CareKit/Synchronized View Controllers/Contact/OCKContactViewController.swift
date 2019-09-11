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

import CareKitStore
import CareKitUI
import Combine
import Contacts
import ContactsUI
import MapKit
import MessageUI
import UIKit

/// A superclass to all view controllers that are synchronized with a contact. Actions in the view sent through the
/// `OCKContactViewDelegate` protocol will be automatically hooked up to controller logic.
///
/// Alternatively, subclass and use your custom view by specializing the `View` generic and overriding the `makeView()` method. Override the
/// `updateView(view:context)` method to hook up the contact to the view. This method will be called any time the contact is added, updated, or
/// deleted.
open class OCKContactViewController<View: UIView & OCKContactDisplayable, Store: OCKStoreProtocol>:
OCKSynchronizedViewController<View, Store.Contact>,
OCKContactDisplayer, OCKContactViewDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate {
    /// An `Error` subclass detailing errors specific to a contact.
    private enum ContactError: Error, LocalizedError {
        case invalidAddress
        /// `number` is the invalid phone number in context.
        case invalidPhoneNumber(number: String)
        case cannotSendMessage
        case cannotSendMail

        var errorDescription: String? {
            switch self {
            case .invalidAddress: return "Invalid address"
            case .invalidPhoneNumber(let number): return "Invalid number: \(number)"
            case .cannotSendMessage: return "Unable to compose a message"
            case .cannotSendMail: return "Unable to compose an email"
            }
        }
    }

    // MARK: - Properties

    /// The view displayed by this view controller.
    public var contactView: UIView & OCKContactDisplayable { synchronizedView }

    /// The store manager used to provide synchronization.
    public let storeManager: OCKSynchronizedStoreManager<Store>

    /// If set, the delegate will receive callbacks when important events happen.
    public weak var delegate: OCKContactViewControllerDelegate?

    private let query: OCKContactQuery?
    private let contactIdentifier: String

    // MARK: - Initializers

    /// Create a view controller with a contact to display.
    /// - Parameter storeManager: A store manager that will be used to provide synchronization.
    /// - Parameter contact: Contact to use as the view model.
    init(storeManager: OCKSynchronizedStoreManager<Store>, contact: Store.Contact) {
        self.storeManager = storeManager
        query = nil
        contactIdentifier = contact.identifier
        super.init()
        setViewModel(contact, animated: false)
    }

    /// Create a view controller by querying for a contact to display.
    /// - Parameter storeManager: A store manager that will be used to provide synchronization.
    /// - Parameter contactIdentifier: The identifier of the contact for which to query.
    /// - Parameter query: The query used to find the contact.
    init(storeManager: OCKSynchronizedStoreManager<Store>, contactIdentifier: String, query: OCKContactQuery?) {
        self.storeManager = storeManager
        self.contactIdentifier = contactIdentifier
        self.query = query
        super.init()
    }

    // MARK: - Life cycle

    override open func viewDidLoad() {
        super.viewDidLoad()
        contactView.delegate = self
        if viewModel == nil {
            fetchContact(withIdentifier: contactIdentifier, query: query)
        }
    }

    // MARK: - Methods

    private func fetchContact(withIdentifier id: String, query: OCKContactQuery?) {
        let anchor = OCKContactAnchor.contactIdentifier([id])
        storeManager.store.fetchContacts(anchor, query: query, queue: .main) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let contacts):
                self.setViewModel(contacts.first, animated: self.viewModel != nil)
                self.subscribe()
                self.delegate?.contactViewController(self, didFinishQuerying: self.viewModel)
            case .failure(let error):
                self.delegate?.contactViewController(self, didFailWithError: error)
            }
        }
    }

    /// Subscribe to update and delete notifications for the contact.
    override open func makeSubscription() -> AnyCancellable? {
        guard let contact = viewModel else { return nil }
        let changedSubscription = storeManager.publisher(forContact: contact, categories: [.update]).sink { [weak self] updatedContact in
            guard let self = self else { return }
            self.setViewModel(updatedContact, animated: self.viewModel != nil)
        }

        let deletedSubscription = storeManager.publisher(forContact: contact, categories: [.delete], fetchImmediately: false)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.setViewModel(nil, animated: self.viewModel != nil)
            }

        return AnyCancellable {
            changedSubscription.cancel()
            deletedSubscription.cancel()
        }
    }

    // MARK: - OCKContactViewDelegate

    /// Present an alert to call the contact. By default, calls the first phone number in the contact's list of phone numbers.
    /// - Parameter contactView: The view that displays the contact.
    /// - Parameter sender: The sender that is initiating the call process.
    open func contactView(_ contactView: UIView & OCKContactDisplayable, senderDidInitiateCall sender: Any?) {
        guard let phoneNumber = viewModel?.convert().phoneNumbers?.first?.value else { return }
        let filteredNumber = phoneNumber.filter("0123456789".contains)  // remove non-numeric characters to provide to calling API
        guard let url = URL(string: "tel://" + filteredNumber) else {
            delegate?.contactViewController(self, didFailWithError: ContactError.invalidPhoneNumber(number: phoneNumber))
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    /// Present the UI to message the contact. By default, the first messaging number will be used.
    /// - Parameter contactView: The view that displays the contact.
    /// - Parameter sender: The sender that is initiating the messaging process.
    open func contactView(_ contactView: UIView & OCKContactDisplayable, senderDidInitiateMessage sender: Any?) {
        guard let messagesNumber = viewModel?.convert().messagingNumbers?.first?.value else { return }
        guard MFMessageComposeViewController.canSendText() else {
            self.delegate?.contactViewController(self, didFailWithError: ContactError.cannotSendMessage)
            return
        }

        let filteredNumber = messagesNumber.filter("0123456789".contains)  // remove non-numeric characters to provide to message API
        let composeViewController = MFMessageComposeViewController()
        composeViewController.messageComposeDelegate = self
        composeViewController.recipients = [filteredNumber]
        self.present(composeViewController, animated: true, completion: nil)
    }

    /// Present the UI to email the contact. By default, the first email address will be used.
    /// - Parameter contactView: The view that displays the contact.
    /// - Parameter sender: The sender that is initiating the email process.
    open func contactView(_ contactView: UIView & OCKContactDisplayable, senderDidInitiateEmail sender: Any?) {
        guard let firstEmail = viewModel?.convert().emailAddresses?.first?.value else { return }
        guard MFMailComposeViewController.canSendMail() else {
            self.delegate?.contactViewController(self, didFailWithError: ContactError.cannotSendMail)
            return
        }

        let mailViewController = MFMailComposeViewController()
        mailViewController.mailComposeDelegate = self
        mailViewController.setToRecipients([firstEmail])
        self.present(mailViewController, animated: true, completion: nil)
    }

    /// Present a map with a marker on the contact's address.
    /// - Parameter contactView: The view that displays the contact.
    /// - Parameter sender: The sender that is initiating the address lookup process.
    open func contactView(_ contactView: UIView & OCKContactDisplayable, senderDidInitiateAddressLookup sender: Any?) {
        guard let address = viewModel?.convert().address else { return }

        let geoloc = CLGeocoder()
        geoloc.geocodePostalAddress(address) { [weak self] placemarks, _ in
            guard let self = self else { return }
            guard let placemark = placemarks?.first else {
                self.delegate?.contactViewController(self, didFailWithError: ContactError.invalidAddress)
                return
            }

            let mkPlacemark = MKPlacemark(placemark: placemark)
            let mapItem = MKMapItem(placemark: mkPlacemark)
            mapItem.openInMaps(launchOptions: nil)
        }
    }

    open func didSelectContactView(_ contactView: UIView & OCKContactDisplayable) { }

    // MARK: - MFMessageComposeViewControllerDelegate

    open func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }

    // MARK: - MFMailComposeViewControllerDelegate

    open func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
