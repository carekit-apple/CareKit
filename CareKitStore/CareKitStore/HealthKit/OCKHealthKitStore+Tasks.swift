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
#if os(iOS)

import Foundation
import HealthKit

public extension OCKHealthKitPassthroughStore {

    func fetchTasks(query: OCKTaskQuery, callbackQueue: DispatchQueue = .main,
                    completion: @escaping (Result<[OCKHealthKitTask], OCKStoreError>) -> Void) {
        taskStore.fetchTasks(query: query, callbackQueue: callbackQueue, completion: completion)
    }

    func addTasks(_ tasks: [OCKHealthKitTask], callbackQueue: DispatchQueue = .main,
                  completion: ((Result<[OCKHealthKitTask], OCKStoreError>) -> Void)? = nil) {
        taskStore.addTasks(tasks, callbackQueue: callbackQueue) { [weak self] result in
            if case let .success(tasks) = result {
                tasks.forEach { self?.startObservingHealthKit(task: $0) }
            }
            completion?(result)
        }
    }

    func updateTasks(_ tasks: [OCKHealthKitTask], callbackQueue: DispatchQueue = .main,
                     completion: ((Result<[OCKHealthKitTask], OCKStoreError>) -> Void)? = nil) {
        taskStore.updateTasks(tasks, callbackQueue: callbackQueue) { [weak self] result in
            if case let .success(tasks) = result {
                tasks.forEach { self?.stopObservingHealthKit(task: $0) }
            }
            completion?(result)
        }
    }

    func deleteTasks(_ tasks: [OCKHealthKitTask], callbackQueue: DispatchQueue = .main,
                     completion: ((Result<[OCKHealthKitTask], OCKStoreError>) -> Void)? = nil) {
        taskStore.deleteTasks(tasks, callbackQueue: callbackQueue, completion: completion)
    }

    func addUpdateOrDeleteTasks(
        addOrUpdate tasks: [OCKHealthKitTask],
        delete deleteTasks: [OCKHealthKitTask],
        callbackQueue: DispatchQueue = .main,
        completion: ((Result<([OCKHealthKitTask], [OCKHealthKitTask], [OCKHealthKitTask]), OCKStoreError>) -> Void)? = nil) {

        taskStore.addUpdateOrDeleteTasks(
            addOrUpdate: tasks,
            delete: deleteTasks,
            callbackQueue: callbackQueue,
            completion: completion)
    }

    internal func fetchTasks(for outcomes: [OCKHealthKitOutcome]) throws -> [OCKHealthKitTask] {
        var query = OCKTaskQuery()
        query.uuids = outcomes.map { $0.taskUUID }
        let tasks = try taskStore.fetchTasks(query: query)
        return tasks
    }
}
#endif
