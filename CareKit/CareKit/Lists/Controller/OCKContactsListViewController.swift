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
import Foundation

/// Classes that conform to this protocol can recieve updates about the state of
/// the `OCKContactsListViewControllerDelegate`.
public protocol OCKContactsListViewControllerDelegate: AnyObject {
    func contactsListViewController(_ viewController: OCKContactsListViewController, didEncounterError: Error)
}

/// An `OCKListViewController` that automatically queries and displays contacts in the `Store` using
/// `OCKDetailedContactViewController`s.
open class OCKContactsListViewController: OCKListViewController {

    // MARK: Properties

    /// The manager of the `Store` from which the `Contact` data is fetched.
    public let storeManager: OCKSynchronizedStoreManager

    /// If set, the delegate will receive callbacks when important events happen at the list view controller level.
    public weak var delegate: OCKContactsListViewControllerDelegate?

    /// If set, the delegate will receive callbacks when important events happen inside the contact view controllers.
    public weak var contactDelegate: OCKContactViewControllerDelegate?

    private var subscription: Cancellable?

    // MARK: - Life Cycle

    /// Initialize using a store manager. All of the contacts in the store manager will be queried and dispalyed.
    ///
    /// - Parameters:
    ///   - storeManager: The store manager owning the store whose contacts should be displayed.
    public init(storeManager: OCKSynchronizedStoreManager) {
        self.storeManager = storeManager
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        title = loc("CONTACTS")
        subscribe()
        fetchContacts()
    }

    // MARK: - Methods

    private func subscribe() {
        subscription?.cancel()
        subscription = storeManager.contactsPublisher(categories: [.add, .update]).sink { _ in
            self.fetchContacts()
        }
    }

    /// `fetchContacts` asynchronously retrieves an array of contacts stored in a `Result`
    /// and makes corresponding `OCKDetailedContactViewController`s.
    private func fetchContacts() {
        storeManager.store.fetchAnyContacts(query: OCKContactQuery(), callbackQueue: .main) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                self.delegate?.contactsListViewController(self, didEncounterError: error)
            case .success(let contacts):
                self.clear()
                for contact in contacts {
                    let contactViewController = OCKDetailedContactViewController(contact: contact, storeManager: self.storeManager)
                    contactViewController.delegate = self.contactDelegate
                    self.appendViewController(contactViewController, animated: false)
                }
            }
        }
    }
}
