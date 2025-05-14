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

@testable import CareKitStore

import AsyncAlgorithms
import HealthKit
import XCTest

// Note, we test the event stream and not the outcome stream because the outcome stream
// calls into the event stream. Testing the outcome stream is unnecessary.

@available(iOS 15, watchOS 8, macOS 13.0, *)
class TestHealthKitPassthroughStoreEvents: XCTestCase {

    private let cdStore = OCKStore(
        name: "TestEvents.Store",
        type: .inMemory
    )

    private lazy var passthroughStore: OCKHealthKitPassthroughStore = {
        let store = OCKHealthKitPassthroughStore(store: cdStore)
        store._now = now
        return store
    }()

    private let now = Date(timeIntervalSinceReferenceDate: 0)

    override func setUpWithError() throws {
        try super.setUpWithError()
        try passthroughStore.reset()
    }

    // MARK: - Fetch Tests

    // Note: under the hood, the fetching logic uses the same business logic as the event stream.
    // There are pretty extensive tests for the event stream in this file, so we can lightly test
    // the fetch logic with some minor sanity checks.

    func testFetchEvents() throws {

        // Add tasks to the store

        let stepsTask = OCKHealthKitTask.makeDailyStepTask()
        let heartRateTask = OCKHealthKitTask.makeDailyHeartRateTask()
        try passthroughStore.addTasksAndWait([stepsTask, heartRateTask])

        // Generate samples that match the event date

        let steps: [Double] = [10, 20]

        let stepsSamples = steps.map {
            Sample(
                id: UUID(),
                type: HKObjectType.quantityType(forIdentifier: stepsTask.healthKitLinkage.quantityIdentifier)!,
                quantity: HKQuantity(unit: stepsTask.healthKitLinkage.unit, doubleValue: $0),
                dateInterval: DateInterval(start: stepsTask.schedule[0].start, end: stepsTask.schedule[0].end)
            )
        }

        let heartRates: [Double] = [70, 80]

        let heartRateSamples = heartRates.map {
            Sample(
                id: UUID(),
                type: HKObjectType.quantityType(forIdentifier: heartRateTask.healthKitLinkage.quantityIdentifier)!,
                quantity: HKQuantity(unit: heartRateTask.healthKitLinkage.unit, doubleValue: $0),
                dateInterval: DateInterval(start: heartRateTask.schedule[0].start, end: heartRateTask.schedule[0].end)
            )
        }

        let samples = stepsSamples + heartRateSamples

        // Fetch the events from the store

        let didFetchEvents = XCTestExpectation(description: "Fetched events")

        var result: Result<[OCKHealthKitPassthroughStore.Event], Error>!

        passthroughStore.fetchEvents(
            query: OCKTaskQuery(for: Date()),
            callbackQueue: .main,
            fetchSamples: { _, completion in
                completion(.success(samples))
            },
            updateCumulativeSumOfSamples: updateCumulativeSumOfSamples,
            completion: {
                result = $0
                didFetchEvents.fulfill()
            }
        )

        wait(for: [didFetchEvents], timeout: 2)

        let events = try result.get()
        XCTAssertEqual(events.count, 2)

        events.forEach { event in

            let outcomeValues = event.outcome?.values ?? []

            switch event.task.id {

            case stepsTask.id:
                XCTAssertEqual(outcomeValues.count, 1)
                XCTAssertEqual(outcomeValues.first?.doubleValue, -1)

            case heartRateTask.id:
                XCTAssertEqual(outcomeValues.count, 2)
                XCTAssertEqual(outcomeValues.first?.doubleValue, 70)
                XCTAssertEqual(outcomeValues[safe: 1]?.doubleValue, 80)

            default:
                XCTFail("Unexpected task")
            }
        }
    }

    // MARK: - Stream Tests

