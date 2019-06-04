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
import Combine
import CareKitStore

/// Conform to receive callbacks when important events happen in an `OCKContactViewController`.
public protocol OCKContactViewControllerDelegate: class {
    
    /// Called when a contact view controller is tapped by the user.
    /// - Parameter contactViewController: The contact view controller which was tapped.
    func didSelect<Store: OCKStoreProtocol>(contactViewController: OCKContactViewController<Store>)
    
    /// Called when an unhandled error is encounted in a contact view controller.
    /// - Parameter contactViewController: The view controller in which the error occurred.
    /// - Parameter error: The error that occurred.
    func contactViewController<Store: OCKStoreProtocol>(_ contactViewController: OCKContactViewController<Store>,
                                                        didFailWithError error: Error)
    
    /// Called when a contact view controller finishes a query used to populate its contents.
    /// - Parameter contactViewController: The contact view controller which completed its query.
    /// - Parameter contact: The contact that was queried.
    func contactViewController<Store: OCKStoreProtocol>(_ contactViewController: OCKContactViewController<Store>,
                                                        didFinishQuerying contact: Store.Contact?)
}

public extension OCKContactViewControllerDelegate {
    func didSelect<Store: OCKStoreProtocol>(contactViewController: OCKContactViewController<Store>) {}
    
    func contactViewController<Store: OCKStoreProtocol>(_ contactViewController: OCKContactViewController<Store>,
                                                        didFailWithError error: Error) {}
    
    func contactViewController<Store: OCKStoreProtocol>(_ contactViewController: OCKContactViewController<Store>,
                                                        didFinishQuerying contact: Store.Contact?) {}
}

/// An abstract superclass to all synchronized view controllers that display a contact.
/// It has a factory function that can be used to conveniently initialize a concreted subclass.
open class OCKContactViewController<Store: OCKStoreProtocol>: OCKSynchronizedViewController<Store.Contact> {
    
    // MARK: Properties
    
    /// Specifies all the ways in which a contact can be displayed.
    public enum Style: String, CaseIterable {
        case simple
    }
    
    internal var detailPresentingView: UIView? { return nil }

    /// The store manager used to provide synchronization.
    public let storeManager: OCKSynchronizedStoreManager<Store>
    private let contactIdentifier: String
    
    /// The contact being displayed. If the view controller is initialized with a contact identifier, it will be nil until the query completes.
    public private (set) var contact: Store.Contact?
    
    /// If set, the delegate will receive callbacks when important events happen.
    public weak var delegate: OCKContactViewControllerDelegate?
    
    // MARK: Initializers
    
    // Styled initializers
    
    /// Creates a concrete subclass of `OCKContactViewController` and returns it upcast to `OCKContactViewController`
    /// - Parameter style: A style, which maps to a specific subclass.
    /// - Parameter storeManager: The store manager, used for synchronization.
    /// - Parameter contact: The contact to display in the view controller.
    public static func makeViewController(style: Style, storeManager: OCKSynchronizedStoreManager<Store>,
                                          contact: Store.Contact) -> OCKContactViewController<Store> {
        switch style {
        case .simple: return OCKSimpleContactViewController(storeManager: storeManager, contact: contact)
        }
    }
    
    /// Creates a concrete subclass of `OCKContactViewController` and returns it upcast to `OCKContactViewController`
    /// - Parameter style: A style, which maps to a specific subclass.
    /// - Parameter storeManager: The store manager, used for synchronization.
    /// - Parameter contactIdentifier: The identifier of the contact to be displayed in the view controller.
    public static func makeViewController(style: Style, storeManager: OCKSynchronizedStoreManager<Store>,
                                          contactIdentifier: String) -> OCKContactViewController<Store> {
        switch style {
        case .simple:
            return OCKSimpleContactViewController(storeManager: storeManager, contactIdentifier: contactIdentifier)
        }
    }
    
    // Custom view initializer
    
    internal init(
        storeManager: OCKSynchronizedStoreManager<Store>,
        contact: Store.Contact,
        loadCustomView: @escaping () -> UIView,
        modelDidChange: @escaping CustomModelDidChange) {
        
        self.contact = contact
        self.storeManager = storeManager
        self.contactIdentifier = contact.identifier
        super.init(loadCustomView: loadCustomView, modelDidChange: modelDidChange)
    }
    
    internal init(
        storeManager: OCKSynchronizedStoreManager<Store>,
        contactIdentifier: String,
        loadCustomView: @escaping () -> UIView,
        modelDidChange: @escaping CustomModelDidChange) {
        
        self.storeManager = storeManager
        self.contactIdentifier = contactIdentifier
        super.init(loadCustomView: loadCustomView, modelDidChange: modelDidChange)
    }
    
    // Bindable view initializers
    
    internal init<View: UIView & OCKBindable>(
        storeManager: OCKSynchronizedStoreManager<Store>,
        contact: Store.Contact,
        loadDefaultView: @escaping () -> View,
        modelDidChange: ModelDidChange? = nil)
    where View.Model == Store.Contact {
            
        self.contact = contact
        self.storeManager = storeManager
        self.contactIdentifier = contact.identifier
        super.init(loadDefaultView: loadDefaultView, modelDidChange: modelDidChange)
    }
    
    internal init<View: UIView & OCKBindable>(
        storeManager: OCKSynchronizedStoreManager<Store>,
        contactIdentifier: String,
        loadDefaultView: @escaping () -> View,
        modelDidChange: ModelDidChange? = nil)
    where View.Model == Store.Contact {
            
        self.storeManager = storeManager
        self.contactIdentifier = contactIdentifier
        super.init(loadDefaultView: loadDefaultView, modelDidChange: modelDidChange)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Life cycle
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        // setup tap gesture on the view
        if let detailPresentingView = detailPresentingView {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(presentDetailViewController))
            detailPresentingView.isUserInteractionEnabled = true
            detailPresentingView.addGestureRecognizer(tapGesture)
        }
        
        contact == nil ? fetchContact() : modelUpdated(viewModel: contact, animated: false)
    }
    
    // MARK: Methods
    
    @objc
    private func presentDetailViewController() {
        delegate?.didSelect(contactViewController: self)
    }
    
    private func fetchContact() {
        storeManager.store.fetchContact(withIdentifier: contactIdentifier) { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success(let contact):
                let shouldAnimate = self.contact != nil
                self.contact = contact
                self.modelUpdated(viewModel: self.contact, animated: shouldAnimate)
                self.subscribe()
                self.delegate?.contactViewController(self, didFinishQuerying: self.contact)
            case .failure(let error):
                self.delegate?.contactViewController(self, didFailWithError: error)
            }
        }
    }
    
    override internal func subscribe() {
        super.subscribe()
        guard let contact = contact else { return }
        let changedSubscription = storeManager.publisher(forContact: contact, categories: [.add, .update]).sink { [weak self] updatedContact in
            let shouldAnimate = self?.contact != nil
            self?.contact = updatedContact
            self?.modelUpdated(viewModel: self?.contact, animated: shouldAnimate)
        }
        
        let deletedSubscription = storeManager.publisher(forContact: contact, categories: [.delete], fetchImmediately: false).sink { [weak self] _ in
            let shouldAnimate = self?.contact != nil
            self?.contact = nil
            self?.modelUpdated(viewModel: self?.contact, animated: shouldAnimate)
        }
        
        subscription = AnyCancellable {
            changedSubscription.cancel()
            deletedSubscription.cancel()
        }
    }
}
