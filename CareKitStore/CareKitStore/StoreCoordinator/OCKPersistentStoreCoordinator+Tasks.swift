/*
 Copyright (c) 2016-2025, Apple Inc. All rights reserved.
 
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

extension OCKStoreCoordinator {

    public func anyTasks(matching query: OCKTaskQuery) -> CareStoreQueryResults<OCKAnyTask> {

        let relevantStores = storesHandlingQuery(query)

        let tasksStreams = relevantStores.map {
            $0.anyTasks(matching: query)
        }

        let tasks = combineMany(
            sequences: tasksStreams,
            makeSortDescriptors: {
                return query
                    .sortDescriptors
                    .map(\.nsSortDescriptor)
            }
        )

        return tasks
    }

    public func fetchAnyTasks(
        query: OCKTaskQuery,
        callbackQueue: DispatchQueue = .main,
        completion: @Sendable @escaping (Result<[OCKAnyTask], OCKStoreError>) -> Void
    ) {
        let respondingStores = storesHandlingQuery(query)
        let closures = respondingStores.map({ store in { done in
            store.fetchAnyTasks(query: query, callbackQueue: callbackQueue, completion: done) }
        })
        aggregateAndFlatten(closures, callbackQueue: callbackQueue, completion: completion)
    }

    public func addAnyTasks(
        _ tasks: [OCKAnyTask],
        callbackQueue: DispatchQueue = .main,
        completion: (@Sendable (Result<[OCKAnyTask], OCKStoreError>) -> Void)? = nil
    ) {
        do {
            let store = try firstStoreHandlingTasks(tasks)
            store.addAnyTasks(tasks, callbackQueue: callbackQueue, completion: completion)
        } catch {
            callbackQueue.async {
                completion?(.failure(.addFailed(
                    reason: "Failed to find store accepting tasks. Error: \(error.localizedDescription)")))
            }
        }
    }

    public func updateAnyTasks(
        _ tasks: [OCKAnyTask],
        callbackQueue: DispatchQueue = .main,
        completion: (@Sendable (Result<[OCKAnyTask], OCKStoreError>) -> Void)? = nil
    ) {
        do {
            let store = try firstStoreHandlingTasks(tasks)
            store.updateAnyTasks(tasks, callbackQueue: callbackQueue, completion: completion)
        } catch {
            callbackQueue.async {
                completion?(.failure(.updateFailed(
                    reason: "Failed to find store accepting tasks. Error: \(error.localizedDescription)")))
            }
        }
    }

    public func deleteAnyTasks(
        _ tasks: [OCKAnyTask],
        callbackQueue: DispatchQueue = .main,
        completion: (@Sendable (Result<[OCKAnyTask], OCKStoreError>) -> Void)? = nil
    ) {
        do {
            let store = try firstStoreHandlingTasks(tasks)
            store.deleteAnyTasks(tasks, callbackQueue: callbackQueue, completion: completion)
        } catch {
            callbackQueue.async {
                completion?(.failure(.deleteFailed(
                    reason: "Failed to find store accepting tasks. Error: \(error.localizedDescription)")))
            }
        }
    }

    private func firstStoreHandlingTasks(_ tasks: [OCKAnyTask]) throws -> OCKAnyTaskStore {

        let firstMatchingStore = state.withLock { state in

            return state.eventStores.first { store in
                return tasks.allSatisfy { task in
                    return
                        state.delegate?.taskStore(store, shouldHandleWritingTask: task) ??
                        taskStore(store, shouldHandleWritingTask: task)
                }
            }
        }

        guard let firstMatchingStore else {
            throw OCKStoreError.invalidValue(reason: "Cannot find store to handle tasks")
        }

        return firstMatchingStore
    }

    private func storesHandlingQuery(_ query: OCKTaskQuery) -> [OCKAnyReadOnlyTaskStore] {

        return state.withLock { state in

            let stores = state.readOnlyEventStores + state.eventStores

            let respondingStores = stores.filter { store in
                return
                    state.delegate?.taskStore(store, shouldHandleQuery: query) ??
                    taskStore(store, shouldHandleQuery: query)
            }

            return respondingStores
        }
    }
}
