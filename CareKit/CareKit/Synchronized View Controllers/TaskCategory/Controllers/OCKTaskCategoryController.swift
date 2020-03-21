/*
 Copyright (c) 2020, Apple Inc. All rights reserved.
 
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

/// A basic controller capable of watching and updating taskCategories.
open class OCKTaskCategoryController: OCKTaskCategoryControllerProtocol, ObservableObject {

    // MARK: OCKTaskCategoryControllerProtocol

    public var store: OCKAnyTaskCategoryStore { storeManager.store }
    public let objectWillChange: CurrentValueSubject<OCKAnyTaskCategory?, Never>

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

    /// Begin observing a taskCategory.
    ///
    /// - Parameter taskCategory: The taskCategory to watch for changes.
    open func observeTaskCategory(_ taskCategory: OCKAnyTaskCategory) {
        objectWillChange.value = taskCategory

        // Set the view model when the taskCategory changes
        subscription = storeManager.publisher(forTaskCategory: taskCategory, categories: [.update, .add], fetchImmediately: false)
            .sink { [weak self] newValue in
                self?.objectWillChange.value = newValue
            }
    }

    /// Fetch and begin observing the first taskCategory described by a query.
    ///
    /// - Parameters:
    ///   - query: Any taskCategory query describing the taskCategory to be fetched.
    ///
    /// - Note: If the query matches multiple taskCategories, the first one returned will be used.
    open func fetchAndObserveTaskCategory(forQuery query: OCKAnyTaskCategoryQuery, errorHandler: ((OCKStoreError) -> Void)? = nil) {

        // Fetch the taskCategory to set as the view model value
        storeManager.store.fetchAnyTaskCategories(query: query, callbackQueue: .main) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error): errorHandler?(error)
            case .success(let taskCategories):
                self.objectWillChange.value = taskCategories.first

                // Set the view model when the taskCategory changes
                guard let id = self.objectWillChange.value?.id else { return }
                self.subscription = self.storeManager.publisher(forTaskCategoryID: id, categories: [.update, .add]).sink { [weak self] newValue in
                    self?.objectWillChange.value = newValue
                }
            }
        }
    }

    /// Fetch and begin observing the taskCategory with the given identifier.
    ///
    /// - Parameters:
    ///   - id: The user-defined unique identifier for the taskCategory.
    open func fetchAndObserveTaskCategory(withID id: String, errorHandler: ((OCKStoreError) -> Void)? = nil) {

        // Fetch the taskCategory to set as the view model value
        storeManager.store.fetchAnyTaskCategory(withID: id, callbackQueue: .main) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error): errorHandler?(error)
            case .success(let taskCategory):
                self.objectWillChange.value = taskCategory

                // Set the view model when the taskCategory changes
                self.subscription = self.storeManager.publisher(forTaskCategoryID: taskCategory.id, categories: [.update, .add]).sink { [weak self] newValue in
                    self?.objectWillChange.value = newValue
                }
            }
        }
    }
}
