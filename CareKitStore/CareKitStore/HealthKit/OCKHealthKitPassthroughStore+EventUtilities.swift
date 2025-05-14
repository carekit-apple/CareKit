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


@available(iOS 15, watchOS 8, macOS 13.0, *)
extension OCKHealthKitPassthroughStore {

    // Element == SampleChange
    typealias SampleChanges = AsyncMapSequence<
        AsyncThrowingStream<HealthKitQueryMonitor.QueryResult, Error>, SampleChange
    >

    typealias UpdateCumulativeSumOfSamples = (
        _ events: [Event],
        _ completion: @escaping (Result<[Event], Error>) -> Void
    ) -> Void

    // This method will update the outcomes for the provided events based on the provided
    // sample changes. The general algorithm is as follows:
    //
    // When we detect new HK samples, we split the samples up by HK quantity type and look for the
    // events that overlap the sample dates.
    //
    // - If the event's task type is "discrete" (EX heart rate values), we will convert the
    // sample to an outcome value and store it in the event's outcome. We will also record
    // the HK sample ID so that we can locate this sample later on if a change occurs.
    //
    // - If the event's task type is "cumulative" (EX steps), we can't just add up the sample
    // values and create an outcome value for the event's outcome. Samples could be duplicates,
    // for example if a sample was recorded from the watch and the phone at the same time. We
    // need to run an HK statistics query to calculate the sum, which takes care of de-duplication.
    // So when we detect a new sample for a "cumulative" event, we store the sample ID for later reference,
    // and mark the outcome as "stale" by setting it to -1. We do that as an optimization - we don't
    // want to run an expensive statistics query each time we detect a new sample, because there may be
    // multiple new samples in this batch of updates that are applied to the same event. By marking the outcome
    // as stale, we can process all of the samples in the batch and then run the necessary statistics queries.
    //
    // When we detect deleted HK samples, we are only given access to the IDs of the deleted samples.
    // We stored the sample IDs in the outcome values, so we can use those to find the necessary
    // outcome values to delete.
    //
    // - If we need to delete an outcome value from a "discrete" event, it is simply removed.
    //
    // - If we need to delete an outcome value from a "cumulative" event, we mark the outcome
    // value as stale.
    //
    // Once we have processed all of the additions and deletions, we are ready to update all outcomes
    // that we have marked as stale. For each stale outcome, we run an HK statistics query to re-compute
    // the sum of the samples for the event.
    func updateEvents(
        _ events: [Event],
        applyingChange change: SampleChange,
        updateCumulativeSumOfSamples: UpdateCumulativeSumOfSamples,
        completion: @escaping (Result<[Event], Error>) -> Void
    ) {

        // Process deleted samples

        var updatedEvents = events

        updatedEvents = events.map { event in
            updateEvent(event, deletedSampleIDs: change.deletedIDs)
        }

        // Process new samples. We partition samples and events by their HK quantity type ensure we
        // can match up samples and events correctly.

        let eventsGroupedByQuantityType = Dictionary(grouping: updatedEvents) {
            extractQuantityType(from: $0.task)
        }

        let addedSamplesGroupedByQuantityType = Dictionary(
            grouping: change.addedSamples,
            by: \.type
        )

        updatedEvents = eventsGroupedByQuantityType.flatMap { quantityType, events -> [Event] in

            let addedSamples = addedSamplesGroupedByQuantityType[quantityType] ?? []

            return events.map { event in
                updateEvent(event, applyingNewSamples: addedSamples)
            }
        }

        // Now that we have processed newly added and deleted samples, we can check
        // which outcomes are stale and update them accordingly

        let eventsWithStaleOutcomes = updatedEvents.filter {
            isOutcomeStale($0.outcome)
        }

        let eventsWithNonStaleOutcomes = updatedEvents.filter {
            isOutcomeStale($0.outcome) == false
        }

        updateCumulativeSumOfSamples(eventsWithStaleOutcomes) { result in

            let allEventsResult = result.map {

                // Combine and sort the events by task effective date then event start date

                let events = eventsWithNonStaleOutcomes + $0

                let eventsSortedByEffectiveThenStart = events
                    .sorted { $0.task.effectiveDate < $1.task.effectiveDate }
                    .sorted { $0.scheduleEvent.start < $1.scheduleEvent.start }

                return eventsSortedByEffectiveThenStart
            }

            completion(allEventsResult)
        }
    }

