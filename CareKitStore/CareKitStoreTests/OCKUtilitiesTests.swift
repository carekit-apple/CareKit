/*
 Copyright (c) 2016-2026, Apple Inc. All rights reserved.
 
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

@testable import CareKitStore
import Foundation
import Testing

struct OCKUtilitiesTests {

    private typealias Closure<Failure: Error> = (@Sendable @escaping (Result<Int, Failure>) -> Void) -> Void

    private var queuesToTest: [DispatchQueue] = [
        DispatchQueue.main,
        DispatchQueue(label: "WorkQueue")
    ]

    @Test
    func aggregatingClosuresSucceeds() {

        for queue in queuesToTest {

            let success1: Closure<MockError> = { $0(.success(1)) }
            let success2: Closure<MockError> = { $0(.success(2)) }
            let success3: Closure<MockError> = { $0(.success(3)) }

            let closures = [success1, success2, success3]

            aggregate(closures, callbackQueue: queue) { result in

                dispatchPrecondition(condition: .onQueue(queue))

                switch result {
                case let .success(successValues):
                    #expect(Set(successValues) == Set([1, 2, 3]))
                case let .failure(error):
                    Issue.record(error)
                }
            }
        }
    }

    @Test
    func aggregatingClosuresFails() {

        for queue in queuesToTest {

            let success1: Closure<MockError> = { $0(.success(1)) }
            let success2: Closure<MockError> = { $0(.success(2)) }
            let failure1: Closure<MockError> = { $0(.failure(MockError())) }
            let failure2: Closure<MockError> = { $0(.failure(MockError())) }

            let closures = [failure1, success1, success2, failure2]

            aggregate(closures, callbackQueue: queue) { result in

                dispatchPrecondition(condition: .onQueue(queue))

                switch result {
                case .success:
                    Issue.record("Expected to fail")
                case let .failure(error):
                    #expect(error == MockError())
                }
            }
        }
    }

    @Test
    func firstValidResultIsSuccessWhenAllClosuresSucceed() {

        for queue in queuesToTest {

            // Order of the chosen result is non-deterministic, so setting all success values to 1 to make tetsing easier
            let success1: Closure<OCKStoreError> = { $0(.success(1)) }
            let success2: Closure<OCKStoreError> = { $0(.success(1)) }
            let success3: Closure<OCKStoreError> = { $0(.success(1)) }

            let closures = [success1, success2, success3]

            getFirstValidResult(closures, callbackQueue: queue) { result in

                dispatchPrecondition(condition: .onQueue(queue))

                switch result {
                case let .success(value):
                    #expect(value == 1)
                case let .failure(error):
                    Issue.record(error)
                }
            }
        }
    }

    @Test
    func firstValidResultIsSuccessWhenSomeClosuresSucceed() {

        for queue in queuesToTest {

            // Order of the chosen result is non-deterministic, so setting all success values to 1 to make tetsing easier
            let failure1: Closure<OCKStoreError> = { $0(.failure(OCKStoreError.addFailed(reason: ""))) }
            let success2: Closure<OCKStoreError> = { $0(.success(1)) }
            let success3: Closure<OCKStoreError> = { $0(.success(1)) }

            let closures = [failure1, success2, success3]

            getFirstValidResult(closures, callbackQueue: queue) { result in

                dispatchPrecondition(condition: .onQueue(queue))

                switch result {
                case let .success(value):
                    #expect(value == 1)
                case let .failure(error):
                    Issue.record(error)
                }
            }
        }
    }

    @Test
    func firstValidResultIsFailureWhenAllClosuresFail() {

        for queue in queuesToTest {

            let failure1: Closure<OCKStoreError> = { $0(.failure(OCKStoreError.addFailed(reason: ""))) }
            let failure2: Closure<OCKStoreError> = { $0(.failure(OCKStoreError.addFailed(reason: ""))) }
            let failure3: Closure<OCKStoreError> = { $0(.failure(OCKStoreError.addFailed(reason: ""))) }

            let closures = [failure1, failure2, failure3]

            getFirstValidResult(closures, callbackQueue: queue) { result in

                dispatchPrecondition(condition: .onQueue(queue))

                switch result {
                case .success:
                    Issue.record("Expected to fail")
                case let .failure(error):
                    #expect(error == .invalidValue(reason: "All of the operations failed."))
                }
            }
        }
    }
}

private struct MockError: Error, Hashable {}
