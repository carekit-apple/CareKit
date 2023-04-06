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

/// A store that allows for reading tasks.
public protocol OCKAnyReadOnlyTaskStore: OCKAnyResettableStore {

    /// A continuous stream of tasks that exist in the store.
    ///
    /// The stream yields a new value whenever the result changes and yields an error if there's an
    /// issue accessing the store or fetching results.
    ///
    /// Supply a query that matches tasks in the store. If the query doesn't contain a date
    /// interval, the result contains every version of a task. Multiple versions of the same task
    /// have the same ``OCKAnyTask/id`` but a different UUID. If the query does contain a date
    /// interval, the result contains the newest version of a task that exists in the interval.
    ///
    /// - Parameter query: A query that matches tasks in the store.
    func anyTasks(matching query: OCKTaskQuery) -> CareStoreQueryResults<OCKAnyTask>

    /// Asynchronously retrieve an array of tasks from the store.
    ///
    /// - Parameters:
    ///   - query: A query that constrain the fetched values.
    ///   - callbackQueue: The queue that the function calls the closure on. In most cases this is the main queue.
    ///   - completion: A callback that the function calls on the provided callback queue.
    func fetchAnyTasks(
        query: OCKTaskQuery,
        callbackQueue: DispatchQueue,
        completion: @escaping OCKResultClosure<[OCKAnyTask]>
    )

    // MARK: Singular Methods - Implementation Provided

    /// Asynchronously retrieve an array of tasks from the store using its user-defined unique identifier.
    ///
    /// If a task with the specified identifier isn't found, the completion handler receives an error.
    ///
    /// - Parameters:
    ///   - id: The identifier of the item to fetch.
    ///   - callbackQueue: The queue that the function calls the closure on. In most cases this is the main queue.
    ///   - completion: A callback that the function calls on the provided callback queue.
    func fetchAnyTask(
        withID id: String,
        callbackQueue: DispatchQueue,
        completion: @escaping (Result<OCKAnyTask, OCKStoreError>) -> Void
    )
}

/// Any store able to write to one ore more types conforming to `OCKAnyTask` is considered an `OCKAnyTaskStore`.
public protocol OCKAnyTaskStore: OCKAnyReadOnlyTaskStore {

    /// Asynchronously add an array of tasks to the store.
    ///
    /// - Parameters:
    ///   - tasks: An array of tasks that the function adds.
    ///   - callbackQueue: The queue that the function calls the closure on. In most cases this is the main queue.
    ///   - completion: A callback that the function calls on the provided callback queue.
    func addAnyTasks(_ tasks: [OCKAnyTask], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyTask]>?)

    /// Asynchronously update an array of tasks in the store.
    ///
    /// - Parameters:
    ///   - tasks: An array of tasks that the function updates. The tasks must already exist in the store.
    ///   - callbackQueue: The queue that the function calls the closure on. In most cases this is the main queue.
    ///   - completion: A callback that the function calls on the provided callback queue.
    func updateAnyTasks(_ tasks: [OCKAnyTask], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyTask]>?)

    /// Asynchronously delete an array of tasks from the store.
    ///
    /// - Parameters:
    ///   - tasks: An array of tasks that the function deletes. The tasks must exist in the store.
    ///   - callbackQueue: The queue that the function calls the closure on. In most cases this is the main queue.
    ///   - completion: A callback that the function calls on the provided callback queue.
    func deleteAnyTasks(_ tasks: [OCKAnyTask], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyTask]>?)

    // MARK: Implementation Provided

    /// Asynchronously add a task to the store.
    ///
    /// - Parameters:
    ///   - task: A task the function adds to the store.
    ///   - callbackQueue: The queue that the function calls the closure on. In most cases this is the main queue.
    ///   - completion: A callback that the function calls on the provided callback queue.
    func addAnyTask(_ task: OCKAnyTask, callbackQueue: DispatchQueue, completion: ((Result<OCKAnyTask, OCKStoreError>) -> Void)?)

    /// Asynchronously update a task in the store.
    ///
    /// - Parameters:
    ///   - task: A task the function updates. The task must already exist in the store.
    ///   - callbackQueue: The queue that the function calls the closure on. In most cases this is the main queue.
    ///   - completion: A callback that the function calls on the provided callback queue.
    func updateAnyTask(_ task: OCKAnyTask, callbackQueue: DispatchQueue, completion: ((Result<OCKAnyTask, OCKStoreError>) -> Void)?)

    /// Asynchronously delete a task from the store.
    ///
    /// - Parameters:
    ///   - task: A task the function deletes. The task must exist in the store.
    ///   - callbackQueue: The queue that the function calls the closure on. In most cases this is the main queue.
    ///   - completion: A callback that the function calls on the provided callback queue.
    func deleteAnyTask(_ task: OCKAnyTask, callbackQueue: DispatchQueue, completion: ((Result<OCKAnyTask, OCKStoreError>) -> Void)?)
}