    /// Update an event's outcome after detecting a batch of new samples.
    private func updateEvent(
        _ event: Event,
        applyingNewSamples samples: [Sample]
    ) -> Event {

        // A sample only affects an event if their date intervals intersect

        let intersectingSamples = samples.filter {
            doesSample($0, intersect: event)
        }

        guard intersectingSamples.isEmpty == false else {
            return event
        }

        // Update the event based on the newly added samples

        var updatedEvent = event

        let type = event.task.healthKitLinkage.quantityType

        switch type {

        case .discrete:
            intersectingSamples.forEach { sample in
                updatedEvent = appendSample(sample, event: updatedEvent)
            }

        case .cumulative:
            intersectingSamples.forEach { sample in
                updatedEvent = invalidateCumulativeOutcome(addedSampleID: sample.id, event: updatedEvent)
            }
        }

        return updatedEvent
    }

    /// Update an event's outcome after detecting a batch of deleted samples.
    private func updateEvent(
        _ event: Event,
        deletedSampleIDs: Set<UUID>
    ) -> Event {

        var updatedEvent = event
        let type = event.task.healthKitLinkage.quantityType

        switch type {

        case .discrete:
            deletedSampleIDs.forEach { id in
                updatedEvent = removeSample(withID: id, from: updatedEvent)
            }

        case .cumulative:
            deletedSampleIDs.forEach { id in
                updatedEvent = invalidateCumulativeOutcome(deletedSampleID: id, event: updatedEvent)
            }
        }

        return updatedEvent
    }

    /// Remove the outcome value that matches the deleted sample ID. We also remove the
    /// stored sample ID that's used to locate the correct outcome value.
    private func removeSample(
        withID id: UUID,
        from event: Event
    ) -> Event {

        var updatedEvent = event

        // Find the index of the outcome value that has the provided sample ID
        guard let indexToRemove = event.outcome?
            .healthKitUUIDs
            .firstIndex(where: { $0.contains(id) })
        else {
            return event
        }

        updatedEvent.outcome?.healthKitUUIDs.remove(at: indexToRemove)
        updatedEvent.outcome?.values.remove(at: indexToRemove)

        // If there are no more outcome values, remove the outcome completely
        if updatedEvent.outcome?.values.isEmpty == true {
            updatedEvent.outcome = nil
        }

        return updatedEvent
    }

    /// Convert a sample to an outcome value and store it on the event's outcome. We also
    /// store the sample ID on the outcome so that we can locate this outcome value later on.
    private func appendSample(
        _ sample: Sample,
        event: Event
    ) -> Event {

        // Convert the sample to an outcome value

        let doubleValue = sample
            .quantity
            .doubleValue(for: event.task.healthKitLinkage.unit)

        var outcomeValue = OCKOutcomeValue(
            doubleValue,
            units: event.task.healthKitLinkage.unit.unitString
        )

        outcomeValue.createdDate = now

        var updatedEvent = event

        // Create an outcome if one doesn't already exist
        updatedEvent.outcome = event.outcome ?? makeOutcome(for: event)

        // Add the outcome value to the outcome
        updatedEvent.outcome?.values.append(outcomeValue)

        // Track the sample ID
        updatedEvent.outcome?.healthKitUUIDs.append([sample.id])

        return updatedEvent
    }

    /// Invalidate the cumulative outcome value for an event because a sample has been deleted
    /// and will affect the sum value. We do store the sample ID for the new sample, but set the outcome
    /// value to -1 to indicate that the sum needs to be recomputed.
    private func invalidateCumulativeOutcome(
        deletedSampleID: UUID,
        event: Event
    ) -> Event {

        var updatedEvent = event

        // Ensure there are existing sample IDs
        guard event.outcome?.healthKitUUIDs.isEmpty == false else {
            updatedEvent.outcome = nil
            return updatedEvent
        }

        guard let indexOfOutcomeValueToInvalidate = event.outcome?
            .healthKitUUIDs
            .firstIndex(where: { $0.contains(deletedSampleID) })
        else {
            return event
        }

        guard let indexOfSampleIDToRemove = event.outcome?
            .healthKitUUIDs[indexOfOutcomeValueToInvalidate]
            .firstIndex(of: deletedSampleID)
        else {
            return event
        }

        // Remove the sample ID
        updatedEvent.outcome?
            .healthKitUUIDs[indexOfOutcomeValueToInvalidate]
            .remove(at: indexOfSampleIDToRemove)

        // Invalidate the outcome value
        updatedEvent.outcome?.values[indexOfOutcomeValueToInvalidate].value = -1

        // If there are no more HK samples linked to this outcome, remove the outcome completely
        if
            updatedEvent.outcome?.healthKitUUIDs.isEmpty == true ||
            updatedEvent.outcome?.healthKitUUIDs[indexOfOutcomeValueToInvalidate].isEmpty == true
        {
            updatedEvent.outcome = nil
        }

        return updatedEvent
    }

