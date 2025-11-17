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

@testable import CareKit
@testable import CareKitStore

import AsyncAlgorithms
import Combine
import XCTest

class TestCareStoreFetchRequestController: XCTestCase {

    private let query = MockQuery(id: 0)

    private var store = OCKStore(name: "test-store", type: .inMemory)

    private var handleFetchedResults: AnyCancellable?

    override func setUpWithError() throws {
        try super.setUpWithError()
        try store.reset()
    }

    // MARK: - Streaming result

    func testInitialFetchedResults() {

        let query = MockQuery()
        let results = [[Int]]().async
        let wrappedResults = CareStoreQueryResults(wrapping: results)

        let controller = CareStoreFetchRequestController<Int, MockQuery>(
            query: query,
            getID: { _ in "" },
            getResults: { _, _ in wrappedResults }
        )

        XCTAssertTrue(controller.fetchedResults.storage.isEmpty)
    }

    func testStreamResult_DoesNotStreamRedundantQuery() {

        let query = MockQuery()
        let results = [[1]]

        let controller = CareStoreFetchRequestController<Int, MockQuery>(
            query: query,
            getID: { _ in "" },
            getResults: { _, _ in
                return CareStoreQueryResults(wrapping: results.async)
            }
        )

        let didStreamResult = XCTestExpectation(description: "Result streamed")
        didStreamResult.assertForOverFulfill = true

        handleFetchedResults = controller.$fetchedResults
            // Drop the initial value of the published property, and wait until new data comes through the stream
            .dropFirst()
            .sink { [unowned self] _ in
                didStreamResult.fulfill()
                controller.streamResults(from: store)
            }

        controller.streamResults(from: store)

        wait(for: [didStreamResult], timeout: 1)
    }

    func testStreamResult_StreamsQuery() {

        let query = MockQuery()
        let results = [[1, 2]]

        let controller = CareStoreFetchRequestController<Int, MockQuery>(
            query: query,
            getID: { _ in "" },
            getResults: { _, _ in
                return CareStoreQueryResults(wrapping: results.async)
            }
        )

        let expectedResults: [Set<CareStoreFetchedResult<Int>>] = [
            [],
            [
                CareStoreFetchedResult(id: "", result: 1, store: store),
                CareStoreFetchedResult(id: "", result: 2, store: store)
            ]
        ]

        var observedResults: [Set<CareStoreFetchedResult<Int>>] = []

        let didStreamResult = XCTestExpectation(description: "Result streamed")
        didStreamResult.assertForOverFulfill = true
        didStreamResult.expectedFulfillmentCount = expectedResults.count

        handleFetchedResults = controller.$fetchedResults.sink { fetchedResults in

            let storage = fetchedResults?.storage ?? []
            observedResults.append(Set(storage))
            didStreamResult.fulfill()
        }

        controller.streamResults(from: store)

        wait(for: [didStreamResult], timeout: 1)

        XCTAssertEqual(observedResults, expectedResults)
    }

    func testRestreamsResultWhenQueryChanges() {

        // Create two unequal queries
        let query = MockQuery(id: 0)
        let newQuery = MockQuery(id: 1)

        let results = [[1, 2]]

        let controller = CareStoreFetchRequestController<Int, MockQuery>(
            query: query,
            getID: { _ in "" },
            getResults: { _, _ in
                return CareStoreQueryResults(wrapping: results.async)
            }
        )

        let expectedResults = [
            [
                CareStoreFetchedResult(id: "", result: 1, store: store),
                CareStoreFetchedResult(id: "", result: 2, store: store)
            ],
            [
                CareStoreFetchedResult(id: "", result: 1, store: store),
                CareStoreFetchedResult(id: "", result: 2, store: store)
            ]
        ]

        var observedResults: [[CareStoreFetchedResult<Int>]] = []

        let didStreamResult = XCTestExpectation(description: "Result streamed")
        didStreamResult.assertForOverFulfill = true
        didStreamResult.expectedFulfillmentCount = expectedResults.count

        handleFetchedResults = controller.$fetchedResults
            .dropFirst()
            .sink { fetchedResults in

                let storage = fetchedResults?.storage ?? []
                observedResults.append(storage)

                // Update the query. That will trigger a new computation of `fetchedResults`.
                controller.update(query: newQuery)

                didStreamResult.fulfill()
            }

        controller.streamResults(from: store)

        wait(for: [didStreamResult], timeout: 1)

        XCTAssertEqual(observedResults, expectedResults)
    }

