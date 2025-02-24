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

/// A wrapper around HealthKit that allows for starting and stopping a live query of samples.
@available(iOS 15, watchOS 8, *)
final class HealthKitQueryMonitor: QueryMonitor {

    private let store: HKHealthStore
    private let queryDescriptors: [HKQueryDescriptor]

    private var query: HKAnchoredObjectQuery?
    private var anchor: HKQueryAnchor?

    var resultHandler: (Result<QueryResult, Error>) -> Void = { _ in }

    /// A wrapper around HealthKit that allows for starting and stopping a live query of samples.
    init(
        queryDescriptors: [HKQueryDescriptor],
        store: HKHealthStore
    ) {
        self.queryDescriptors = queryDescriptors
        self.store = store
    }

    func startQuery() {

        // Don't perform the query again if it's already running
        guard query == nil else { return }

        // Only perform query if there are one or more descriptors.
        guard queryDescriptors.count > 0 else { return }

        // Create a query for the initial results
        query = HKAnchoredObjectQuery(
            queryDescriptors: queryDescriptors,
            anchor: anchor,
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
        query!.updateHandler = { [weak self] _, samples, deletedObjects, anchor, error in

            self?.handleQueryResult(
                samples: samples,
                deletedObjects: deletedObjects,
                anchor: anchor,
                error: error
            )
        }

        store.execute(query!)
    }

    func stopQuery() {
        guard let query = query else { return }
        store.stop(query)
        self.query = nil
    }

    private func handleQueryResult(
        samples: [HKSample]?,
        deletedObjects: [HKDeletedObject]?,
        anchor: HKQueryAnchor?,
        error: Error?
    ) {
        // Update the anchors to ensure the next update does not contain
        // duplicate samples
        self.anchor = anchor

        // Note, when an error is encountered, the result handler will not get called again
        if let error = error {
            resultHandler(.failure(error))
            return
        }

        let result = QueryResult(
            samples: samples ?? [],
            deletedObjects: deletedObjects ?? []
        )

        resultHandler(.success(result))
    }
}