    /// Invalidate the cumulative outcome value for an event because a new sample has been added
    /// that will affect the sum value. We do store the sample ID for the new sample, but set the outcome
    /// value to -1 to indicate that the sum needs to be recomputed.
    private func invalidateCumulativeOutcome(
        addedSampleID: UUID,
        event: Event
    ) -> Event {

        var updatedEvent = event

        // Create an outcome if one doesn't already exist
        updatedEvent.outcome = event.outcome ?? makeOutcome(for: event)

        // If there are no outcome values yet, create a new one
        guard
            event.outcome?.values.first != nil &&
            event.outcome?.healthKitUUIDs.first != nil
        else {

            let units = event.task.healthKitLinkage.unit.unitString
            var outcomeValue = OCKOutcomeValue(-1, units: units)
            outcomeValue.createdDate = now

            updatedEvent.outcome?.values.append(outcomeValue)
            updatedEvent.outcome?.healthKitUUIDs.append([addedSampleID])

            return updatedEvent
        }

        // Invalidate the first outcome value
        updatedEvent.outcome?.values[0].value = -1

        // Track the new sample ID
        updatedEvent.outcome?.healthKitUUIDs[0].append(addedSampleID)

        return updatedEvent
    }

    /// A sample intersects an event if the two date intervals intersect.
    private func doesSample(
        _ sample: Sample,
        intersect event: Event
    ) -> Bool {

        // Subtract 1 from the end date to ensure a sample that starts
        // on the event's end date is not considered an intersecting event
        let eventInterval = DateInterval(
            start: event.scheduleEvent.start,
            end: event.scheduleEvent.end - 1
        )

        let doesIntersect = eventInterval.intersects(sample.dateInterval)
        return doesIntersect
    }

    private func extractQuantityType(from task: Task) -> HKQuantityType {
        let quantityID = task.healthKitLinkage.quantityIdentifier
        let quantityType = HKObjectType.quantityType(forIdentifier: quantityID)!
        return quantityType
    }

    /// An outcome is considered stale one of its values is -1, indicating that the outcome
    /// reflects the sum of samples over time and needs to be recomputed.
    private func isOutcomeStale(_ outcome: Outcome?) -> Bool {

        let values = outcome?.values
            .compactMap(\.numberValue)
            ?? []

        let isStale = values.contains(-1)
        return isStale
    }

    // MARK: - HealthKit

