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
import UIKit

/// View controller that is synchronized with a contact. Shows an `OCKDetailedContactView` and handles user interactions automatically.
open class OCKDetailedContactViewController<Store: OCKStoreProtocol>: OCKContactViewController<OCKDetailedContactView, Store> {
    // MARK: Properties

    /// The type of view being displayed.
    public typealias View = OCKDetailedContactView

    // MARK: Life Cycle

    /// Create a view controller with a contact to display.
    /// - Parameter storeManager: A store manager that will be used to provide synchronization.
    /// - Parameter contact: Contact to use as the view model.
    override public init(storeManager: OCKSynchronizedStoreManager<Store>, contact: Store.Contact) {
        super.init(storeManager: storeManager, contact: contact)
    }

    /// Create a view controller by querying for a contact to display.
    /// - Parameter storeManager: A store manager that will be used to provide synchronization.
    /// - Parameter contactIdentifier: The identifier of the contact for which to query.
    /// - Parameter query: The query used to find the contact.
    override public init(storeManager: OCKSynchronizedStoreManager<Store>, contactIdentifier: String, query: OCKContactQuery?) {
        super.init(storeManager: storeManager, contactIdentifier: contactIdentifier, query: query)
    }

    // MARK: Methods

    /// Update the view whenever the view model changes.
    /// - Parameter view: The view to update.
    /// - Parameter context: The data associated with the updated state.
    override open func updateView(_ view: OCKDetailedContactView, context: OCKSynchronizationContext<Store.Contact>) {
        let contact = context.viewModel?.convert()
        view.headerView.titleLabel.text = OCKContactUtility.string(from: contact?.name)
        view.headerView.detailLabel.text = contact?.title
        view.instructionsLabel.text = contact?.role
        view.headerView.iconImageView?.image = OCKContactUtility.image(from: contact?.asset) ?? OCKDetailedContactView.defaultImage

        // check we have have contact info needed for phone,
        // message, and email buttons to unhide them
        view.addressButton.isHidden = contact?.address == nil
        view.callButton.isHidden = contact?.phoneNumbers?.isEmpty ?? true
        view.emailButton.isHidden = contact?.emailAddresses?.isEmpty ?? true
        view.messageButton.isHidden = contact?.messagingNumbers?.isEmpty ?? true

        view.addressButton.setDetail(OCKContactUtility.string(from: contact?.address), for: .normal)
    }

    /// Create an instance of the view to be displayed.
    override open func makeView() -> OCKDetailedContactView {
        return .init()
    }
}
