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
import HealthKit

@available(iOS 15, watchOS 8, *)
public extension OCKHealthKitPassthroughStore {

    func tasks(matching query: OCKTaskQuery) -> CareStoreQueryResults<OCKHealthKitTask> {

        let tasks = store.healthKitTasks(matching: query)
        let wrappedTasks = CareStoreQueryResults(wrapping: tasks)
        return wrappedTasks
    }

    func fetchTasks(query: OCKTaskQuery, callbackQueue: DispatchQueue = .main,
                    completion: @escaping (Result<[OCKHealthKitTask], OCKStoreError>) -> Void) {
        store.context.perform {
            do {
                let tasks = try self.store.fetchHealthKitTasks(query: query)
                callbackQueue.async {
                    completion(.success(tasks))
                }
            } catch {
                callbackQueue.async {
                    completion(.failure(.fetchFailed(reason: error.localizedDescription)))
                }
            }
        }
    }

    func addTasks(_ tasks: [OCKHealthKitTask], callbackQueue: DispatchQueue = .main,
                  completion: ((Result<[OCKHealthKitTask], OCKStoreError>) -> Void)? = nil) {

        store.addHealthKitTasks(
            tasks,
            callbackQueue: callbackQueue,
            completion: completion
        )
    }

    func updateTasks(_ tasks: [OCKHealthKitTask], callbackQueue: DispatchQueue = .main,
                     completion: ((Result<[OCKHealthKitTask], OCKStoreError>) -> Void)? = nil) {
        store.updateHealthKitTasks(tasks, callbackQueue: callbackQueue, completion: completion)
    }

    func deleteTasks(_ tasks: [OCKHealthKitTask], callbackQueue: DispatchQueue = .main,
                     completion: ((Result<[OCKHealthKitTask], OCKStoreError>) -> Void)? = nil) {

        store.deleteHealthKitTasks(
            tasks,
            callbackQueue: callbackQueue,
            completion: completion
        )
    }

    func fetchTasks(for outcomes: [OCKHealthKitOutcome]) throws -> [OCKHealthKitTask] {
        var query = OCKTaskQuery()
        query.uuids = outcomes.map { $0.taskUUID }
        let tasks = try store.fetchHealthKitTasks(query: query)
        return tasks
    }
}
