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
import XCTest

class TestScheduleEvent: XCTestCase {
    func testComparisonOperator() {
        let element = OCKScheduleElement(start: Date(), end: nil, interval: DateComponents(year: 1),
                                         text: nil, targetValues: [])
        XCTAssert(element[0]! < element[1]!)
    }

    func testStartDateEndDateForEventWithNoDuration() {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
        let interval = DateComponents(day: 1)
        let element = OCKScheduleElement(start: startDate, end: endDate, interval: interval,
                                         text: nil, targetValues: [])
        let event = element[0]!
        XCTAssert(event.start == event.end)
    }

    func testStartDateEndDateForEventWithDuration() {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
        let interval = DateComponents(day: 1)
        let element = OCKScheduleElement(start: startDate, end: endDate, interval: interval,
                                         text: nil, targetValues: [], duration: 100)
        let event = element[0]!
        XCTAssert(event.end == event.start.addingTimeInterval(100))
    }

    func testStartDateEndDateForEventWithAllDayDuration() {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
        let interval = DateComponents(day: 1)
        let element = OCKScheduleElement(start: startDate, end: endDate, interval: interval,
                                         text: nil, targetValues: [], isAllDay: true)
        let event = element[0]!
        XCTAssert(event.start == Calendar.current.startOfDay(for: startDate))
        XCTAssert(event.end == Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: event.start)!)
    }
}
