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
import Foundation
import MapKit

#if os(iOS)
import ContactsUI
import MessageUI
#endif

/// A basic controller capable of watching and updating contacts.
open class OCKContactController: ObservableObject {

    // MARK: - Properties

    /// The current contact. Subscribe to the projected value to be notified when the contact changes.
    @Published public final var contact: OCKAnyContact?

    /// The error encountered by the controller.
    @Published public internal(set) var error: Error?

    /// The store manager against which the contact will be synchronized.
    public let storeManager: OCKSynchronizedStoreManager

    private var cancellables: Set<AnyCancellable> = Set()

    // MARK: - Life Cycle

    /// Initialize with a store manager.
    public required init(storeManager: OCKSynchronizedStoreManager) {
        self.storeManager = storeManager
    }

    // MARK: - Synchronization

    /// Begin observing a contact.
    ///
    /// - Parameter contact: The contact to watch for changes.
    open func observeContact(_ contact: OCKAnyContact) {
        self.contact = contact

        // Set the view model when the contact changes
        storeManager.publisher(forContact: contact, categories: [.update, .add], fetchImmediately: false)
            .sink { [weak self] in self?.contact = $0 }
            .store(in: &cancellables)
    }

    /// Fetch and begin observing the first contact described by a query.
    ///
    /// - Parameters:
    ///   - query: Any contact query describing the contact to be fetched.
    ///
    /// - Note: If the query matches multiple contacts, the first one returned will be used.
    open func fetchAndObserveContact(forQuery query: OCKAnyContactQuery) {

        // Fetch the contact to set as the view model value
        storeManager.store.fetchAnyContacts(query: query, callbackQueue: .main) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                self.error = error
            case .success(let contacts):
                self.contact = contacts.first

                // Set the view model when the contact changes
                guard let id = self.contact?.id else { return }
                self.storeManager.publisher(forContactID: id, categories: [.update, .add]).sink { [weak self] newValue in
                    self?.contact = newValue
                }.store(in: &self.cancellables)
            }
        }
    }

    /// Fetch and begin observing the contact with the given identifier.
    ///
    /// - Parameters:
    ///   - id: The user-defined unique identifier for the contact.
    open func fetchAndObserveContact(withID id: String) {

        // Fetch the contact to set as the view model value
        storeManager.store.fetchAnyContact(withID: id, callbackQueue: .main) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                self.error = error
            case .success(let contact):
                self.contact = contact

                // Set the view model when the contact changes
                self.storeManager.publisher(forContactID: contact.id, categories: [.update, .add]).sink { [weak self] newValue in
                    self?.contact = newValue
                }.store(in: &self.cancellables)
            }
        }
    }

    // MARK: - Utilities

    /// Initiate a phone call for the current `contact`.
    /// - Throws: If the current contact has an invalid phone number.
    /// - Returns: A URL that that will navigate to the Phone app.
    open func initiateCall() throws -> URL {
        let contact = try validateContact()

        // Ensure the contact has a phone number to call
        guard let phoneNumber = contact.phoneNumbers?.first?.value else {
            throw OCKContactControllerError.invalidPhoneNumber(nil)
        }

        // Generate the URL to call the phone number
        let filteredNumber = filteredDigits(for: phoneNumber)
        guard let url = URL(string: "tel://" + filteredNumber) else {
            throw OCKContactControllerError.invalidPhoneNumber(phoneNumber)
        }
        return url
    }

    /// Lookup the address of the current `contact`.
    /// - Parameter completion: On success, the result will contain the `MKMapItem` for the contact's address. A failure will occur if the
    ///                         address is invalid.
    open func initiateAddressLookup(completion: @escaping (Result<MKMapItem, Error>) -> Void) {
        let contact: OCKAnyContact
        do {
            contact = try validateContact()
        } catch {
            completion(.failure(error))
            return
        }

        // Ensure the contact has an address
        guard let address = contact.address else {
            completion(.failure(OCKContactControllerError.invalidAddress(nil)))
            return
        }

        // Generate the map item that pinpoints the contact's address
        let geoloc = CLGeocoder()
        geoloc.geocodePostalAddress(address) { placemarks, _ in
            guard let placemark = placemarks?.first else {
                completion(.failure(OCKContactControllerError.invalidAddress(address)))
                return
            }
            let mkPlacemark = MKPlacemark(placemark: placemark)
            completion(.success(MKMapItem(placemark: mkPlacemark)))
        }
    }

    // Remove non-numeric characters
    private func filteredDigits(for value: String) -> String {
        return value.filter("0123456789".contains)
    }

    private func validateContact() throws -> OCKAnyContact {
        guard let contact = contact else {
            throw OCKContactControllerError.nilContact
        }
        return contact
    }

    #if os(iOS)

    /// Locate the current `contact` in the system contacts.
    /// - Throws: If the current `contact` is nil.
    /// - Returns: A view controller that displays the system contact.
    open func initiateSystemContactLookup() throws -> CNContactViewController {
        let contact = try validateContact()

        // Create a CNMutableContact from an OCKAnyContact
        let mutableContact = CNMutableContact(from: contact)

        // Create a view controller that displays the contact
        let contactViewController = CNContactViewController(forUnknownContact: mutableContact)
        contactViewController.contactStore = CNContactStore()
        contactViewController.allowsEditing = false
        contactViewController.view.backgroundColor = OCKStyle().color.customGroupedBackground
        return contactViewController
    }

    /// Initiate a message for the current `contact`.
    /// - Throws: If the contact's phone number is invalid, or messages cannot be sent.
    /// - Returns: The view controller in which a message can be sent.
    open func initiateMessage() throws -> MFMessageComposeViewController {
        let contact = try validateContact()

        // Ensure the contact has a phone number to message
        guard let messageNumber = contact.messagingNumbers?.first?.value else {
            throw OCKContactControllerError.invalidPhoneNumber(nil)
        }

        // Ensure we can send messages
        guard MFMessageComposeViewController.canSendText() else {
            throw OCKContactControllerError.cannotSendMessages
        }

        // Generate the message view controller
        let filteredNumber = filteredDigits(for: messageNumber)
        let composeViewController = MFMessageComposeViewController()
        composeViewController.recipients = [filteredNumber]
        return composeViewController
    }

    /// Initiate an email for the current `contact`.
    /// - Throws: If the contact's email is invalid, or mail cannot be sent.
    /// - Returns: The view controller in which the email can be sent.
    open func initiateEmail() throws -> MFMailComposeViewController {
        let contact = try validateContact()

        // Ensure the contact has an email
        guard let email = contact.emailAddresses?.first?.value else {
            throw OCKContactControllerError.invalidEmail(nil)
        }

        // Ensure we can send emails
        guard MFMailComposeViewController.canSendMail() else {
            throw OCKContactControllerError.cannotSendMail
        }

        // Generate the mail view controller
        let viewController = MFMailComposeViewController()
        viewController.setToRecipients([email])
        return viewController
    }

    #endif
}

private enum OCKContactControllerError: Error, LocalizedError {

    case nilContact
    case invalidAddress(_ address: OCKPostalAddress?)
    case invalidPhoneNumber(_ phoneNumber: String?)
    case invalidMessageNumber(_ messageNumber: String?)
    case invalidEmail(_ email: String?)
    case cannotSendMail
    case cannotSendMessages

    var errorDescription: String? {
        switch self {
        case .nilContact: return "Contact view model is nil"
        case .invalidAddress(let address): return "Invalid address: \(String(describing: address))"
        case .invalidPhoneNumber(let phoneNumber): return "Invalid phone number: \(String(describing: phoneNumber))"
        case .invalidMessageNumber(let messageNumber): return "Invalid message number: \(String(describing: messageNumber))"
        case .invalidEmail(let email): return "Invalid email: \(String(describing: email))"
        case .cannotSendMail: return "Cannot send mail"
        case .cannotSendMessages: return "Cannot send messages"
        }
    }
}
