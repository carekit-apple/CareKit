/*
 Copyright (c) 2020, Apple Inc. All rights reserved.
 
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
import XCTest

class TestEvent: XCTestCase {

    func testIdentitiesMatch() {
        let uuid = UUID()
        let event1 = makeEvent(taskUUID: uuid, occurrence: 0)
        let event2 = makeEvent(taskUUID: uuid, occurrence: 0)
        let anyEvent1 = event1.anyEvent
        let anyEvent2 = event2.anyEvent

        XCTAssertEqual(event1.id, event2.id)
        XCTAssertEqual(anyEvent1.id, anyEvent2.id)
    }

    func testIdentitiesDoNotMatch() {
        let uuid = UUID()
        var event1 = makeEvent(taskUUID: uuid, occurrence: 0)
        var event2 = makeEvent(taskUUID: uuid, occurrence: 1)
        var anyEvent1 = event1.anyEvent
        var anyEvent2 = event2.anyEvent

        XCTAssertNotEqual(event1.id, event2.id)
        XCTAssertNotEqual(anyEvent1.id, anyEvent2.id)

        event1 = makeEvent(taskUUID: UUID(), occurrence: 0)
        event2 = makeEvent(taskUUID: UUID(), occurrence: 0)
        anyEvent1 = event1.anyEvent
        anyEvent2 = event2.anyEvent

        XCTAssertNotEqual(event1.id, event2.id)
        XCTAssertNotEqual(anyEvent1.id, anyEvent2.id)
    }

    func makeEvent(taskUUID: UUID, occurrence: Int) -> OCKEvent<OCKTask, OCKOutcome> {
        let task = makeTask(uuid: taskUUID)
        let scheduleEvent = task.schedule.event(forOccurrenceIndex: occurrence)!
        return .init(task: task, outcome: nil, scheduleEvent: scheduleEvent)
    }

    private func makeTask(uuid: UUID) -> OCKTask {
        var task = OCKTask(id: "", title: "", carePlanUUID: nil,
                           schedule: .dailyAtTime(hour: 0, minutes: 0, start: Date(), end: nil, text: nil))
        task.uuid = uuid
        return task
    }
}
