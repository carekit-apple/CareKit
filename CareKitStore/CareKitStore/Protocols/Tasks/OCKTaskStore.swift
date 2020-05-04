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

/// Any store from which a single type conforming to `OCKAnyTask` can be queried is considered a `OCKReadableTaskStore`.
public protocol OCKReadableTaskStore: OCKAnyReadOnlyTaskStore {
    associatedtype Task: OCKAnyTask & Equatable
    associatedtype TaskQuery: OCKAnyTaskQuery

    /// `fetchTasks` asynchronously retrieves an array of tasks from the store.
    ///
    /// - Parameters:
    ///   - query: A query used to constrain the values that will be fetched.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func fetchTasks(query: TaskQuery, callbackQueue: DispatchQueue, completion: @escaping OCKResultClosure<[Task]>)

    // MARK: Singular Methods - Implementation Provided

    /// `fetchTask` asynchronously retrieves an array of tasks from the store using its user-defined unique identifier. If a task with the
    /// specified identifier is not found, the completion handler will be called with an error.
    ///
    /// - Parameters:
    ///   - id: A unique user-defined identifier
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func fetchTask(withID id: String, callbackQueue: DispatchQueue, completion: @escaping OCKResultClosure<Task>)
}

/// Any store that can perform read and write operations on a single type conforming to `OCKAnyTask` is considered an `OCKTaskStore`.
public protocol OCKTaskStore: OCKReadableTaskStore, OCKAnyTaskStore {

    /// `addTasks` asynchronously adds an array of tasks to the store.
    ///
    /// - Parameters:
    ///   - tasks: An array of tasks to be added to the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func addTasks(_ tasks: [Task], callbackQueue: DispatchQueue, completion: OCKResultClosure<[Task]>?)

    /// `updateTasks` asynchronously updates an array of tasks in the store.
    ///
    /// - Parameters:
    ///   - tasks: An array of tasks to be updated. The tasks must already exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func updateTasks(_ tasks: [Task], callbackQueue: DispatchQueue, completion: OCKResultClosure<[Task]>?)

    /// `deleteTasks` asynchronously deletes an array of tasks from the store.
    ///
    /// - Parameters:
    ///   - tasks: An array of tasks to be deleted. The tasks must exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func deleteTasks(_ tasks: [Task], callbackQueue: DispatchQueue, completion: OCKResultClosure<[Task]>?)
    
    /// Adds, updates, and deletes tasks in a single atomic transaction
    /// - Parameter tasks: Tasks that should be either added or updated, depending on whether or not they already exist.
    /// - Parameter deleteTasks: Tasks that should be deleted from the store.
    /// - Parameter callbackQueue: The queue that the callback will be performed on
    /// - Parameter completion: A result closure that takes arrays of added, updated, and deleted tasks.
    func addUpdateOrDeleteTasks(
        addOrUpdate tasks: [Task],
        delete deleteTasks: [Task],
        callbackQueue: DispatchQueue,
        completion: ((Result<([Task], [Task], [Task]), OCKStoreError>) -> Void)?)
    
    // MARK: Implementation Provided

    /// `addTask` asynchronously adds a task to the store.
    ///
    /// - Parameters:
    ///   - task: A task to be added to the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func addTask(_ task: Task, callbackQueue: DispatchQueue, completion: OCKResultClosure<Task>?)

    /// `updateTask` asynchronously updates a task in the store.
    ///
    /// - Parameters:
    ///   - contact: A task to be updated. The task must already exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func updateTask(_ task: Task, callbackQueue: DispatchQueue, completion: OCKResultClosure<Task>?)

    /// `deleteTask` asynchronously deletes a task from the store.
    ///
    /// - Parameters:
    ///   - task: A task to be deleted. The task must exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func deleteTask(_ task: Task, callbackQueue: DispatchQueue, completion: OCKResultClosure<Task>?)
}

// MARK: Singular Methods for OCKReadableTaskStore

public extension OCKReadableTaskStore {
    func fetchTask(withID id: String, callbackQueue: DispatchQueue = .main, completion: @escaping OCKResultClosure<Task>) {
        var query = OCKTaskQuery(for: Date())
        query.extendedSortDescriptors = [.effectiveDate(ascending: true)]
        query.ids = [id]
        query.limit = 1

        fetchTasks(query: TaskQuery(query), callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .fetchFailed(reason: "No task with ID: \(id)")))
    }
}

// MARK: Singular Methods for OCKTaskStore

public extension OCKTaskStore {
    func addTask(_ task: Task, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<Task>? = nil) {
        addTasks([task], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .addFailed(reason: "Failed to add task \(task)")))
    }

    func updateTask(_ task: Task, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<Task>? = nil) {
        updateTasks([task], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .updateFailed(reason: "Failed to update task: \(task)")))
    }

    func deleteTask(_ task: Task, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<Task>? = nil) {
        deleteTasks([task], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .deleteFailed(reason: "Failed to delete task: \(task)")))
    }
}

// MARK: OCKAnyReadOnlyStore conformance for OCKReadableStore

public extension OCKReadableTaskStore {
    func fetchAnyTasks(query: OCKAnyTaskQuery, callbackQueue: DispatchQueue,
                       completion: @escaping OCKResultClosure<[OCKAnyTask]>) {
        let taskQuery = TaskQuery(query)
        fetchTasks(query: taskQuery, callbackQueue: callbackQueue) { completion($0.map { $0.map { $0 as OCKAnyTask } }) }
    }
}

// MARK: OCKAnyStore conformance for OCKTaskStore

public extension OCKTaskStore {
    func addAnyTasks(_ tasks: [OCKAnyTask], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyTask]>?) {
        guard let tasks = tasks as? [Task] else {
            let message = "Failed to add tasks. Not all tasks were of the correct type, \(Task.self)."
            callbackQueue.async { completion?(.failure(.addFailed(reason: message))) }
            return
        }
        addTasks(tasks, callbackQueue: callbackQueue) { completion?($0.map { $0.map { $0 as OCKAnyTask } }) }
    }

    func updateAnyTasks(_ tasks: [OCKAnyTask], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyTask]>?) {
        guard let tasks = tasks as? [Task] else {
            let message = "Failed to update tasks. Not all tasks were of the correct type, \(Task.self)."
            callbackQueue.async { completion?(.failure(.updateFailed(reason: message))) }
            return
        }
        updateTasks(tasks, callbackQueue: callbackQueue) { completion?($0.map { $0.map { $0 as OCKAnyTask } }) }
    }

    func deleteAnyTasks(_ tasks: [OCKAnyTask], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyTask]>?) {
        guard let tasks = tasks as? [Task] else {
            let message = "Failed to delete tasks. Not all tasks were of the correct type, \(Task.self)."
            callbackQueue.async { completion?(.failure(.deleteFailed(reason: message))) }
            return
        }
        deleteTasks(tasks, callbackQueue: callbackQueue) { completion?($0.map { $0.map { $0 as OCKAnyTask } }) }
    }
}