    func testRestreamsWhenStoreChanges() {

        let newStore = OCKStore(name: "newStore")

        let query = MockQuery(id: 0)

        let results = [[1, 2]]

        let controller = CareStoreFetchRequestController<Int, MockQuery>(
            query: query,
            getID: { _ in "" },
            getResults: { _, _ in
                return CareStoreQueryResults(wrapping: results.async)
            }
        )

        let expectedResults = [
            [
                CareStoreFetchedResult(id: "", result: 1, store: store),
                CareStoreFetchedResult(id: "", result: 2, store: store)
            ],
            [
                CareStoreFetchedResult(id: "", result: 1, store: newStore),
                CareStoreFetchedResult(id: "", result: 2, store: newStore)
            ]
        ]

        var observedResults: [[CareStoreFetchedResult<Int>]] = []

        let didStreamResult = XCTestExpectation(description: "Result streamed")
        didStreamResult.assertForOverFulfill = true
        didStreamResult.expectedFulfillmentCount = expectedResults.count

        handleFetchedResults = controller.$fetchedResults
            .dropFirst()
            .sink { fetchedResults in

                let storage = fetchedResults?.storage ?? []
                observedResults.append(storage)

                // Update the store. That will trigger a new computation of `fetchedResults`.
                controller.streamResults(from: newStore)

                didStreamResult.fulfill()
            }

        controller.streamResults(from: store)

        wait(for: [didStreamResult], timeout: 1)

        XCTAssertEqual(observedResults, expectedResults)
    }

    func testDoesNotRestreamsWhenStoreIsUnchanged() {

        let query = MockQuery(id: 0)
        let results = [[1, 2]]

        let controller = CareStoreFetchRequestController<Int, MockQuery>(
            query: query,
            getID: { _ in "" },
            getResults: { _, _ in
                return CareStoreQueryResults(wrapping: results.async)
            }
        )

        let expectedResults = [
            [
                CareStoreFetchedResult(id: "", result: 1, store: store),
                CareStoreFetchedResult(id: "", result: 2, store: store)
            ]
        ]

        var observedResults: [[CareStoreFetchedResult<Int>]] = []

        let didStreamResult = XCTestExpectation(description: "Result streamed")
        didStreamResult.assertForOverFulfill = true
        didStreamResult.expectedFulfillmentCount = expectedResults.count

        handleFetchedResults = controller.$fetchedResults
            .dropFirst()
            .sink { fetchedResults in

                let storage = fetchedResults?.storage ?? []
                observedResults.append(storage)

                // Stream from the same store. That will not trigger a new computation of `fetchedResults`.
                controller.streamResults(from: self.store)

                didStreamResult.fulfill()
            }

        controller.streamResults(from: store)

        wait(for: [didStreamResult], timeout: 1)

        XCTAssertEqual(observedResults, expectedResults)
    }

    // MARK: - Query

    func testGetQuery_ReturnsPendingQuery() {

        let query = MockQuery()

        let controller = CareStoreFetchRequestController<Int, MockQuery>(
            query: query,
            getID: { _ in "" },
            getResults: { _, _ in

                let values = [[Int]]().async
                return CareStoreQueryResults(wrapping: values)
            }
        )

        XCTAssertEqual(controller.query, query)
    }

    func testGetQuery_ReturnsStreamingQuery() {

        let query = MockQuery()

        let controller = CareStoreFetchRequestController<Int, MockQuery>(
            query: query,
            getID: { _ in "" },
            getResults: { _, _ in

                let values = [[Int]]().async
                return CareStoreQueryResults(wrapping: values)
            }
        )

        controller.streamResults(from: store)

        XCTAssertEqual(controller.query, query)
    }

    func testGetQuery_ReturnsUpdatedPendingQuery() {

        let query = MockQuery(id: 0)
        let newQuery = MockQuery(id: 1)

        let controller = CareStoreFetchRequestController<Int, MockQuery>(
            query: query,
            getID: { _ in "" },
            getResults: { _, _ in

                let values = [[Int]]().async
                return CareStoreQueryResults(wrapping: values)
            }
        )

        controller.update(query: newQuery)

        XCTAssertEqual(controller.query, newQuery)
    }

    func testGetQuery_ReturnsUpdatedStreamingQuery() {

        let query = MockQuery(id: 0)
        let newQuery = MockQuery(id: 1)

        let controller = CareStoreFetchRequestController<Int, MockQuery>(
            query: query,
            getID: { _ in "" },
            getResults: { _, _ in

                let values = [[Int]]().async
                return CareStoreQueryResults(wrapping: values)
            }
        )

        controller.streamResults(from: store)
        controller.update(query: newQuery)

        XCTAssertEqual(controller.query, newQuery)
    }
}

private struct MockQuery: Equatable {
    var id = 0
}
