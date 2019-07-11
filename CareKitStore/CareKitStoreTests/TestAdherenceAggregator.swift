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
import CareKitStore
import Foundation
import XCTest

class TestAdherenceAggregators: XCTestCase {
    func makeEvents() -> [OCKStore.Event] {
        let element = OCKScheduleElement(start: Date(), end: nil, interval: DateComponents(day: 1),
                                         text: nil, targetValues: [OCKOutcomeValue(10), OCKOutcomeValue("test")],
                                         duration: 100, isAllDay: false)
        let task = OCKTask(identifier: "A", title: "A", carePlanID: nil, schedule: OCKSchedule(composing: [element]))
        let outcome = OCKOutcome(taskID: nil, taskOccurenceIndex: 0, values: [OCKOutcomeValue("test")])
        guard let scheduleEvent = task.schedule[0] else { XCTFail("Bad schedule"); return [] }
        let event1: OCKStore.Event = OCKEvent(task: task, outcome: outcome, scheduleEvent: scheduleEvent)
        let event2: OCKStore.Event = OCKEvent(task: task, outcome: nil, scheduleEvent: scheduleEvent)
        return [event1, event2]
    }

    func testCountOutcomes() {
        let aggregator = OCKAdherenceAggregator<OCKStore.Event>.countOutcomes
        let result = aggregator.aggregate(events: makeEvents())
        XCTAssert(result == .progress(0.5))
    }

    func testCountOutcomeValues() {
        let aggregator = OCKAdherenceAggregator<OCKStore.Event>.countOutcomeValues
        let result = aggregator.aggregate(events: makeEvents())
        XCTAssert(result == .progress(0.25))
    }

    func testCustomAggregator() {
        let aggregator = OCKAdherenceAggregator<OCKStore.Event>.custom({ _ in .noTasks })
        let result = aggregator.aggregate(events: makeEvents())
        XCTAssert(result == .noTasks)
    }
}
