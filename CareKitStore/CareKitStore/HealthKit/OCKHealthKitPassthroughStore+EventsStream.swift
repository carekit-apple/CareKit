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

import AsyncAlgorithms
import Foundation
import os.log

@available(iOS 15, watchOS 8, *)
public extension OCKHealthKitPassthroughStore {

    func events(matching query: OCKEventQuery) -> CareStoreQueryResults<OCKEvent<Task, Outcome>> {

        // Overrides the default `events(matching:)`. The default implementation
        // fetches partial events and outcomes separately. The HK store implementation
        // requires that we fetch partial events *when* we fetch outcomes, so if we
        // relied on the default implementation we would be doing redundant fetching of
        // partial events.

        let taskQuery = query.taskQuery

        let events = events(
            matching: taskQuery,
            applyingChanges: healthKitSampleChanges,
            updateCumulativeSumOfSamples: updateCumulativeSumOfHealthKitSamples
        )
        .removeDuplicates()

        let wrappedEvents = CareStoreQueryResults(wrapping: events)
        return wrappedEvents
    }
}

@available(iOS 15, watchOS 8, *)
extension OCKHealthKitPassthroughStore {


    // Test seam. Allows us to abstract HK out of the business logic.
    // Returns `some AsyncSequence where Element == [Event]`
    func events<SampleChanges: AsyncSequence>(
        matching query: OCKTaskQuery,
        applyingChanges changes: @escaping ([Event]) -> SampleChanges,
        updateCumulativeSumOfSamples: @escaping UpdateCumulativeSumOfSamples
    ) -> AsyncFlatMapSequence<AsyncMapSequence<AsyncMapSequence<
        AsyncThrowingMapSequence<CareStoreQueryResults<OCKHealthKitTask>, [[OCKHealthKitPassthroughStore.Task]]>, [PartialEvent<OCKHealthKitPassthroughStore.Task>]>, [OCKHealthKitPassthroughStore.Event]>, AsyncThrowingExclusiveReductionsSequence<AsyncChain2Sequence<AsyncLazySequence<[SampleChange]>, SampleChanges>, [OCKHealthKitPassthroughStore.Event]>
    > where SampleChanges.Element == SampleChange {


        // Compute partial event data
        let partialEvents = partialEvents(matching: query)

        // Use the partial event data to compute full events
        let events = partialEvents.map { partialEvents in
            partialEvents.map(self.makeEvent)
        }

        // Update the outcomes for each event based on the new HealthKit sample changes
        let updatedEvents = events.flatMap { events in

            let initialChanges = [SampleChange()].async
            let seededChanges = chain(initialChanges, changes(events))

            // Continuously update the outcomes for the events when new HealthKit
            // sample changes are received. We seed the streaming changes in case there actually
            // no changes that are streamed. In that case, the `events` never get reduced into
            // a final result.
            let updatedEvents = seededChanges.reductions(into: events) { currentEvents, change in

                // Update the outcomes for the events with the new sample changes
                let updatedEvents = try await self.updateEvents(
                    currentEvents,
                    applyingChange: change,
                    updateCumulativeSumOfSamples: updateCumulativeSumOfSamples
                )

                currentEvents = updatedEvents
            }

            return updatedEvents
        }

        return updatedEvents
    }

    private func updateEvents(
        _ events: [Event],
        applyingChange change: SampleChange,
        updateCumulativeSumOfSamples: @escaping UpdateCumulativeSumOfSamples
    ) async throws -> [Event] {

        return try await withCheckedThrowingContinuation { continuation in

            updateEvents(
                events,
                applyingChange: change,
                updateCumulativeSumOfSamples: updateCumulativeSumOfSamples,
                completion: continuation.resume
            )
        }
    }
}