    func fetchHealthKitSamples(
        events: [Event],
        completion: @escaping (Result<[Sample], Error>) -> Void
    ) {

        let descriptors = makeQueryDescriptors(for: events)

        // Only perform query if there are one or more descriptors.
        guard descriptors.isEmpty == false else {
            completion(.success([]))
            return
        }

        // We're not storing the query anchor because we're only fetching the
        // initial samples, and aren't concerned with changes that occur to the samples
        // in the HK store.

        let query = HKAnchoredObjectQuery(
            queryDescriptors: descriptors,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { _, hkSamples, _, _, error in

            // Catch errors
            if let error = error {
                completion(.failure(error))
                return
            }

            let samples = hkSamples?
                .compactMap { $0 as? HKQuantitySample }
                .map(Sample.init)
                ?? []

            completion(.success(samples))
        }

        healthStore.execute(query)
    }

    /// A constant stream of changes to HK samples matching the provided event dates.
    func healthKitSampleChanges(matching events: [Event]) -> SampleChanges {

        // Create a live query that fetches HealthKit sample changes

        let queryDescriptors = makeQueryDescriptors(for: events)

        let monitor = HealthKitQueryMonitor(
            queryDescriptors: queryDescriptors,
            store: healthStore
        )

        // Wrap the live query in an async stream

        let queryResults = AsyncThrowingStream(HealthKitQueryMonitor.QueryResult.self) { continuation in

            // If there are no events, we won't be able to create query descriptors
            // for the HK query which leads to a runtime crash. We'll need to finish early
            // to avoid that crash. We could arguable have returned earlier above when the
            // descriptors were created, but it's not possible to return an empty stream
            // because the return type won't match `SampleChangeStream`. The query hasn't been
            // started yet, so there's no harm waiting until now to finish the stream.
            guard queryDescriptors.isEmpty == false else {
                continuation.finish()
                return
            }

            monitor.resultHandler = { result in
                continuation.yield(with: result)
            }

            continuation.onTermination = { _ in
                monitor.stopQuery()
            }

            monitor.startQuery()
        }

        let sampleChanges = queryResults
            .map { SampleChange($0) }

        return sampleChanges
    }

    func updateCumulativeSumOfHealthKitSamples(
        events: [Event],
        completion: @escaping (Result<[Event], Error>) -> Void
    ) {

        let updateClosures = events.map { event in
            { self.updateCumulativeSumOfSamples(event: event, completion: $0) }
        }

        aggregate(
            updateClosures,
            callbackQueue: workQueue,
            completion: completion
        )
    }

    /// Update the outcome value for the event to reflect the sum of all HK samples that match the event date.
    /// Make sure the HealthKit sample UUIDs linked to the outcome values for the event are up to date before
    /// calling this method.
    private func updateCumulativeSumOfSamples(
        event: Event,
        completion: @escaping (Result<Event, Error>) -> Void
    ) {

        let predicate = makePredicate(for: event.scheduleEvent)
        let quantityType = extractQuantityType(from: event.task)

        let query = HKStatisticsQuery(
            quantityType: quantityType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, statistics, error in

            if let error {
                completion(.failure(error))
                return
            }

            let newSum = statistics?
                .sumQuantity()?
                .doubleValue(for: event.task.healthKitLinkage.unit)

            let updatedEvent = self.updateCumulativeSumOfSamples(newSum: newSum, event: event)
            completion(.success(updatedEvent))
        }

        healthStore.execute(query)
    }

    /// Store the new sum as an outcome value on the provided event.
    private func updateCumulativeSumOfSamples(
        newSum: Double?,
        event: Event
    ) -> Event {

        var updatedEvent = event

        // If there is no sum, we can remove the outcome completely
        guard let newSum else {
            updatedEvent.outcome = nil
            return updatedEvent
        }

        // Store the new sum as a single outcome value

        updatedEvent.outcome = event.outcome ?? makeOutcome(for: event)

        let units = event.task.healthKitLinkage.unit.unitString
        var outcomeValue = OCKOutcomeValue(newSum, units: units)
        outcomeValue.createdDate = now

        updatedEvent.outcome!.values = [outcomeValue]

        // The healthKitUUIDs should be up to date with the samples that generated the
        // new sum. So we'll just copy over the UUIDs to the new sum.

        let healthKitUUIDs = event.outcome?
            .healthKitUUIDs
            .flatMap { $0 }
            ?? []

        updatedEvent.outcome!.healthKitUUIDs = [healthKitUUIDs]

        return updatedEvent
    }

    // MARK: - Mappers

    func makeTaskQuery(from outcomeQuery: OCKOutcomeQuery) -> OCKTaskQuery {

        let dateInterval = Calendar.current.dateInterval(of: .day, for: Date())!

        var taskQuery = OCKTaskQuery(dateInterval: dateInterval)
        taskQuery.ids = outcomeQuery.taskIDs
        taskQuery.remoteIDs = outcomeQuery.taskRemoteIDs
        taskQuery.uuids = outcomeQuery.taskUUIDs

        return taskQuery
    }

    func makeQueryDescriptors(for events: [Event]) -> [HKQueryDescriptor] {

        // Create a lookup table to quickly locate all events for a specific sample type
        let eventsGroupedByQuantityType = Dictionary(grouping: events) {
            extractQuantityType(from: $0.task)
        }

        // Create a single query descriptor for each quantity type. The date interval
        // for the query descriptor predicate is determined by the events for the quantity type.
        let queryDescriptors = eventsGroupedByQuantityType.map { sampleType, events -> HKQueryDescriptor in

            let predicates = events.map { makePredicate(for: $0.scheduleEvent) }
            let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)

            return HKQueryDescriptor(sampleType: sampleType, predicate: predicate)
        }

        return queryDescriptors
    }

    func makeEvent(for partialEvent: PartialEvent<Task>) -> Event {

        return Event(
            task: partialEvent.task,
            outcome: nil,
            scheduleEvent: partialEvent.scheduleEvent
        )
    }

    private func makePredicate(for scheduleEvent: OCKScheduleEvent) -> NSPredicate {

        return HKQuery.predicateForSamples(
            withStart: scheduleEvent.start,
            end: scheduleEvent.end,
            options: [.strictStartDate, .strictEndDate]
        )
    }

    private func makeOutcome(for event: Event) -> OCKHealthKitOutcome {

        return OCKHealthKitOutcome(
            taskUUID: event.task.uuid,
            taskOccurrenceIndex: event.scheduleEvent.occurrence,
            values: []
        )
    }
}

