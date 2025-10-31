/*
 Copyright (c) 2022, Apple Inc. All rights reserved.
 
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
import Synchronization

/// A wrapper around HealthKit that allows for starting and stopping a live query of samples.
final class HealthKitQueryMonitor: Sendable {

    private struct State {
        var query: HKAnchoredObjectQuery?
        var anchor: HKQueryAnchor?
    }

    private let store: HKHealthStore
    private let queryDescriptors: [HKQueryDescriptor]
    private let state = Mutex(State())
    private let resultHandler: @Sendable (Result<QueryResult, Error>) -> Void

    /// A wrapper around HealthKit that allows for starting and stopping a live query of samples.
    init(
        queryDescriptors: [HKQueryDescriptor],
        store: HKHealthStore,
        resultHandler: @Sendable @escaping (Result<QueryResult, Error>) -> Void = { _ in }
    ) {
        self.queryDescriptors = queryDescriptors
        self.store = store
        self.resultHandler = resultHandler
    }

    func startQuery() {

        state.withLock { state in

            guard
                // Don't perform the query again if it's already running
                state.query == nil,
                // Only perform query if there are one or more descriptors else we'll hit a runtime crash.
                queryDescriptors.isEmpty == false
            else {
                return
            }

            // Create a query for the initial results
            state.query = HKAnchoredObjectQuery(
                queryDescriptors: queryDescriptors,
                anchor: state.anchor,
                limit: HKObjectQueryNoLimit,
                resultsHandler: { [weak self] _, samples, deletedObjects, anchor, error in

                    self?.handleQueryResult(
                        samples: samples,
                        deletedObjects: deletedObjects,
                        anchor: anchor,
                        error: error
                    )
                }
            )

            // Forward subsequent changes to the result
            state.query!.updateHandler = { [weak self] _, samples, deletedObjects, anchor, error in

                self?.handleQueryResult(
                    samples: samples,
                    deletedObjects: deletedObjects,
                    anchor: anchor,
                    error: error
                )
            }

            store.execute(state.query!)
        }
    }

    func stopQuery() {

        state.withLock { state in

            guard let query = state.query else {
                return
            }

            store.stop(query)
            state.query = nil
        }
    }

    private func handleQueryResult(
        samples: [HKSample]?,
        deletedObjects: [HKDeletedObject]?,
        anchor: HKQueryAnchor?,
        error: Error?
    ) {

        // Note, when an error is encountered, the result handler will not get called again
        if let error = error {
            resultHandler(.failure(error))
            return
        }

        let queryResult = state.withLock { state in

            // Update the anchors to ensure the next update does not contain
            // duplicate samples
            state.anchor = anchor

            return QueryResult(
                samples: samples ?? [],
                deletedObjects: deletedObjects ?? []
            )
        }

        resultHandler(.success(queryResult))
    }
}
