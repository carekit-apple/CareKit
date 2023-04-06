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
import UIKit


/// Queries for and displays contacts in a store.
open class OCKContactsListViewController<
    ContactViewSynchronizer: ViewSynchronizing
>: SynchronizedViewController<_OCKContactsListViewSynchronizer<ContactViewSynchronizer>> where
    ContactViewSynchronizer.View: OCKContactDisplayable,
    ContactViewSynchronizer.ViewModel == OCKAnyContact?
{


    private lazy var responder = OCKContactViewResponder(
        presenter: self,
        contactForView: { [weak self] in
            guard let self = self else { return nil }
            return self.viewSynchronizer.contact(
                forView: $0,
                contacts: self.viewModel
            )
        }
    )

    @available(*, unavailable, message: "The storeManager is unavailable.")
    public var storeManager: OCKSynchronizedStoreManager!

    @available(*, unavailable, renamed: "init(store:contactViewSynchronizer:)")
    public init(storeManager: OCKSynchronizedStoreManager) {
        fatalError("Unavailable")
    }

    /// Queries for and displays contacts in a store.
    /// - Parameters:
    ///   - store: Contains the contact data that will be displayed.
    ///   - contactViewSynchronizer: Capable of creating and updating a contact view in the list.
    public init(
        store: OCKAnyStoreProtocol,
        contactViewSynchronizer: ContactViewSynchronizer
    ) {
        let query = OCKContactQuery(for: Date())
        let contacts = store.anyContacts(matching: query)

        super.init(
            initialViewModel: [],
            viewModels: contacts,
            viewSynchronizer: _OCKContactsListViewSynchronizer(contactViewSynchronizer: contactViewSynchronizer)
        )
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        viewSynchronizer.contactViewDelegate = responder
    }
}

public extension OCKContactsListViewController where ContactViewSynchronizer == OCKSimpleContactViewSynchronizer {

    /// Initialize using a store manager. All of the contacts in the store manager will be queried and dispalyed.
    ///
    /// - Parameters:
    ///   - storeManager: The store manager owning the store whose contacts should be displayed.
    @available(*, unavailable, renamed: "init(store:)")
    convenience init(storeManager: OCKSynchronizedStoreManager) {
        fatalError("Unavailable")
    }

    /// Queries for and displays contacts in a store. Displays simple contact views by default.
    /// - Parameters:
    ///   - storeManager: Contains the contact data that will be displayed.
    convenience init(store: OCKAnyStoreProtocol) {
        self.init(
            store: store,
            contactViewSynchronizer: OCKSimpleContactViewSynchronizer()
        )
    }
}

#endif