// MARK: Singular Methods for OCKAnyReadOnlyTaskStore

public extension OCKAnyReadOnlyTaskStore {
    func fetchAnyTask(withID id: String, callbackQueue: DispatchQueue = .main, completion: @escaping OCKResultClosure<OCKAnyTask>) {
        var query = OCKTaskQuery(id: id)
        query.sortDescriptors = [.effectiveDate(ascending: false)]
        query.ids = [id]
        query.limit = 1
        fetchAnyTasks(query: query, callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .fetchFailed(reason: "No task with matching ID")))
    }
}

// MARK: Singular Methods for OCKAnyTaskStore

public extension OCKAnyTaskStore {
    func addAnyTask(_ task: OCKAnyTask, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<OCKAnyTask>? = nil) {
        addAnyTasks([task], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .addFailed(reason: "Failed to add task")))
    }

    func updateAnyTask(_ task: OCKAnyTask, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<OCKAnyTask>? = nil) {
        updateAnyTasks([task], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .updateFailed(reason: "Failed to update task")))
    }

    func deleteAnyTask(_ task: OCKAnyTask, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<OCKAnyTask>? = nil) {
        deleteAnyTasks([task], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .deleteFailed(reason: "Failed to delete task")))
    }
}

// MARK: Async methods for OCKAnyReadOnlyTaskStore

public extension OCKAnyReadOnlyTaskStore {

    /// Asynchronously retrieve an array of tasks from the store.
    ///
    /// - Parameters:
    ///   - query: A query that constrains the fetched values.
    func fetchAnyTasks(query: OCKTaskQuery) async throws -> [OCKAnyTask] {
        try await withCheckedThrowingContinuation { continuation in
            fetchAnyTasks(query: query, callbackQueue: .main, completion: continuation.resume)
        }
    }

    // MARK: Singular Methods - Implementation Provided

    /// Asynchronously retrieve an array of tasks from the store using its user-defined unique identifier.
    ///
    /// If a task with the specified identifier isn't found, the completion handler receives an error.
    ///
    /// - Parameters:
    ///   - id: The identifier of the item to fetch.
    func fetchAnyTask(withID id: String) async throws -> OCKAnyTask {
        try await withCheckedThrowingContinuation { continuation in
            fetchAnyTask(withID: id, callbackQueue: .main, completion: continuation.resume)
        }
    }
}

// MARK: Async methods for OCKAnyTaskStore

public extension OCKAnyTaskStore {

    /// Asynchronously add an array of tasks to the store.
    ///
    /// - Parameters:
    ///   - task: An array of tasks the function adds.
    func addAnyTasks(_ tasks: [OCKAnyTask]) async throws -> [OCKAnyTask] {
        try await withCheckedThrowingContinuation { continuation in
            addAnyTasks(tasks, callbackQueue: .main, completion: continuation.resume)
        }
    }

    /// Asynchronously update an array of tasks in the store.
    ///
    /// - Parameters:
    ///   - task: An array of tasks the function updates. The tasks must exist in the store.
    func updateAnyTasks(_ tasks: [OCKAnyTask]) async throws -> [OCKAnyTask] {
        try await withCheckedThrowingContinuation { continuation in
            updateAnyTasks(tasks, callbackQueue: .main, completion: continuation.resume)
        }
    }

    /// Asynchronously delete an array of tasks from the store.
    ///
    /// - Parameters:
    ///   - task: An array of tasks the function deletes. The tasks must exist in the store.
    func deleteAnyTasks(_ tasks: [OCKAnyTask]) async throws -> [OCKAnyTask] {
        try await withCheckedThrowingContinuation { continuation in
            deleteAnyTasks(tasks, callbackQueue: .main, completion: continuation.resume)
        }
    }

    // MARK: Singular Methods - Implementation Provided

    /// Asynchronously add a task to the store.
    ///
    /// - Parameters:
    ///   - task: A task the function adds.
    func addAnyTask(_ task: OCKAnyTask) async throws -> OCKAnyTask {
        try await withCheckedThrowingContinuation { continuation in
            addAnyTask(task, callbackQueue: .main, completion: continuation.resume)
        }
    }

    /// Asynchronously update a task in the store.
    ///
    /// - Parameters:
    ///   - task: A task the function updates. The task must exist in the store.
    func updateAnyTask(_ task: OCKAnyTask) async throws -> OCKAnyTask {
        try await withCheckedThrowingContinuation { continuation in
            updateAnyTask(task, callbackQueue: .main, completion: continuation.resume)
        }
    }

    /// Asynchronously delete a task from the store.
    ///
    /// - Parameters:
    ///   - task: A task the function deletes. The task must exist in the store.
    func deleteAnyTask(_ task: OCKAnyTask) async throws -> OCKAnyTask {
        try await withCheckedThrowingContinuation { continuation in
            deleteAnyTask(task, callbackQueue: .main, completion: continuation.resume)
        }
    }
}