    func testInitialResultIsEmpty() async throws {

        let noChanges: AsyncSyncSequence<[SampleChange]> = [SampleChange()].async

        let query = OCKTaskQuery()

        let events = passthroughStore.events(
            matching: query,
            applyingChanges: { _ in noChanges },
            updateCumulativeSumOfSamples: updateCumulativeSumOfSamples
        )

        let accumulatedEvents = try await accumulate(events, expectedCount: 1)

        let observedEvents = accumulatedEvents.map { events in
            events.map { Event($0) }
        }

        let expectedEvents: [[Event]] = [[]]

        XCTAssertEqual(expectedEvents, observedEvents)
    }

    func testCorrectTasksAreChecked() async throws {

        // Add tasks to the store

        let stepsTask = OCKHealthKitTask.makeDailyStepTask()
        let heartRateTask = OCKHealthKitTask.makeDailyHeartRateTask()
        _ = try await passthroughStore.addTasks([stepsTask, heartRateTask])

        // Create a task query that does not include either of the existing tasks
        let query = OCKTaskQuery(id: "irrelevantTask")

        let noChanges: AsyncSyncSequence<[SampleChange]> = [].async

        let events = passthroughStore.events(
            matching: query,
            applyingChanges: { _ in noChanges },
            updateCumulativeSumOfSamples: updateCumulativeSumOfSamples
        )

        let accumulatedEvents = try await accumulate(events, expectedCount: 1)

        let observedEvents = accumulatedEvents.map { events in
            events.map { Event($0) }
        }

        let expectedEvents: [[Event]] = [[]]

        XCTAssertEqual(expectedEvents, observedEvents)
    }

    func testEventsAreSortedByStartDateThenEffectiveDate() async throws {

        // Add tasks to the store.
        // Ensure there are two tasks whose events occur at the same time, to ensure they are then sorted stably.
        // This test will be a bit imperfect, because there is a chance that events just *happen* to turn out
        // sorted randomly, even if we don't explicitly sort them. Hopefully by adding enough tasks to the store,
        // we decrease the chance of that random success case

        let heartRateTask = OCKHealthKitTask.makeDailyHeartRateTask(startHour: 2)

        var weightTask = OCKHealthKitTask.makeDailyWeightTask(startHour: 2)
        weightTask.effectiveDate = heartRateTask.effectiveDate + 1

        let stepsTask = OCKHealthKitTask.makeDailyStepTask(startHour: 3)
        let oxygenSaturationTask = OCKHealthKitTask.makeDailyOxygenSaturationTask(startHour: 4)

        _ = try await passthroughStore.addTasks([heartRateTask, stepsTask, oxygenSaturationTask, weightTask])

        // Accumulate streamed results

        let queryInterval = DateInterval(
            start: weightTask.schedule[0].start,
            end: oxygenSaturationTask.schedule[2].end
        )

        let query = OCKTaskQuery(dateInterval: queryInterval)

        let noChanges: AsyncSyncSequence<[SampleChange]> = [].async

        let events = passthroughStore.events(
            matching: query,
            applyingChanges: { _ in noChanges },
            updateCumulativeSumOfSamples: updateCumulativeSumOfSamples
        )

        let accumulatedEvents = try await accumulate(events, expectedCount: 1)

        // Validate the result

        let observedEvents = accumulatedEvents.map { events in
            events.map { Event($0) }
        }

        let expectedEvents = [
            [
                Event(taskUUID: heartRateTask.uuid, scheduleEvent: heartRateTask.schedule[0]),
                Event(taskUUID: weightTask.uuid, scheduleEvent: weightTask.schedule[0]),
                Event(taskUUID: stepsTask.uuid, scheduleEvent: stepsTask.schedule[0]),
                Event(taskUUID: oxygenSaturationTask.uuid, scheduleEvent: oxygenSaturationTask.schedule[0]),

                Event(taskUUID: heartRateTask.uuid, scheduleEvent: heartRateTask.schedule[1]),
                Event(taskUUID: weightTask.uuid, scheduleEvent: weightTask.schedule[1]),
                Event(taskUUID: stepsTask.uuid, scheduleEvent: stepsTask.schedule[1]),
                Event(taskUUID: oxygenSaturationTask.uuid, scheduleEvent: oxygenSaturationTask.schedule[1]),

                Event(taskUUID: heartRateTask.uuid, scheduleEvent: heartRateTask.schedule[2]),
                Event(taskUUID: weightTask.uuid, scheduleEvent: weightTask.schedule[2]),
                Event(taskUUID: stepsTask.uuid, scheduleEvent: stepsTask.schedule[2]),
                Event(taskUUID: oxygenSaturationTask.uuid, scheduleEvent: oxygenSaturationTask.schedule[2])
            ]
        ]

        XCTAssertEqual(expectedEvents, observedEvents)
    }

