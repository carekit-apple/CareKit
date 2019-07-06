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

import UIKit
import CareKitStore
import MessageUI
import Contacts
import MapKit

/// An `Error` subclass detailing errors specific to `OCKSimpleContactViewController`.
private enum OCKSimpleContactError: Error, LocalizedError {
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

open class OCKSimpleContactViewController<Store: OCKStoreProtocol>:
OCKContactViewController<Store>, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate {
    
    // MARK: Properties
    
    /// A view displaying the name and title of the contact. By default, `detailPresentingView` returns an `OCKHeaderView`.
    override var detailPresentingView: UIView? {
        return contactView.headerView
    }
    
    /// The view that the contact is displayed in.
    public var contactView: OCKSimpleContactView {
        guard let view = view as? OCKSimpleContactView else { fatalError("Unexpected class") }
        return view
    }
    
    // MARK: Initializers
    
    /// Initialize with a contact.
    ///
    /// - Parameters:
    ///   - storeManager: A store manager that will be used to provide synchronization.
    ///   - contact: The contact to be displayed in an `OCKSimpleContactView`.
    public init(storeManager: OCKSynchronizedStoreManager<Store>, contact: Store.Contact) {
        super.init(storeManager: storeManager, contact: contact, loadDefaultView: { OCKBindableSimpleContactView<Store.Contact>() })
    }
    
    /// Initialize with a contact identifier. The contact will be fetched from the store automatically.
    ///
    /// - Parameters:
    ///   - storeManager: A store manager that will be used to provide synchronization.
    ///   - contactIdentifier: The identifier of the contact which should be fetched and displayed.
    public init(storeManager: OCKSynchronizedStoreManager<Store>, contactIdentifier: String) {
        super.init(storeManager: storeManager, contactIdentifier: contactIdentifier,
                   loadDefaultView: { OCKBindableSimpleContactView<Store.Contact>() })
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Life cycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        contactView.emailButton.addTarget(self, action: #selector(emailPressed), for: .touchUpInside)
        contactView.messageButton.addTarget(self, action: #selector(messagesPressed), for: .touchUpInside)
        contactView.callButton.addTarget(self, action: #selector(callPressed), for: .touchUpInside)
        contactView.addressButton.addTarget(self, action: #selector(directionsPressed), for: .touchUpInside)
    }
    
    // MARK: Methods
    
    @objc
    private func callPressed() {
        guard let phoneNumber = contact?.convert().phoneNumbers?.first?.value else { return }
        let filteredNumber = phoneNumber.filter("0123456789".contains)  // remove non-numeric characters to provide to calling API
        guard let url = URL(string: "tel://" + filteredNumber) else {
            delegate?.contactViewController(self, didFailWithError: OCKSimpleContactError.invalidPhoneNumber(number: phoneNumber))
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    @objc
    private func directionsPressed() {
        guard let address = contact?.convert().address else { return }
        
        let geoloc = CLGeocoder()
        geoloc.geocodePostalAddress(address) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            guard let p = placemarks?.first else {
                self.delegate?.contactViewController(self, didFailWithError: OCKSimpleContactError.invalidAddress)
                return
            }
            
            let mkPlacemark = MKPlacemark(placemark: p)
            let mapItem = MKMapItem(placemark: mkPlacemark)
            mapItem.openInMaps(launchOptions: nil)
        }
    }
    
    @objc
    private func emailPressed() {
        guard let firstEmail = contact?.convert().emailAddresses?.first?.value else { return }
        guard MFMailComposeViewController.canSendMail() else {
            self.delegate?.contactViewController(self, didFailWithError: OCKSimpleContactError.cannotSendMail)
            return
        }
        
        let mailViewController = MFMailComposeViewController()
        mailViewController.mailComposeDelegate = self
        mailViewController.setToRecipients([firstEmail])
        self.present(mailViewController, animated: true, completion: nil)
    }
    
    @objc
    private func messagesPressed() {
        guard let messagesNumber = contact?.convert().messagingNumbers?.first?.value else { return }
        guard MFMessageComposeViewController.canSendText() else {
            self.delegate?.contactViewController(self, didFailWithError: OCKSimpleContactError.cannotSendMessage)
            return
        }
        
        let filteredNumber = messagesNumber.filter("0123456789".contains)           // remove non-numeric characters to provide to message API
        let composeViewController = MFMessageComposeViewController()
        composeViewController.messageComposeDelegate = self
        composeViewController.recipients = [filteredNumber]
        self.present(composeViewController, animated: true, completion: nil)
    }
    
    // MARK: MFMessageComposeViewControllerDelegate
    
    public func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    // MARK: MFMailComposeViewControllerDelegate
    
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
