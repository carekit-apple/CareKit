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

import Foundation

/// Any store from which types conforming to `OCKAnyTask` can be queried is considered `OCKAnyReadOnlyTaskStore`.
public protocol OCKAnyReadOnlyTaskStore: AnyObject {

    /// The delegate receives callbacks when the contents of the care plan store are modified.
    /// In `CareKit` apps, the delegate will be set automatically, and it should not be modified.
    var taskDelegate: OCKTaskStoreDelegate? { get set }

    /// `fetchAnyTasks` asynchronously retrieves an array of tasks from the store.
    ///
    /// - Parameters:
    ///   - query: A query used to constrain the values that will be fetched.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func fetchAnyTasks(query: OCKAnyTaskQuery, callbackQueue: DispatchQueue,
                       completion: @escaping OCKResultClosure<[OCKAnyTask]>)

    // MARK: Singular Methods - Implementation Provided

    /// `fetchAnyTask` asynchronously retrieves an array of tasks from the store using its user-defined unique identifier. If a task with the
    /// specified identifier is not found, the completion handler will be called with an error.
    ///
    /// - Parameters:
    ///   - id: A unique user-defined identifier
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func fetchAnyTask(withID id: String, callbackQueue: DispatchQueue,
                      completion: @escaping (Result<OCKAnyTask, OCKStoreError>) -> Void)
}

/// Any store able to write to one ore more types conforming to `OCKAnyTask` is considered an `OCKAnyTaskStore`.
public protocol OCKAnyTaskStore: OCKAnyReadOnlyTaskStore {

    /// `addAnyTasks` asynchronously adds an array of tasks to the store.
    ///
    /// - Parameters:
    ///   - tasks: An array of tasks to be added to the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func addAnyTasks(_ tasks: [OCKAnyTask], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyTask]>?)

    /// `updateAnyTasks` asynchronously updates an array of tasks in the store.
    ///
    /// - Parameters:
    ///   - tasks: An array of tasks to be updated. The tasks must already exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func updateAnyTasks(_ tasks: [OCKAnyTask], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyTask]>?)

    /// `deleteAnyTasks` asynchronously deletes an array of tasks from the store.
    ///
    /// - Parameters:
    ///   - tasks: An array of tasks to be deleted. The tasks must exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func deleteAnyTasks(_ tasks: [OCKAnyTask], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyTask]>?)

    // MARK: Implementation Provided

    /// `addAnyTask` asynchronously adds a task to the store.
    ///
    /// - Parameters:
    ///   - task: A task to be added to the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func addAnyTask(_ task: OCKAnyTask, callbackQueue: DispatchQueue, completion: ((Result<OCKAnyTask, OCKStoreError>) -> Void)?)

    /// `updateAnyTask` asynchronously updates a task in the store.
    ///
    /// - Parameters:
    ///   - contact: A task to be updated. The task must already exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func updateAnyTask(_ task: OCKAnyTask, callbackQueue: DispatchQueue, completion: ((Result<OCKAnyTask, OCKStoreError>) -> Void)?)

    /// `deleteTask` asynchronously deletes a task from the store.
    ///
    /// - Parameters:
    ///   - task: A task to be deleted. The task must exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func deleteAnyTask(_ task: OCKAnyTask, callbackQueue: DispatchQueue, completion: ((Result<OCKAnyTask, OCKStoreError>) -> Void)?)
}

// MARK: Singular Methods for OCKAnyReadOnlyTaskStore

public extension OCKAnyReadOnlyTaskStore {
    func fetchAnyTask(withID id: String, callbackQueue: DispatchQueue = .main, completion: @escaping OCKResultClosure<OCKAnyTask>) {
        var query = OCKTaskQuery(for: Date())
        query.extendedSortDescriptors = [.effectiveDate(ascending: true)]
        query.ids = [id]
        query.limit = 1
        fetchAnyTasks(query: query, callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .fetchFailed(reason: "No task with ID: \(id)")))
    }
}

// MARK: Singular Methods for OCKAnyTaskStore

public extension OCKAnyTaskStore {
    func addAnyTask(_ task: OCKAnyTask, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<OCKAnyTask>? = nil) {
        addAnyTasks([task], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .addFailed(reason: "Failed to add task \(task)")))
    }

    func updateAnyTask(_ task: OCKAnyTask, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<OCKAnyTask>? = nil) {
        updateAnyTasks([task], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .updateFailed(reason: "Failed to update task: \(task)")))
    }

    func deleteAnyTask(_ task: OCKAnyTask, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<OCKAnyTask>? = nil) {
        deleteAnyTasks([task], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .deleteFailed(reason: "Failed to delete task: \(task)")))
    }
}