    func testSamplesAreAppliedToOutcomesForMultipleTasks() async throws {

        // Add tasks to the store

        let stepsTask = OCKHealthKitTask.makeDailyStepTask(startHour: 0)
        let heartRateTask = OCKHealthKitTask.makeDailyHeartRateTask(startHour: 1)

        _ = try await passthroughStore.addTasks([stepsTask, heartRateTask])

        // Generate samples that match the event date

        let steps: [Double] = [10, 20]

        let stepsSamples = steps.map {
            Sample(
                id: UUID(),
                type: HKObjectType.quantityType(forIdentifier: stepsTask.healthKitLinkage.quantityIdentifier)!,
                quantity: HKQuantity(unit: stepsTask.healthKitLinkage.unit, doubleValue: $0),
                dateInterval: DateInterval(start: stepsTask.schedule[0].start, end: stepsTask.schedule[0].end)
            )
        }

        let heartRates: [Double] = [70, 80]

        let heartRateSamples = heartRates.map {
            Sample(
                id: UUID(),
                type: HKObjectType.quantityType(forIdentifier: heartRateTask.healthKitLinkage.quantityIdentifier)!,
                quantity: HKQuantity(unit: heartRateTask.healthKitLinkage.unit, doubleValue: $0),
                dateInterval: DateInterval(start: heartRateTask.schedule[0].start, end: heartRateTask.schedule[0].end)
            )
        }

        let samples = stepsSamples + heartRateSamples
        let sampleChange = SampleChange(addedSamples: samples)
        let sampleChanges = [sampleChange].async

        // Accumulate the streamed events

        let query = OCKTaskQuery()

        let events = passthroughStore.events(
            matching: query,
            applyingChanges: { _ in sampleChanges },
            updateCumulativeSumOfSamples: updateCumulativeSumOfSamples
        )

        let accumulatedEvents = try await accumulate(events, expectedCount: 2)

        // Validate the events

        let observedEvents = accumulatedEvents.map { events in
            events.map { Event($0) }
        }

        let expectedEvents = [
            // Initial events before the samples are applied
            [
                Event(
                    taskUUID: stepsTask.uuid,
                    scheduleEvent: stepsTask.schedule[0],
                    outcome: nil
                ),
                Event(
                    taskUUID: heartRateTask.uuid,
                    scheduleEvent: heartRateTask.schedule[0],
                    outcome: nil
                )
            ],
            // Events after the samples are applied
            [
                Event(
                    taskUUID: stepsTask.uuid,
                    scheduleEvent: stepsTask.schedule[0],
                    outcome: OCKHealthKitOutcome(
                        taskUUID: stepsTask.uuid,
                        taskOccurrenceIndex: 0,
                        values: [
                            // -1 indicates a stale cumulative sum. That's expected because we aren't actually going
                            // and fetching a cumulative sum from HK after we detect a change while unit testing
                            makeOutcomeValue(-1.0, units: "count")
                        ],
                        isOwnedByApp: true,
                        healthKitUUIDs: [stepsSamples.map(\.id)]
                    )
                ),
                Event(
                    taskUUID: heartRateTask.uuid,
                    scheduleEvent: heartRateTask.schedule[0],
                    outcome: OCKHealthKitOutcome(
                        taskUUID: heartRateTask.uuid,
                        taskOccurrenceIndex: 0,
                        values: [
                            makeOutcomeValue(70.0, units: "count/min"),
                            makeOutcomeValue(80.0, units: "count/min")
                        ],
                        isOwnedByApp: true,
                        healthKitUUIDs: [
                            [heartRateSamples[0].id],
                            [heartRateSamples[1].id]
                        ]
                    )
                )
            ]
        ]

        XCTAssertEqual(expectedEvents, observedEvents)
    }

