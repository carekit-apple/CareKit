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

public extension OCKHealthKitPassthroughStore {

    func fetchEvents(
        query: OCKEventQuery,
        callbackQueue: DispatchQueue = .main,
        completion: @escaping OCKResultClosure<[Event]>
    ) {

        let taskQuery = query.taskQuery

        fetchEvents(
            query: taskQuery,
            callbackQueue: callbackQueue,
            fetchSamples: fetchHealthKitSamples,
            updateCumulativeSumOfSamples: updateCumulativeSumOfHealthKitSamples
        ) { result in

            let resultWithStoreError = result.mapError {
                OCKStoreError.fetchFailed(reason: $0.localizedDescription)
            }

            callbackQueue.async {
                completion(resultWithStoreError)
            }
        }
    }
}

extension OCKHealthKitPassthroughStore {

    /// Test seam. Allows us to abstract HK out of the business logic.
    func fetchEvents(
        query: OCKTaskQuery,
        callbackQueue: DispatchQueue,
        fetchSamples: @Sendable @escaping (
            _ events: [Event],
            _ completion: @Sendable @escaping (Result<[Sample], Error>) -> Void
        ) -> Void,
        updateCumulativeSumOfSamples: @escaping UpdateCumulativeSumOfSamples,
        completion: @Sendable @escaping (Result<[Event], Error>) -> Void
    ) {

        fetchPartialEvents(
            query: query,
            callbackQueue: callbackQueue
        ) { result in

            switch result {

            case let .success(partialEvents):

                let events = partialEvents.map(self.makeEvent)

                self.fetchOutcomes(
                    events: events,
                    fetchSamples: fetchSamples,
                    updateCumulativeSumOfSamples: updateCumulativeSumOfSamples,
                    completion: completion
                )

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    private func fetchOutcomes(
        events: [Event],
        fetchSamples: @escaping @Sendable (
            _ events: [Event],
            _ completion: @escaping @Sendable (Result<[Sample], Error>) -> Void
        ) -> Void,
        updateCumulativeSumOfSamples: @escaping @Sendable (
            _ events: [Event],
            _ completion: @escaping @Sendable (Result<[Event], Error>) -> Void
        ) -> Void,
        completion: @escaping @Sendable (Result<[Event], Error>) -> Void
    ) {

        fetchSamples(events) { samplesResult in

            switch samplesResult {

            case let .success(samples):

                let sampleChange = SampleChange(addedSamples: samples)

                self.updateEvents(
                    events,
                    applyingChange: sampleChange,
                    updateCumulativeSumOfSamples: updateCumulativeSumOfSamples,
                    completion: completion
                )

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}
