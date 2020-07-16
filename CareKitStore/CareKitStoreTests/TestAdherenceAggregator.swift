/*
 Copyright (c) 2019, Apple Inc. All rights reserved.
 
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
import XCTest

class TestAdherenceAggregators: XCTestCase {

    func makeEvents(
        outcomeValues: [OCKOutcomeValueUnderlyingType],
        targetValues: [OCKOutcomeValueUnderlyingType]) -> [OCKAnyEvent] {

        let element = OCKScheduleElement(
            start: Date(), end: nil,
            interval: DateComponents(day: 1),
            text: nil,
            targetValues: targetValues.map { OCKOutcomeValue($0) },
            duration: .seconds(100))

        let task = OCKTask(
            id: "A", title: "A",
            carePlanUUID: nil,
            schedule: OCKSchedule(composing: [element]))

        let outcome = OCKOutcome(
            taskUUID: UUID(),
            taskOccurrenceIndex: 0,
            values: outcomeValues.map { OCKOutcomeValue($0) })

        let scheduleEvent = task.schedule[0]

        let event1: OCKStore.Event = OCKEvent(
            task: task,
            outcome: outcome,
            scheduleEvent: scheduleEvent)

        let event2: OCKStore.Event = OCKEvent(
            task: task,
            outcome: nil,
            scheduleEvent: scheduleEvent)

        return [event1.anyEvent, event2.anyEvent]
    }

    func testOutcomesExist() {
        let events = makeEvents(outcomeValues: [0], targetValues: [])
        let aggregator = OCKAdherenceAggregator.outcomeExists
        let result = aggregator.aggregate(events: events)
        XCTAssert(result == .progress(0.5), "Expected 0.5, but got \(result)")
    }

    func testPercentOfOutcomeValuesThatExist() {
        let events = makeEvents(outcomeValues: [0], targetValues: [10, "test"])
        let aggregator = OCKAdherenceAggregator.percentOfOutcomeValuesThatExist
        let result = aggregator.aggregate(events: events)
        XCTAssert(result == .progress(0.25), "Expected 0.25, but got \(result)")
    }

    func testPercentOfOutcomesValuesThatExistWithNoGoals() {
        let events = makeEvents(outcomeValues: [0], targetValues: [])
        let aggregator = OCKAdherenceAggregator.percentOfOutcomeValuesThatExist
        let result = aggregator.aggregate(events: events)
        XCTAssert(result == .progress(0.5), "Expected 0.5, but got \(result)")
    }

    func testCompareTargetValuesWithUnequalNumberOfValuesAndTargetValues() {
        let events = makeEvents(outcomeValues: [10], targetValues: [10, "test"])
        let aggregator = OCKAdherenceAggregator.compareTargetValues
        let result = aggregator.aggregate(events: events)
        XCTAssert(result == .progress(0.0), "Expected 0.0 but got \(result)")
    }

    func testCompareTargetValuesWithUnmetGoal() {
        let events = makeEvents(outcomeValues: [9, "test"], targetValues: [10, "test"])
        let aggregator = OCKAdherenceAggregator.compareTargetValues
        let result = aggregator.aggregate(events: events)
        XCTAssert(result == .progress(0.0), "Expected 0.0 but got \(result)")
    }

    func testCompareTargetValuesWithAllGoalsMet() {
        let events = makeEvents(outcomeValues: [10, "test"], targetValues: [10, "test"])
        let aggregator = OCKAdherenceAggregator.compareTargetValues
        let result = aggregator.aggregate(events: events)
        XCTAssert(result == .progress(0.5), "Expected 0.5 but got \(result)")
    }

    func testCompareTargetValuesWithNoGoals() {
        let events = makeEvents(outcomeValues: [10], targetValues: [])
        let aggregator = OCKAdherenceAggregator.compareTargetValues
        let result = aggregator.aggregate(events: events)
        XCTAssert(result == .progress(0.5), "Expected 0.5 but got \(result)")
    }

    func testCompareTargetValuesWithMismatchedNumeralTypes() {
        let events = makeEvents(outcomeValues: [12.0], targetValues: [10])
        let aggregator = OCKAdherenceAggregator.compareTargetValues
        let result = aggregator.aggregate(events: events)
        XCTAssert(result == .progress(0.5), "Expected 0.5 but got \(result)")
    }

    func testCompareTargetValuesWithMismatchedNumeralAndBooleanTypes() {
        let events = makeEvents(outcomeValues: [false], targetValues: [10])
        let aggregator = OCKAdherenceAggregator.compareTargetValues
        let result = aggregator.aggregate(events: events)
        XCTAssert(result == .progress(0), "Expected 0 but got \(result)")
    }

    func testTargetCompletionPercentage() {
        let events = makeEvents(outcomeValues: [10, "fail"], targetValues: [10, "fail"])
        let aggregator = OCKAdherenceAggregator.percentOfTargetValuesMet
        let result = aggregator.aggregate(events: events)
        XCTAssert(result == .progress(0.5), "Expected 0.5 but got \(result)")
    }

    func testTargetCompletionPercentWithNoOutcomeValues() {
        let events = makeEvents(outcomeValues: [], targetValues: [10, "test"])
        let aggregator = OCKAdherenceAggregator.percentOfTargetValuesMet
        let result = aggregator.aggregate(events: events)
        XCTAssert(result == .progress(0.0), "Expected 0.0 but got \(result)")
    }

    func testTargetCompletionPercentWithNoTargetValues() {
        let events = makeEvents(outcomeValues: [10, "test"], targetValues: [])
        let aggregator = OCKAdherenceAggregator.percentOfTargetValuesMet
        let result = aggregator.aggregate(events: events)
        XCTAssert(result == .progress(0.5), "Expected 0.5 but got \(result)")
    }

    func testCustomAggregator() {
        let events = makeEvents(outcomeValues: [], targetValues: [])
        let aggregator = OCKAdherenceAggregator.custom({ _ in .noTasks })
        let result = aggregator.aggregate(events: events)
        XCTAssert(result == .noTasks, "Expected `noTasks` but got \(result)")
    }
}
