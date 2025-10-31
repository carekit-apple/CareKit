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

    public func anyOutcomes(matching query: OCKOutcomeQuery) -> CareStoreQueryResults<OCKAnyOutcome> {

        let relevantStores = storesHandlingQuery(query)

        let outcomesStreams = relevantStores.map {
            $0.anyOutcomes(matching: query)
        }

        let outcomes = combineMany(
            sequences: outcomesStreams,
            makeSortDescriptors: {

                let sortDescriptor = NSSortDescriptor(
                    keyPath: \OCKCDOutcome.id,
                    ascending: true
                )

                return [sortDescriptor]
            }
        )

        return outcomes
    }

    public func fetchAnyOutcomes(
        query: OCKOutcomeQuery,
        callbackQueue: DispatchQueue = .main,
        completion: @escaping @Sendable (Result<[OCKAnyOutcome], OCKStoreError>) -> Void
    ) {

        let respondingStores = storesHandlingQuery(query)
        let closures = respondingStores.map({ store in { done in
            store.fetchAnyOutcomes(query: query, callbackQueue: callbackQueue, completion: done) }
        })
        aggregateAndFlatten(closures, callbackQueue: callbackQueue, completion: completion)
    }

    public func addAnyOutcomes(
        _ outcomes: [OCKAnyOutcome],
        callbackQueue: DispatchQueue = .main,
        completion: (@Sendable (Result<[OCKAnyOutcome], OCKStoreError>) -> Void)? = nil
    ) {
        do {
            let store = try firstStoreHandlingOutcomes(outcomes)
            store.addAnyOutcomes(outcomes, callbackQueue: callbackQueue, completion: completion)
        } catch {
            callbackQueue.async {
                completion?(.failure(.addFailed(
                    reason: "Failed to find store accepting outcomes. Error: \(error.localizedDescription)")))
            }
        }
    }

    public func updateAnyOutcomes(
        _ outcomes: [OCKAnyOutcome],
        callbackQueue: DispatchQueue = .main,
        completion: (@Sendable (Result<[OCKAnyOutcome], OCKStoreError>) -> Void)? = nil
    ) {
        do {
            let store = try firstStoreHandlingOutcomes(outcomes)
            store.updateAnyOutcomes(outcomes, callbackQueue: callbackQueue, completion: completion)
        } catch {
            callbackQueue.async {
                completion?(.failure(.updateFailed(
                    reason: "Failed to find store accepting outcomes. Error: \(error.localizedDescription)")))
            }
        }
    }

    public func deleteAnyOutcomes(
        _ outcomes: [OCKAnyOutcome],
        callbackQueue: DispatchQueue = .main,
        completion: (@Sendable (Result<[OCKAnyOutcome], OCKStoreError>) -> Void)? = nil
    ) {
        do {
            let store = try firstStoreHandlingOutcomes(outcomes)
            store.deleteAnyOutcomes(outcomes, callbackQueue: callbackQueue, completion: completion)
        } catch {
            callbackQueue.async {
                completion?(.failure(.deleteFailed(
                    reason: "Failed to find store accepting outcomes. Error: \(error.localizedDescription)")))
            }
        }
    }

    private func firstStoreHandlingOutcomes(_ outcomes: [OCKAnyOutcome]) throws -> OCKAnyOutcomeStore {

        let firstMatchingStore = state.withLock { state in

            return state.eventStores.first { store in
                return outcomes.allSatisfy { outcome in
                    return
                        state.delegate?.outcomeStore(store, shouldHandleWritingOutcome: outcome) ??
                        outcomeStore(store, shouldHandleWritingOutcome: outcome)
                }
            }
        }

        guard let firstMatchingStore else {
            throw OCKStoreError.invalidValue(reason: "Cannot find store to handle outcomes")
        }

        return firstMatchingStore
    }

    private func storesHandlingQuery(_ query: OCKOutcomeQuery) -> [OCKAnyReadOnlyOutcomeStore] {

        return state.withLock { state in

            let stores = state.readOnlyEventStores + state.eventStores

            let respondingStores = stores.filter { store in
                return
                    state.delegate?.outcomeStore(store, shouldHandleQuery: query) ??
                    outcomeStore(store, shouldHandleQuery: query)
            }

            return respondingStores
        }
    }
}
