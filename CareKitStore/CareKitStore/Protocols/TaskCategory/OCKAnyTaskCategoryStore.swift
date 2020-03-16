//
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

import Foundation

/// Any store from which types conforming to `OCKAnyTaskCategory` can be queried is considered `OCKAnyReadOnlyTaskCategoryStore`.
public protocol OCKAnyReadOnlyTaskCategoryStore: AnyObject {

    /// The delegate receives callbacks when the contents of the care plan store are modified.
    /// In `CareKit` apps, the delegate will be set automatically, and it should not be modified.
    var taskCategoryDelegate: OCKTaskCategoryStoreDelegate? { get set }

    /// `fetchAnyTaskCategories` asynchronously retrieves an array of taskCategories from the store.
    ///
    /// - Parameters:
    ///   - query: A query used to constrain the values that will be fetched.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func fetchAnyTaskCategories(query: OCKAnyTaskCategoryQuery, callbackQueue: DispatchQueue, completion: @escaping OCKResultClosure<[OCKAnyTaskCategory]>)

    // MARK: Singular Methods - Implementation Provided

    /// `fetchAnyTaskCategory` asynchronously retrieves a single taskCategory from the store.
    ///
    /// - Parameters:
    ///   - id: The identifier of the item to be fetched.
    ///   - query: A query used to constrain the values that will be fetched.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func fetchAnyTaskCategory(withID id: String, callbackQueue: DispatchQueue, completion: @escaping OCKResultClosure<OCKAnyTaskCategory>)
}

/// Any store able to write to one ore more types conforming to `OCKAnyTaskCategory` is considered an `OCKAnyTaskCategoryStore`.
public protocol OCKAnyTaskCategoryStore: OCKAnyReadOnlyTaskCategoryStore {

    /// `addAnyTaskCategories` asynchronously adds an array of taskCategories to the store.
    ///
    /// - Parameters:
    ///   - taskCategories: An array of taskCategories to be added to the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func addAnyTaskCategories(_ taskCategories: [OCKAnyTaskCategory], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyTaskCategory]>?)

    /// `updateAnyTaskCategories` asynchronously updates an array of taskCategories in the store.
    ///
    /// - Parameters:
    ///   - taskCategories: An array of taskCategories to be updated. The taskCategories must already exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func updateAnyTaskCategories(_ taskCategories: [OCKAnyTaskCategory], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyTaskCategory]>?)

    /// `deleteAnyTaskCategories` asynchronously deletes an array of taskCategories from the store.
    ///
    /// - Parameters:
    ///   - taskCategories: An array of taskCategories to be deleted. The taskCategories must exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func deleteAnyTaskCategories(_ taskCategories: [OCKAnyTaskCategory], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyTaskCategory]>?)

    // MARK: Singular Methods - Implementation Privided

    /// `addAnyTaskCategory` asynchronously adds a single taskCategory to the store.
    ///
    /// - Parameters:
    ///   - taskCategory: A single taskCategory to be added to the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func addAnyTaskCategory(_ taskCategory: OCKAnyTaskCategory, callbackQueue: DispatchQueue, completion: OCKResultClosure<OCKAnyTaskCategory>?)

    /// `updateAnyTaskCategory` asynchronously update single taskCategory in the store.
    ///
    /// - Parameters:
    ///   - taskCategory: A single taskCategory to be updated. The taskCategory must already exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func updateAnyTaskCategory(_ taskCategory: OCKAnyTaskCategory, callbackQueue: DispatchQueue, completion: OCKResultClosure<OCKAnyTaskCategory>?)

    /// `deleteAnyTaskCategory` asynchronously deletes a single taskCategory from the store.
    ///
    /// - Parameters:
    ///   - taskCategory: An single taskCategory to be deleted. The taskCategory must exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func deleteAnyTaskCategory(_ taskCategory: OCKAnyTaskCategory, callbackQueue: DispatchQueue, completion: OCKResultClosure<OCKAnyTaskCategory>?)
}

// MARK: Singular Methods for OCKAnyReadOnlyTaskCategoryStore

public extension OCKAnyReadOnlyTaskCategoryStore {
    func fetchAnyTaskCategory(withID id: String, callbackQueue: DispatchQueue = .main,
                         completion: @escaping OCKResultClosure<OCKAnyTaskCategory>) {
        var query = OCKTaskCategoryQuery(for: Date())
        query.limit = 1
        query.extendedSortDescriptors = [.title(ascending: true)]
        query.ids = [id]

        fetchAnyTaskCategories(query: query, callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .fetchFailed(reason: "No taskCategory with ID: \(id)")))
    }
}

// MARK: Singular Methods for OCKAnyTaskCategoryStore

public extension OCKAnyTaskCategoryStore {
    func addAnyTaskCategory(_ taskCategory: OCKAnyTaskCategory, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<OCKAnyTaskCategory>? = nil) {
        addAnyTaskCategories([taskCategory], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .addFailed(reason: "Failed to add taskCategory: \(taskCategory)")))
    }

    func updateAnyTaskCategory(_ taskCategory: OCKAnyTaskCategory, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<OCKAnyTaskCategory>? = nil) {
        updateAnyTaskCategories([taskCategory], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .updateFailed(reason: "Failed to update taskCategory: \(taskCategory)")))
    }

    func deleteAnyTaskCategory(_ taskCategory: OCKAnyTaskCategory, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<OCKAnyTaskCategory>? = nil) {
        deleteAnyTaskCategories([taskCategory], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .deleteFailed(reason: "Failed to delete taskCategory: \(taskCategory)")))
    }
}
