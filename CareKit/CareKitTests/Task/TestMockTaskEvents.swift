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

@testable import CareKit
@testable import CareKitStore
import Foundation
import XCTest

class TestMockTaskEvents: XCTestCase {

    func testData() {
        let taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: false)
        let events = taskEvents.first
        XCTAssertNotNil(taskEvents.first?.first?.task.instructions)
        XCTAssertNotNil(events)
        events.map { XCTAssertEqual($0.count, 3) }
    }
}

extension OCKTaskEvents {
    static func mock(eventsHaveOutcomes: Bool, occurrences: Int = 3) -> OCKTaskEvents {
        let startOfDay = Calendar.current.startOfDay(for: Date())

        let elements = (0..<occurrences).map {
            OCKSchedule.dailyAtTime(hour: $0 + 1, minutes: 0, start: startOfDay, end: nil, text: "\($0 + 1)")
        }

        var task = OCKTask(id: "doxylamine", title: "Doxylamine", carePlanUUID: nil, schedule: .init(composing: elements))
        task.uuid = UUID()
        task.instructions = "Take the tablet with a glass of water."

        var taskEvents = OCKTaskEvents()
        elements.enumerated().forEach {
            var outcome: OCKAnyOutcome?
            if eventsHaveOutcomes {
                var outcomeValue = OCKOutcomeValue(true)
                outcomeValue.createdDate = Date()
                outcome = OCKOutcome(taskUUID: task.uuid!, taskOccurrenceIndex: $0, values: [outcomeValue])
            }
            let event = OCKAnyEvent(task: task, outcome: outcome, scheduleEvent: $1.event(forOccurrenceIndex: $0)!)
            taskEvents.append(event: event)
        }
        return taskEvents
    }
}
