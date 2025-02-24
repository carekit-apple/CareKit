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

extension OCKStoreCoordinator {

    public func anyTasks(matching query: OCKTaskQuery) -> CareStoreQueryResults<OCKAnyTask> {

        let stores = readOnlyEventStores + eventStores

        let relevantStores = stores.filter {
            taskStore($0, shouldHandleQuery: query)
        }

        let tasksStreams = relevantStores.map {
            $0.anyTasks(matching: query)
        }

        let sortDescriptors = query
            .sortDescriptors
            .map(\.nsSortDescriptor)

        let tasks = combineMany(
            sequences: tasksStreams,
            sortingElementsUsing: sortDescriptors
        )

        return tasks
    }

    public func fetchAnyTasks(
        query: OCKTaskQuery,
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[OCKAnyTask], OCKStoreError>) -> Void
    ) {
        let readableStores = readOnlyEventStores + eventStores
        let respondingStores = readableStores.filter { taskStore($0, shouldHandleQuery: query) }
        let closures = respondingStores.map({ store in { done in
            store.fetchAnyTasks(query: query, callbackQueue: callbackQueue, completion: done) }
        })
        aggregateAndFlatten(closures, callbackQueue: callbackQueue, completion: completion)
    }

    public func addAnyTasks(
        _ tasks: [OCKAnyTask],
        callbackQueue: DispatchQueue = .main,
        completion: ((Result<[OCKAnyTask], OCKStoreError>) -> Void)? = nil
    ) {
        do {
            try findStore(forTasks: tasks).addAnyTasks(tasks, callbackQueue: callbackQueue, completion: completion)
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
        completion: ((Result<[OCKAnyTask], OCKStoreError>) -> Void)? = nil
    ) {
        do {
            try findStore(forTasks: tasks).updateAnyTasks(tasks, callbackQueue: callbackQueue, completion: completion)
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
        completion: ((Result<[OCKAnyTask], OCKStoreError>) -> Void)? = nil
    ) {
        do {
            try findStore(forTasks: tasks).deleteAnyTasks(tasks, callbackQueue: callbackQueue, completion: completion)
        } catch {
            callbackQueue.async {
                completion?(.failure(.deleteFailed(
                    reason: "Failed to find store accepting tasks. Error: \(error.localizedDescription)")))
            }
        }
    }

    private func findStore(forTasks tasks: [OCKAnyTask]) throws -> OCKAnyTaskStore {
        let matchingStores = tasks.compactMap { task in eventStores.first(where: { taskStore($0, shouldHandleWritingTask: task) }) }
        guard matchingStores.count == tasks.count else { throw OCKStoreError.invalidValue(reason: "No store could be found for some tasks.") }
        guard let store = matchingStores.first else { throw OCKStoreError.invalidValue(reason: "No store could be found for any tasks.") }
        guard matchingStores.allSatisfy({ $0 === store }) else { throw OCKStoreError.invalidValue(reason: "Not all tasks belong to same store.") }
        return store
    }
}
