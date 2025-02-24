/*
 Copyright (c) 2021, Apple Inc. All rights reserved.
 
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

import CareKitStore
import SwiftUI

/// An observable object that holds the result state for the `CareStoreFetchRequest` struct.
///
/// - The result is deferred until `streamResult(store:)` is explicitly called.
///
/// - Updates to the fetched result will trigger a view update.
///
/// - The result is generic, and is computed based on the provided `Result`.
///   Going the generic route allows us to create a single controller for all of the entity types in the CareKit store.
final class CareStoreFetchRequestController<Result, Query>: ObservableObject {

    typealias ComputeResults = (
        _ query: Query,
        _ store: OCKAnyStoreProtocol
    ) -> CareStoreQueryResults<Result>

    /// The result fetched from the CareKit store.
    @Published
    private(set) var fetchedResults: CareStoreFetchedResults<Result, Query>!

    /// The current query that is either being performed, or waiting to be performed. If the query
    /// has not yet been performed, see `streamResults(store:)` to begin the fetching process.
    var query: Query {
        switch streamStatus {
        case let .pending(query): return query
        case let .streaming(query, _, _): return query
        }
    }

    /// The status of the data stream from the CareKit store. If the data is not yet streaming, see
    /// `streamResult(store:)` to begin the fetching process.
    private var streamStatus: StreamStatus

    private let getID: (Result) -> String
    private let getResults: ComputeResults

    /// True if two queries are equal. This can be used as an optimization
    /// to avoid streaming unnecessary queries.
    private let areQueriesEqual: (
        _ lhs: Query,
        _ rhs: Query
    ) -> Bool

    init(
        query: Query,
        getID: @escaping (Result) -> String,
        getResults: @escaping ComputeResults,
        areQueriesEqual: @escaping (_ lhs: Query, _ rhs: Query) -> Bool
    ) {
        self.streamStatus = .pending(query: query)
        self.getID = getID
        self.getResults = getResults
        self.areQueriesEqual = areQueriesEqual

        fetchedResults = CareStoreFetchedResults(
            storage: [],
            setQuery: { [unowned self] in update(query: $0) },
            getQuery: { [unowned self] in self.query }
        )
    }

    deinit {
        cancelStreamingTask()
    }

    /// Update the current query that is either pending or streaming. If the query is pending
    /// make sure to call `streamResults(store:)` explicitly to begin the streaming process.
    func update(query: Query) {

        switch streamStatus {
        case let .streaming(_, store, _):
            streamResults(query: query, store: store)
        case .pending:
            streamStatus = .pending(query: query)
        }
    }

    /// Stream data from a CareKit store based on the current query. See `fetchedResults` for the
    /// results of the fetching process. This method is optimized and safe to call multiple times.
    func streamResults(from store: OCKAnyStoreProtocol) {
        streamResults(query: query, store: store)
    }

    private func streamResults(
        query: Query,
        store: OCKAnyStoreProtocol
    ) {

        // Don't re-stream the same results
        let shouldStreamResults = shouldStreamResults(matching: query, store: store)
        guard shouldStreamResults else { return }

        log(.debug, "Beginning to stream data from the store")

        // Cancel the current task streaming results
        cancelStreamingTask()

        let streamingTask = Task {

            let results = getResults(query, store)

            for try await results in results {
                try Task.checkCancellation()
                await updateResults(results, from: store)
            }
        }

        streamStatus = .streaming(
            query: query,
            store: store,
            task: streamingTask
        )
    }

    private func cancelStreamingTask() {

        switch streamStatus {
        case let .streaming(_, _, task):
            task.cancel()
        case .pending:
            break
        }
    }

    private func shouldStreamResults(
        matching query: Query,
        store: OCKAnyStoreProtocol
    ) -> Bool {

        switch streamStatus {

        case let .streaming(streamingQuery, streamingStore, _):

            let isQueryNew = areQueriesEqual(streamingQuery, query) == false
            let isStoreNew = store !== streamingStore

            return isQueryNew || isStoreNew

        case .pending:
            return true
        }
    }

    @MainActor
    private func updateResults(
        _ results: [Result],
        from store: OCKAnyStoreProtocol
    ) {

        let fetchedResults = results.map { result in

            return CareStoreFetchedResult(
                id: getID(result),
                result: result,
                store: store
            )
        }

        let batchedResult = CareStoreFetchedResults(
            storage: fetchedResults,
            setQuery: { [unowned self] in update(query: $0) },
            getQuery: { [unowned self] in query }
        )

        self.fetchedResults = batchedResult
    }
}

private extension CareStoreFetchRequestController {

    /// The status of a data stream from the CareKit store.
    enum StreamStatus {

        /// Streaming data from a CareKit store.
        case streaming(
            query: Query,
            store: OCKAnyStoreProtocol,
            task: Task<Void, Error>
        )

        /// Waiting to stream data from a CareKit store.
        case pending(query: Query)
    }
}

// When the `Query` conforms to `Equatable`, we can avoid streaming
// duplicate queries. We could avoid this indirection by making the
// original generic conform to Equatable, but that locks us into that
// conformance in the public API.
extension CareStoreFetchRequestController where Query: Equatable {

    convenience init(
        query: Query,
        getID: @escaping (Result) -> String,
        getResults: @escaping ComputeResults
    ) {
        self.init(
            query: query,
            getID: getID,
            getResults: getResults,
            areQueriesEqual: { $0 == $1 }
        )
    }
}
