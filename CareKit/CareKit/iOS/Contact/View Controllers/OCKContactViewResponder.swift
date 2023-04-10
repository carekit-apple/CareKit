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

#if !os(watchOS)

import CareKitStore
import CareKitUI
import Contacts
import ContactsUI
import MessageUI
import UIKit

final class OCKContactViewResponder: NSObject,
    OCKContactViewDelegate,
    MFMessageComposeViewControllerDelegate,
    MFMailComposeViewControllerDelegate {

    private weak var presenter: UIViewController?

    private let contactForView: (UIView & OCKContactDisplayable) -> OCKAnyContact?

    init(
        presenter: UIViewController,
        contactForView: @escaping (UIView & OCKContactDisplayable) -> OCKAnyContact?
    ) {
        self.presenter = presenter
        self.contactForView = contactForView
    }

    func contactView(
        _ contactView: UIView & OCKContactDisplayable,
        senderDidInitiateCall sender: Any?
    ) {
        // Extract the phone number for the contact
        let contact = contactForView(contactView)
        guard let url = contact?.phoneCallURL() else {
            assertionFailure("Encountered an invalid phone number.")
            let logMsg: StaticString = "Encountered an invalid phone number for contact: %{private}@"
            log(.error, logMsg, args: String(describing: contact))
            return
        }

        // Initiate a phone call to the contact
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    func contactView(
        _ contactView: UIView & OCKContactDisplayable,
        senderDidInitiateEmail sender: Any?
    ) {
        // Extract the email address for the contact
        let contact = contactForView(contactView)
        guard let email = contact?.emailAddresses?.first?.value else {
            assertionFailure("Encountered an invalid email address.")
            let logMsg: StaticString = "Encountered an invalid email address for contact: %{private}@"
            log(.error, logMsg, args: String(describing: contact))
            return
        }

        // Ensure we can send emails
        guard MFMailComposeViewController.canSendMail() else {
            log(.error, "Unable to send emails.")
            return
        }

        // Initiate an email to the contact
        let mailViewController = MFMailComposeViewController()
        mailViewController.setToRecipients([email])
        mailViewController.mailComposeDelegate = self
        presenter?.present(mailViewController, animated: false)
    }

    func contactView(
        _ contactView: UIView & OCKContactDisplayable,
        senderDidInitiateMessage sender: Any?
    ) {
        // Extract the messaging number for the contact
        let contact = contactForView(contactView)
        guard let messagingNumber = contact?.cleanedMessagingNumber() else {
            assertionFailure("Encountered an invalid messaging number.")
            let logMsg: StaticString = "Encountered an invalid messaging number for contact: %{private}@"
            log(.error, logMsg, args: String(describing: contact))
            return
        }

        // Ensure we can send messages
        guard MFMessageComposeViewController.canSendText() else {
            log(.error, "Cannot send messages.")
            return
        }

        // Initiate a message to the contact
        let messageViewController = MFMessageComposeViewController()
        messageViewController.recipients = [messagingNumber]
        messageViewController.messageComposeDelegate = self
        presenter?.present(messageViewController, animated: true)
    }

    func contactView(
        _ contactView: UIView & OCKContactDisplayable,
        senderDidInitiateAddressLookup sender: Any?
    ) {
        // Extract the map pin for the contact
        let contact = contactForView(contactView)
        contact?.getAddressMapItem { item in
            guard let item = item else {
                assertionFailure("Could not locate contact on the map.")
                let logMsg: StaticString = "Could not locate contact on the map. %{private}@"
                log(.error, logMsg, args: String(describing: contact))
                return
            }

            // Open the address in maps
            item.openInMaps(launchOptions: nil)
        }
    }

    func didSelectContactView(_ contactView: UIView & OCKContactDisplayable) {
        guard let contact = contactForView(contactView) else { return }

        // Create the system contact view controller
        let mutableContact = CNMutableContact(from: contact)
        let contactViewController = CNContactViewController(forUnknownContact: mutableContact)
        contactViewController.contactStore = CNContactStore()
        contactViewController.allowsEditing = false
        contactViewController.view.backgroundColor = OCKStyle().color.customGroupedBackground

        // Wrap the contact view controller in a navigation controller
        contactViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissViewController)
        )
        
        /*
         TODO: Remove in the future. Explicitly setting the tint color here to support
         current developers that have a SwiftUI lifecycle app and wrap this view
         controller in a `UIViewControllerRepresentable` implementation...Tint color
         is not propagated...etc.
         */
        let tintColor = contactViewController.determineTintColor(from: contactView)
        contactViewController.view.tintColor = tintColor
        contactViewController.navigationController?.navigationBar.tintColor = tintColor
        
        let navigationController = UINavigationController(rootViewController: contactViewController)
        presenter?.present(navigationController, animated: true)
    }

    @objc
    private func dismissViewController() {
        presenter?.dismiss(animated: true, completion: nil)
    }

    // MARK: - MFMessageComposeViewControllerDelegate

    func messageComposeViewController(
        _ controller: MFMessageComposeViewController,
        didFinishWith result: MessageComposeResult
    ) {
        controller.dismiss(animated: true, completion: nil)
    }

    // MARK: - MFMailComposeViewControllerDelegate

    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(animated: true, completion: nil)
    }
}

#endif