    func testSamplesAreAppliedToOutcomesAtBoundaries() async throws {

        // Add task to the store

        let heartRateTask = OCKHealthKitTask.makeDailyHeartRateTask()
        _ = try await passthroughStore.addTask(heartRateTask)

        // Generate samples that match the event date
        let samples = [

            // Intersects with the lower bound of the event
            Sample(
                id: UUID(),
                type: HKObjectType.quantityType(forIdentifier: heartRateTask.healthKitLinkage.quantityIdentifier)!,
                quantity: HKQuantity(unit: heartRateTask.healthKitLinkage.unit, doubleValue: 1),
                dateInterval: DateInterval(start: heartRateTask.schedule[0].start - 1, end: heartRateTask.schedule[0].start)
            ),

            // Intersects with the upper bound of the event
            Sample(
                id: UUID(),
                type: HKObjectType.quantityType(forIdentifier: heartRateTask.healthKitLinkage.quantityIdentifier)!,
                quantity: HKQuantity(unit: heartRateTask.healthKitLinkage.unit, doubleValue: 2),
                dateInterval: DateInterval(start: heartRateTask.schedule[0].end - 1, end: heartRateTask.schedule[0].end)
            ),

            // Misses the lower bound of the event
            Sample(
                id: UUID(),
                type: HKObjectType.quantityType(forIdentifier: heartRateTask.healthKitLinkage.quantityIdentifier)!,
                quantity: HKQuantity(unit: heartRateTask.healthKitLinkage.unit, doubleValue: 3),
                dateInterval: DateInterval(start: heartRateTask.schedule[0].start - 2, end: heartRateTask.schedule[0].start - 1)
            ),

            // Misses the upper bound of the event
            Sample(
                id: UUID(),
                type: HKObjectType.quantityType(forIdentifier: heartRateTask.healthKitLinkage.quantityIdentifier)!,
                quantity: HKQuantity(unit: heartRateTask.healthKitLinkage.unit, doubleValue: 4),
                dateInterval: DateInterval(start: heartRateTask.schedule[0].end, end: heartRateTask.schedule[0].end + 1)
            )
        ]

        let sampleChange = SampleChange(addedSamples: samples)
        let sampleChanges = [sampleChange].async

        // Accumulate the streamed events

        let query = OCKTaskQuery()

        let events = passthroughStore.events(
            matching: query,
            applyingChanges: { _ in sampleChanges },
            updateCumulativeSumOfSamples: updateCumulativeSumOfSamples
        )

        let accumulatedEvents = try await accumulate(events, expectedCount: 2)

        // Validate the events

        let observedEvents = accumulatedEvents.map { events in
            events.map { Event($0) }
        }

        let expectedEvents = [
            // Initial events before the samples are applied
            [
                Event(
                    taskUUID: heartRateTask.uuid,
                    scheduleEvent: heartRateTask.schedule[0],
                    outcome: nil
                )
            ],
            // Events after the samples are applied
            [
                Event(
                    taskUUID: heartRateTask.uuid,
                    scheduleEvent: heartRateTask.schedule[0],
                    outcome: OCKHealthKitOutcome(
                        taskUUID: heartRateTask.uuid,
                        taskOccurrenceIndex: 0,
                        values: [
                            makeOutcomeValue(1.0, units: "count/min"),
                            makeOutcomeValue(2.0, units: "count/min")
                        ],
                        isOwnedByApp: true,
                        healthKitUUIDs: [
                            [samples[0].id],
                            [samples[1].id]
                        ]
                    )
                )
            ]
        ]

        XCTAssertEqual(expectedEvents, observedEvents)
    }

