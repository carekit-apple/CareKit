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

// Note:
//
// This class is a mechanism for wrapping another sequence, allowing us to
// hide the implementation details of the wrapped sequence from the public API.
//
// For example, the standard Concurrency map function yields (notice the type information):
//
// ```
// let stream: AsyncStream<Int> = makeSomeIntStream()
// let transformedStream: AsyncMapSequence<AsyncStream<Int>, Double> = stream.map { Double($0) }
// ```
//
// Notice how the type information exposes the implementation details to the consumer.
// To hide that away, we can wrap the transformed stream:
//
// let finalStream: CareStoreQueryResults<Double> = CareStoreQueryResults(sequence: transformedStream)
// ```

/// A continuous stream of entities that exist in a CareKit store.
///
/// You can't instantiate this stream directly. Instead, use methods like ``OCKReadableTaskStore/tasks(matching:)`` to create
/// one. Similarly named methods exist for streaming other entities in a store.
public struct CareStoreQueryResults<Result>: AsyncSequence, Sendable {

    public struct AsyncIterator: AsyncIteratorProtocol {

        let _next: () async throws -> [Result]?

        init<I: AsyncIteratorProtocol>(wrapping wrappedIterator: I) where I.Element == [Result] {

            var mutableWrappedIterator = wrappedIterator

            _next = {
                try await mutableWrappedIterator.next()
            }
        }

        public mutating func next() async throws -> [Result]? {
            return try await _next()
        }
    }

    private let _makeAsyncIterator: @Sendable () -> AsyncIterator

    init<S: AsyncSequence & Sendable>(wrapping wrappedSequence: S) where S.Element == [Result] {
        _makeAsyncIterator = {
            return AsyncIterator(wrapping: wrappedSequence.makeAsyncIterator())
        }
    }

    public func makeAsyncIterator() -> AsyncIterator {
        return _makeAsyncIterator()
    }
}
