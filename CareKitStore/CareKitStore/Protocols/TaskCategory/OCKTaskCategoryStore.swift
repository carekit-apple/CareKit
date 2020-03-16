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

/// Any store from which a single type conforming to `OCKAnyTaskCategory` can be queried is considered `OCKAReadableCarePlanStore`.
public protocol OCKReadableTaskCategoryStore: OCKAnyReadOnlyTaskCategoryStore {
    associatedtype TaskCategory: OCKAnyTaskCategory & Equatable & Identifiable
    associatedtype TaskCategoryQuery: OCKAnyTaskCategoryQuery

    /// `fetchTaskCategories` asynchronously retrieves an array of categories from the store.
    ///
    /// - Parameters:
    ///   - query: A query used to constrain the values that will be fetched.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func fetchTaskCategories(query: TaskCategoryQuery, callbackQueue: DispatchQueue, completion: @escaping OCKResultClosure<[TaskCategory]>)

    // MARK: Implementation Provided

    /// `fetchTaskCategory` asynchronously retrieves a taskCategory from the store using its user-defined unique identifier. If a taskCategory with the
    /// specified identifier is not found, the completion handler will be called with an error.
    ///
    /// - Parameters:
    ///   - id: A unique user-defined identifier.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func fetchTaskCategory(withID id: String, callbackQueue: DispatchQueue, completion: @escaping OCKResultClosure<TaskCategory>)
}

/// Any store that can perform read and write operations on a single type conforming to `OCKAnyTaskCategory` is considered an `OCKCarePlanStore`.
public protocol OCKTaskCategoryStore: OCKReadableTaskCategoryStore, OCKAnyTaskCategoryStore {

    /// `addTaskCategories` asynchronously adds an array of categories to the store.
    ///
    /// - Parameters:
    ///   - categories: An array of categories to be added to the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func addTaskCategories(_ taskCategories: [TaskCategory], callbackQueue: DispatchQueue, completion: OCKResultClosure<[TaskCategory]>?)

    /// `updateTaskCategories` asynchronously updates an array of categories in the store.
    ///
    /// - Parameters:
    ///   - categories: An array of categories to be updated. The categories must already exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func updateTaskCategories(_ taskCategories: [TaskCategory], callbackQueue: DispatchQueue, completion: OCKResultClosure<[TaskCategory]>?)

    /// `deleteTaskCategories` asynchronously deletes an array of categories from the store.
    ///
    /// - Parameters:
    ///   - categories: An array of categories to be deleted. The categories must exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func deleteTaskCategories(_ taskCategories: [TaskCategory], callbackQueue: DispatchQueue, completion: OCKResultClosure<[TaskCategory]>?)

    // MARK: Implementation Provided

    /// `addTaskCategory` asynchronously adds a taskCategory to the store.
    ///
    /// - Parameters:
    ///   - taskCategory: A TaskCategory to be added to the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func addTaskCategory(_ taskCategory: TaskCategory, callbackQueue: DispatchQueue, completion: OCKResultClosure<TaskCategory>?)

    /// `updateTaskCategory` asynchronously updates a categories in the store.
    ///
    /// - Parameters:
    ///   - taskCategory: A TaskCategory to be updated. The taskCategory must already exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func updateTaskCategory(_ taskCategory: TaskCategory, callbackQueue: DispatchQueue, completion: OCKResultClosure<TaskCategory>?)

    /// `deleteTaskCategory` asynchronously deletes a taskCategory from the store.
    ///
    /// - Parameters:
    ///   - taskCategory: A TaskCategory to be deleted. The taskCategory must exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func deleteTaskCategory(_ taskCategory: TaskCategory, callbackQueue: DispatchQueue, completion: OCKResultClosure<TaskCategory>?)
}

// MARK: Singular Methods for OCKReadableTaskCategoryStore
public extension OCKReadableTaskCategoryStore {
    func fetchTaskCategory(withID id: String, callbackQueue: DispatchQueue = .main,
                      completion: @escaping OCKResultClosure<TaskCategory>) {
        var query = OCKTaskCategoryQuery(for: Date())
        query.limit = 1
        query.ids = [id]
        query.extendedSortDescriptors = [.title(ascending: true)]

        fetchTaskCategories(query: TaskCategoryQuery(query), callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .fetchFailed(reason: "No taskCategory with ID: \(id)")))
    }
}

// MARK: Singular Methods for OCKTaskCategoryStore

public extension OCKTaskCategoryStore {
    func addTaskCategory(_ taskCategory: TaskCategory, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<TaskCategory>? = nil) {
        addTaskCategories([taskCategory], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .addFailed(reason: "Failed to add taskCategory: \(taskCategory)")))
    }

    func updateTaskCategory(_ taskCategory: TaskCategory, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<TaskCategory>? = nil) {
        updateTaskCategories([taskCategory], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .updateFailed(reason: "Failed to update taskCategory: \(taskCategory)")))
    }

    func deleteTaskCategory(_ taskCategory: TaskCategory, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<TaskCategory>? = nil) {
        deleteTaskCategories([taskCategory], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .deleteFailed(reason: "Failed to delete taskCategory: \(taskCategory)")))
    }
}

// MARK: OCKAnyReadbaleTaskCategoryStore conformance for OCKReadableTaskCategoryStore

public extension OCKReadableTaskCategoryStore {
    func fetchAnyTaskCategories(query: OCKAnyTaskCategoryQuery, callbackQueue: DispatchQueue,
                          completion: @escaping OCKResultClosure<[OCKAnyTaskCategory]>) {
        let taskCategoryQuery = TaskCategoryQuery(query)
        fetchTaskCategories(query: taskCategoryQuery, callbackQueue: callbackQueue) { completion($0.map { $0.map { $0 as OCKAnyTaskCategory } }) }
    }
}

// MARK: OCKAnyTaskCategoryStore conformance for OCKTaskCategoryStore

public extension OCKTaskCategoryStore {
    func addAnyTaskCategories(_ taskCategories: [OCKAnyTaskCategory], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyTaskCategory]>?) {
        guard let taskCategories = taskCategories as? [TaskCategory] else {
            let message = "Failed to add categories. Not all taskCategory were the correct type: \(TaskCategory.self)."
            callbackQueue.async { completion?(.failure(.addFailed(reason: message))) }
            return
        }
        addTaskCategories(taskCategories, callbackQueue: callbackQueue) { completion?($0.map { $0.map { $0 as OCKAnyTaskCategory } }) }
    }

    func updateAnyTaskCategories(_ taskCategories: [OCKAnyTaskCategory], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyTaskCategory]>?) {
        guard let taskCategories = taskCategories as? [TaskCategory] else {
            let message = "Failed to update categories. Not all taskCategory were the correct type: \(TaskCategory.self)."
            callbackQueue.async { completion?(.failure(.updateFailed(reason: message))) }
            return
        }

        updateTaskCategories(taskCategories, callbackQueue: callbackQueue) { completion?($0.map { $0.map { $0 as OCKAnyTaskCategory } }) }
    }

    func deleteAnyTaskCategories(_ taskCategories: [OCKAnyTaskCategory], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyTaskCategory]>?) {
        guard let taskCategories = taskCategories as? [TaskCategory] else {
            let message = "Failed to delete categories. Not all taskCategory were the correct type: \(TaskCategory.self)."
            callbackQueue.async { completion?(.failure(.deleteFailed(reason: message))) }
            return
        }
        deleteTaskCategories(taskCategories, callbackQueue: callbackQueue) { completion?($0.map { $0.map { $0 as OCKAnyTaskCategory } }) }
    }
}