    func testSampleIsAppliedToMultipleOutcomes() async throws {

        // Add tasks to the store

        let stepsTask = OCKHealthKitTask.makeDailyStepTask()
        _ = try await passthroughStore.addTask(stepsTask)

        // Generate samples that match the dates for two events

        let sample = Sample(
            id: UUID(),
            type: HKObjectType.quantityType(forIdentifier: stepsTask.healthKitLinkage.quantityIdentifier)!,
            quantity: HKQuantity(unit: stepsTask.healthKitLinkage.unit, doubleValue: 10),
            dateInterval: DateInterval(start: stepsTask.schedule[0].start, end: stepsTask.schedule[1].end)
        )

        let sampleChange = SampleChange(addedSamples: [sample])
        let sampleChanges = [sampleChange].async

        // Accumulate the streamed events

        let queryInterval = DateInterval(
            start: stepsTask.schedule[0].start,
            end: stepsTask.schedule[1].end
        )

        let query = OCKTaskQuery(dateInterval: queryInterval)

        let events = passthroughStore.events(
            matching: query,
            applyingChanges: { _ in sampleChanges },
            updateCumulativeSumOfSamples: updateCumulativeSumOfSamples
        )

        let accumulatedEvents = try await accumulate(events, expectedCount: 2)

        // Validate the events

        let observedEvents = accumulatedEvents.map { events in
            events.map { Event($0) }
        }

        let expectedEvents = [
            // Initial events before the samples are applied
            [
                Event(
                    taskUUID: stepsTask.uuid,
                    scheduleEvent: stepsTask.schedule[0],
                    outcome: nil
                ),
                Event(
                    taskUUID: stepsTask.uuid,
                    scheduleEvent: stepsTask.schedule[1],
                    outcome: nil
                )
            ],
            // Events after the samples are applied
            [
                Event(
                    taskUUID: stepsTask.uuid,
                    scheduleEvent: stepsTask.schedule[0],
                    outcome: OCKHealthKitOutcome(
                        taskUUID: stepsTask.uuid,
                        taskOccurrenceIndex: 0,
                        values: [
                            makeOutcomeValue(-1.0, units: "count")
                        ],
                        isOwnedByApp: true,
                        healthKitUUIDs: [[sample.id]]
                    )
                ),
                Event(
                    taskUUID: stepsTask.uuid,
                    scheduleEvent: stepsTask.schedule[1],
                    outcome: OCKHealthKitOutcome(
                        taskUUID: stepsTask.uuid,
                        taskOccurrenceIndex: 1,
                        values: [
                            makeOutcomeValue(-1.0, units: "count")
                        ],
                        isOwnedByApp: true,
                        healthKitUUIDs: [[sample.id]]
                    )
                )
            ]
        ]

        XCTAssertEqual(expectedEvents, observedEvents)
    }

    // MARK: - Test Changes

