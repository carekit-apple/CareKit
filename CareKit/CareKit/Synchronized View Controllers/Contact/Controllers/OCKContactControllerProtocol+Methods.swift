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
import Contacts
import ContactsUI
import Foundation
import MapKit
import MessageUI

public extension OCKContactControllerProtocol {

    func initiateCall() throws -> URL {
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

    func initiateMessage() throws -> MFMessageComposeViewController {
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

    func initiateEmail() throws -> MFMailComposeViewController {
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

    func initiateAddressLookup(completion: @escaping (Result<MKMapItem, Error>) -> Void) {
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

    func initiateSystemContactLookup() throws -> CNContactViewController {
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

    // Remove non-numeric characters
    private func filteredDigits(for value: String) -> String {
        return value.filter("0123456789".contains)
    }

    private func validateContact() throws -> OCKAnyContact {
        guard let contact = objectWillChange.value else {
            throw OCKContactControllerError.nilContact
        }
        return contact
    }
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
