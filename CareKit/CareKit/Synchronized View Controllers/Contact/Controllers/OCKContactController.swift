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
import Combine
import Foundation
import MapKit
import MessageUI

/// A basic controller capable of watching and updating contacts.
open class OCKContactController: OCKContactControllerProtocol, ObservableObject {

    // MARK: OCKContactControllerProtocol

    public var store: OCKAnyContactStore { storeManager.store }
    public let objectWillChange: CurrentValueSubject<OCKAnyContact?, Never>

    // MARK: - Properties

    /// The store manager against which the task will be synchronized.
    public let storeManager: OCKSynchronizedStoreManager

    private var subscription: AnyCancellable?

    // MARK: - Life Cycle

    /// Initialize with a store manager.
    public required init(storeManager: OCKSynchronizedStoreManager) {
        self.objectWillChange = .init(nil)
        self.storeManager = storeManager
    }

    // MARK: - Methods

    /// Begin observing a contact.
    ///
    /// - Parameter contact: The contact to watch for changes.
    open func observeContact(_ contact: OCKAnyContact) {
        objectWillChange.value = contact

        // Set the view model when the contact changes
        subscription = storeManager.publisher(forContact: contact, categories: [.update, .add], fetchImmediately: false)
            .sink { [weak self] newValue in
                self?.objectWillChange.value = newValue
            }
    }

    /// Fetch and begin observing the first contact described by a query.
    ///
    /// - Parameters:
    ///   - query: Any contact query describing the contact to be fetched.
    ///
    /// - Note: If the query matches multiple contacts, the first one returned will be used.
    open func fetchAndObserveContact(forQuery query: OCKAnyContactQuery, errorHandler: ((OCKStoreError) -> Void)? = nil) {

        // Fetch the contact to set as the view model value
        storeManager.store.fetchAnyContacts(query: query, callbackQueue: .main) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error): errorHandler?(error)
            case .success(let contacts):
                self.objectWillChange.value = contacts.first

                // Set the view model when the contact changes
                guard let id = self.objectWillChange.value?.id else { return }
                self.subscription = self.storeManager.publisher(forContactID: id, categories: [.update, .add]).sink { [weak self] newValue in
                    self?.objectWillChange.value = newValue
                }
            }
        }
    }

    /// Fetch and begin observing the contact with the given identifier.
    ///
    /// - Parameters:
    ///   - id: The user-defined unique identifier for the contact.
    open func fetchAndObserveContact(withID id: String, errorHandler: ((OCKStoreError) -> Void)? = nil) {

        // Fetch the contact to set as the view model value
        storeManager.store.fetchAnyContact(withID: id, callbackQueue: .main) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error): errorHandler?(error)
            case .success(let contact):
                self.objectWillChange.value = contact

                // Set the view model when the contact changes
                self.subscription = self.storeManager.publisher(forContactID: contact.id, categories: [.update, .add]).sink { [weak self] newValue in
                    self?.objectWillChange.value = newValue
                }
            }
        }
    }
}