    func testSampleChangesAreApplied() async throws {

        // Add tasks to the store

        let stepsTask = OCKHealthKitTask.makeDailyStepTask(startHour: 7)
        let weightTask = OCKHealthKitTask.makeDailyWeightTask(startHour: 8)
        _ = try await passthroughStore.addTasks([stepsTask, weightTask])

        // Generate samples that match the dates for two events

        let weightSampleUUID = UUID()

        let weightSample = Sample(
            id: weightSampleUUID,
            type: HKObjectType.quantityType(forIdentifier: weightTask.healthKitLinkage.quantityIdentifier)!,
            quantity: HKQuantity(unit: weightTask.healthKitLinkage.unit, doubleValue: 70),
            dateInterval: DateInterval(start: weightTask.schedule[0].start, end: weightTask.schedule[1].end)
        )

        let stepsSampleUUID = UUID()

        let stepsSample = Sample(
            id: stepsSampleUUID,
            type: HKObjectType.quantityType(forIdentifier: stepsTask.healthKitLinkage.quantityIdentifier)!,
            quantity: HKQuantity(unit: stepsTask.healthKitLinkage.unit, doubleValue: 10),
            dateInterval: DateInterval(start: stepsTask.schedule[0].start, end: stepsTask.schedule[1].end)
        )

        let sampleChanges = [
            SampleChange(addedSamples: [weightSample, stepsSample]),
            SampleChange(deletedIDs: [weightSampleUUID]),
            SampleChange(addedSamples: [weightSample]),
            SampleChange(deletedIDs: [stepsSampleUUID])
        ]
        .async

        // Accumulate the streamed events

        let query = OCKTaskQuery()

        let events = passthroughStore.events(
            matching: query,
            applyingChanges: { _ in sampleChanges },
            updateCumulativeSumOfSamples: updateCumulativeSumOfSamples
        )

        let accumulatedEvents = try await accumulate(events, expectedCount: 5)

        // Validate the events

        let observedEvents = accumulatedEvents.map { events in
            events.map { Event($0) }
        }

        let expectedEvents = [
            // Initial events before the samples are applied
            [
                Event(
                    taskUUID: stepsTask.uuid,
                    scheduleEvent: stepsTask.schedule[0],
                    outcome: nil
                ),
                Event(
                    taskUUID: weightTask.uuid,
                    scheduleEvent: weightTask.schedule[0],
                    outcome: nil
                )
            ],
            // Events after the samples have been applied
            [
                Event(
                    taskUUID: stepsTask.uuid,
                    scheduleEvent: stepsTask.schedule[0],
                    outcome: OCKHealthKitOutcome(
                        taskUUID: stepsTask.uuid,
                        taskOccurrenceIndex: 0,
                        values: [
                            makeOutcomeValue(-1.0, units: "count")
                        ],
                        isOwnedByApp: true,
                        healthKitUUIDs: [[stepsSample.id]]
                    )
                ),
                Event(
                    taskUUID: weightTask.uuid,
                    scheduleEvent: weightTask.schedule[0],
                    outcome: OCKHealthKitOutcome(
                        taskUUID: weightTask.uuid,
                        taskOccurrenceIndex: 0,
                        values: [
                            makeOutcomeValue(70.0, units: "g")
                        ],
                        isOwnedByApp: true,
                        healthKitUUIDs: [[weightSample.id]]
                    )
                )
            ],
            [
                Event(
                    taskUUID: stepsTask.uuid,
                    scheduleEvent: stepsTask.schedule[0],
                    outcome: OCKHealthKitOutcome(
                        taskUUID: stepsTask.uuid,
                        taskOccurrenceIndex: 0,
                        values: [
                            makeOutcomeValue(-1.0, units: "count")
                        ],
                        isOwnedByApp: true,
                        healthKitUUIDs: [[stepsSample.id]]
                    )
                ),
                Event(
                    taskUUID: weightTask.uuid,
                    scheduleEvent: weightTask.schedule[0],
                    outcome: nil
                )
            ],
            [
                Event(
                    taskUUID: stepsTask.uuid,
                    scheduleEvent: stepsTask.schedule[0],
                    outcome: OCKHealthKitOutcome(
                        taskUUID: stepsTask.uuid,
                        taskOccurrenceIndex: 0,
                        values: [
                            makeOutcomeValue(-1.0, units: "count")
                        ],
                        isOwnedByApp: true,
                        healthKitUUIDs: [[stepsSample.id]]
                    )
                ),
                Event(
                    taskUUID: weightTask.uuid,
                    scheduleEvent: weightTask.schedule[0],
                    outcome: OCKHealthKitOutcome(
                        taskUUID: weightTask.uuid,
                        taskOccurrenceIndex: 0,
                        values: [
                            makeOutcomeValue(70.0, units: "g")
                        ],
                        isOwnedByApp: true,
                        healthKitUUIDs: [[weightSample.id]]
                    )
                )
            ],
            [
                Event(
                    taskUUID: stepsTask.uuid,
                    scheduleEvent: stepsTask.schedule[0],
                    outcome: nil
                ),
                Event(
                    taskUUID: weightTask.uuid,
                    scheduleEvent: weightTask.schedule[0],
                    outcome: OCKHealthKitOutcome(
                        taskUUID: weightTask.uuid,
                        taskOccurrenceIndex: 0,
                        values: [
                            makeOutcomeValue(70.0, units: "g")
                        ],
                        isOwnedByApp: true,
                        healthKitUUIDs: [[weightSample.id]]
                    )
                )
            ]
        ]

        XCTAssertEqual(expectedEvents, observedEvents)
    }

