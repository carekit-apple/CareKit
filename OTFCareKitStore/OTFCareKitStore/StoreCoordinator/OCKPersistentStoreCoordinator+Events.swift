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

    open func fetchAnyEvents(taskID: String, query: OCKEventQuery, callbackQueue: DispatchQueue,
                             completion: @escaping OCKResultClosure<[OCKAnyEvent]>) {
        findStore(taskID: taskID) { result in
            switch result {
            case .failure(let error):
                callbackQueue.async { completion(.failure(error)) }
            case .success(let store):
                store.fetchAnyEvents(taskID: taskID, query: query, callbackQueue: callbackQueue, completion: completion)
            }
        }
    }

    open func fetchAnyEvent(forTask task: OCKAnyTask, occurrence: Int, callbackQueue: DispatchQueue,
                            completion: @escaping OCKResultClosure<OCKAnyEvent>) {
        let closures = eventStores.map({ store in { done in
            store.fetchAnyEvent(forTask: task, occurrence: occurrence, callbackQueue: callbackQueue, completion: done)
        } })
        getFirstValidResult(closures, callbackQueue: callbackQueue, completion: completion)
    }

    // Determines which store holds the task with a given id.
    private func findStore(taskID: String, completion: @escaping OCKResultClosure<OCKAnyReadOnlyEventStore>) {
        let group = DispatchGroup()
        var respondingStore: OCKAnyReadOnlyEventStore?

        for store in eventStores + readOnlyEventStores {
            group.enter()
            store.fetchAnyTask(withID: taskID, callbackQueue: .main) { result in
                switch result {
                case .failure:
                    // The store didn't contain the task. (Fetching a task by id errors if there is no match)
                    break
                case .success:
                    assert(respondingStore == nil, "Two stores should never contain tasks with the same id!")
                    respondingStore = store
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            guard let store = respondingStore else {
                completion(.failure(.fetchFailed(
                    reason: "Unable to find a task with the given id.")))
                return
            }

            completion(.success(store))
        }
    }
}