    // MARK: - Helpers

    private func updateCumulativeSumOfSamples(
        events: [OCKHealthKitPassthroughStore.Event],
        completion: @escaping (Result<[OCKHealthKitPassthroughStore.Event], Error>) -> Void
    ) {
        let updatedEvents = events.map { event -> OCKHealthKitPassthroughStore.Event in

            guard event.outcome?.values.isEmpty == false else {
                return event
            }

            let outcomeValues = event.outcome?.values ?? []

            let summedOutcomeValue = outcomeValues
                .map { $0.numberValue!.doubleValue }
                .reduce(0, +)

            var updatedEvent = event
            updatedEvent.outcome?.values[0].value = summedOutcomeValue

            return updatedEvent
        }

        completion(.success(updatedEvents))
    }

    private func makeOutcomeValue(_ value: OCKOutcomeValueUnderlyingType, units: String?) -> OCKOutcomeValue {
        var outcomeValue = OCKOutcomeValue(value, units: units)
        outcomeValue.createdDate = now
        return outcomeValue
    }
}

private extension OCKHealthKitTask {

    private static var startOfDay: Date {
        Calendar.current.startOfDay(for: Date())
    }

    static func makeDailyStepTask(startHour: Int = 7) -> OCKHealthKitTask {

        let task = OCKHealthKitTask(
            id: "steps",
            title: nil,
            carePlanUUID: nil,
            schedule: .dailyAtTime(hour: startHour, minutes: 0, start: startOfDay, end: nil, text: nil),
            healthKitLinkage: OCKHealthKitLinkage(quantityIdentifier: .stepCount, quantityType: .cumulative, unit: .count())
        )

        return task
    }

    static func makeDailyHeartRateTask(startHour: Int = 7) -> OCKHealthKitTask {

        let unit = HKUnit.count().unitDivided(by: .minute())

        let task = OCKHealthKitTask(
            id: "heartRate",
            title: nil,
            carePlanUUID: nil,
            schedule: .dailyAtTime(hour: startHour, minutes: 0, start: startOfDay, end: nil, text: nil),
            healthKitLinkage: OCKHealthKitLinkage(quantityIdentifier: .heartRate, quantityType: .discrete, unit: unit)
        )

        return task
    }

    static func makeDailyWeightTask(startHour: Int = 7) -> OCKHealthKitTask {

        let task = OCKHealthKitTask(
            id: "weight",
            title: nil,
            carePlanUUID: nil,
            schedule: .dailyAtTime(hour: startHour, minutes: 0, start: startOfDay, end: nil, text: nil),
            healthKitLinkage: OCKHealthKitLinkage(quantityIdentifier: .bodyMass, quantityType: .discrete, unit: .gram())
        )

        return task
    }

    static func makeDailyOxygenSaturationTask(startHour: Int = 7) -> OCKHealthKitTask {

        let task = OCKHealthKitTask(
            id: "oxygenSaturation",
            title: nil,
            carePlanUUID: nil,
            schedule: .dailyAtTime(hour: startHour, minutes: 0, start: startOfDay, end: nil, text: nil),
            healthKitLinkage: OCKHealthKitLinkage(quantityIdentifier: .oxygenSaturation, quantityType: .discrete, unit: .count())
        )

        return task
    }
}

private struct Event: Equatable {

    var taskUUID: UUID
    var scheduleEvent: OCKScheduleEvent
    var outcome: OCKHealthKitOutcome?
}

@available(iOS 15, watchOS 8, macOS 13.0, *)
private extension Event {

    init(_ event: OCKHealthKitPassthroughStore.Event) {

        taskUUID = event.task.uuid
        outcome = event.outcome
        scheduleEvent = event.scheduleEvent
    }
}

