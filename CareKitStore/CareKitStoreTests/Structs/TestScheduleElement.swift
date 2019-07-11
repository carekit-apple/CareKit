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
import XCTest

class TestScheduleElement: XCTestCase {
    var date: Date {
        var components = DateComponents()
        components.year = 2_019
        components.month = 1
        components.day = 19
        components.hour = 15
        components.minute = 30
        return Calendar.current.date(from: components)!
    }

    var interval: DateComponents {
        var components = DateComponents()
        components.year = 1
        return components
    }

    var element: OCKScheduleElement {
        return OCKScheduleElement(start: date, end: nil, interval: interval, text: "Wedding Anniversary", targetValues: [])
    }

    func testSubscript() {
        let event = element[0]!
        assert(event.start == element.start)
    }

    func testSubscriptReturnsNilForDatePastEndDate() {
        var finiteElement = element
        finiteElement.end = Calendar.current.date(byAdding: interval, to: finiteElement.start)!
        assert(finiteElement[2] == nil)
    }

    func testOneScheduleElementIsEqualToItsElements() {
        let interval = DateComponents(day: 1)
        let schedule = OCKScheduleElement(start: date, end: nil, interval: interval, text: nil, targetValues: [])
        XCTAssert([schedule] == schedule.elements)
    }

    func testOffset() {
        let offset = DateComponents(year: 1)
        let originalElement = OCKScheduleElement(start: date, end: date.addingTimeInterval(10), interval: interval,
                                                 text: nil, targetValues: [])
        let offsetElement = originalElement.offset(by: offset)
        let expectedStartDate = Calendar.current.date(byAdding: offset, to: date)!
        XCTAssert(offsetElement.start == expectedStartDate)
    }

    func testNoEventsBeforeStartDate() {
        let wayBefore = Calendar.current.date(byAdding: .year, value: -1, to: element.start)!
        let justBefore = Calendar.current.date(byAdding: .second, value: -1, to: element.start)!
        let events = element.events(from: wayBefore, to: justBefore)
        XCTAssert(events.isEmpty)
    }

    func testEventOccursExactlyOnStartDate() {
        let justAfter = Calendar.current.date(byAdding: .second, value: 1, to: element.start)!
        let events = element.events(from: date, to: justAfter)
        XCTAssert(events.first!.start == element.start)
    }

    func testEventCannotOccurExactlyOnEndDate() {
        var finiteElement = element
        finiteElement.end = Calendar.current.date(byAdding: .year, value: 1, to: date)!
        let start = Calendar.current.date(byAdding: .second, value: 1, to: finiteElement.start)!
        let events = finiteElement.events(from: start, to: finiteElement.end!)
        XCTAssert(events.isEmpty)
    }

    func testEventOccurenceIsCorrectOnQueriesThatDontStartFromTheBeginning() {
        let mid = Calendar.current.date(byAdding: .year, value: 2, to: date)!
        let end = Calendar.current.date(byAdding: .year, value: 4, to: date)!
        let events = element.events(from: mid, to: end)
        XCTAssert(events.count == 2)
        XCTAssert(events[0].occurence == 2)
        XCTAssert(events[1].occurence == 3)
    }

    func testReturnsEmptyArrayIfAskedForEventsStartingAfterEndDate() {
        var finiteElement = element
        finiteElement.end = Calendar.current.date(byAdding: .year, value: 5, to: date)
        let events = finiteElement.events(from: Calendar.current.date(byAdding: .year, value: 6, to: date)!,
                                          to: Calendar.current.date(byAdding: .year, value: 8, to: date)!)
        XCTAssert(events.isEmpty)
    }

    func testEventIntervals() {
        let stop = Calendar.current.date(byAdding: .year, value: 3, to: element.start)!
        let events = element.events(from: element.start, to: stop)
        for (index, event) in events.enumerated() {
            let expectedDate = Calendar.current.date(byAdding: .year, value: index, to: element.start)!
            XCTAssert(event.start == expectedDate)
            XCTAssert(event.occurence == index)
        }
    }

    func testEventsBetweenEqualIndicesReturnSingleElementArray() {
        XCTAssert(element.events(betweenOccurenceIndex: 0, and: 1).count == 1)
    }

    func testEventsBetweeUnequalIndicesReturnsTheCorrectNumberOfElements() {
        XCTAssert(element.events(betweenOccurenceIndex: 0, and: 2).count == 2)
        XCTAssert(element.events(betweenOccurenceIndex: 2, and: 5).count == 3)
    }

    func testEventsBetweenIndicesFillsTheArrayWithNilBeyondTheEndDate() {
        let start = date
        let end = Calendar.current.date(byAdding: .year, value: 5, to: start)
        let interval = DateComponents(year: 1)
        let element = OCKScheduleElement(start: start, end: end, interval: interval, text: nil, targetValues: [])
        let events = element.events(betweenOccurenceIndex: 2, and: 10)
        for index in 0..<8 {
            if index <= 3 {
                XCTAssert(events[index] != nil)
                XCTAssert(events[index]?.occurence == index + 2)
            }
            if index > 3 {
                XCTAssert(events[index] == nil)
            }
        }
    }

    func testEventsBetweenDatesIncludesEventsThatStartedBeforeTheStartDateButAreAllDayEvents() {
        let allDayElement = OCKScheduleElement(start: Calendar.current.startOfDay(for: Date()), end: nil,
                                               interval: DateComponents(weekOfYear: 1), isAllDay: true)

        let afternoon = Calendar.current.startOfDay(for: Date()).addingTimeInterval(60 * 60 * 12) // 12:00
        let evening = Calendar.current.startOfDay(for: Date()).addingTimeInterval(60 * 60 * 20) // 20:00
        let events = allDayElement.events(from: afternoon, to: evening)
        XCTAssert(events.count == 1, "Expected 1 event, but got: \(events.count)")
    }

    func testEventsBetweenDatesIncludesEventsThatStartAfterTheEndDateButAreAllDayEvents() {
        let morning = Calendar.current.startOfDay(for: Date()).addingTimeInterval(60 * 60 * 6) // 06:00
        let afternoon = Calendar.current.startOfDay(for: Date()).addingTimeInterval(60 * 60 * 12) // 12:00
        let evening = Calendar.current.startOfDay(for: Date()).addingTimeInterval(60 * 60 * 20) // 20:00

        let allDayElement = OCKScheduleElement(start: evening, end: nil,
                                               interval: DateComponents(weekOfYear: 1), isAllDay: true)

        let events = allDayElement.events(from: morning, to: afternoon)
        XCTAssert(events.count == 1, "Expected 1 event, but got: \(events.count)")
    }

    func testEventsBetweenDatesIncludeEventsWithMultidayDurationsThatStartedOnPreviousDays() {
        let morning = Calendar.current.startOfDay(for: Date())
        let threeDays = TimeInterval(60 * 60 * 24 * 3)
        let element = OCKScheduleElement(start: morning, end: nil, interval: DateComponents(day: 7), duration: threeDays)
        let twoDaysLater = Calendar.current.date(byAdding: .day, value: 2, to: morning)!
        let fourDaysLater = Calendar.current.date(byAdding: .day, value: 4, to: morning)!
        let events = element.events(from: twoDaysLater, to: fourDaysLater)
        XCTAssert(events.count == 1, "Expected 1 event, but got: \(events.count)")
    }

    func testEventsBetweenDatesIncludesMultidayAllDayEventsThatStartedOnPreviousDays() {
        let morning = Calendar.current.startOfDay(for: Date())
        let threeDays = TimeInterval(60 * 60 * 24 * 3)
        let element = OCKScheduleElement(start: morning, end: nil, interval: DateComponents(day: 7),
                                         duration: threeDays, isAllDay: true)
        let twoDaysLater = Calendar.current.date(byAdding: .day, value: 2, to: morning)!
        let fourDaysLater = Calendar.current.date(byAdding: .day, value: 4, to: morning)!
        let events = element.events(from: twoDaysLater, to: fourDaysLater)
        XCTAssert(events.count == 1, "Expected 1 event, but got: \(events.count)")
    }

    func testEventsBetweenDatesCanOverlap() {
        let morning = Calendar.current.startOfDay(for: Date())
        let twoHours = TimeInterval(60 * 60 * 2)
        let element = OCKScheduleElement(start: morning, end: nil, interval: DateComponents(hour: 1), duration: twoHours)
        let queryStart = morning.addingTimeInterval(60 * 60 * 1.5)
        let queryEnd = queryStart.addingTimeInterval(1)
        let events = element.events(from: queryStart, to: queryEnd)
        XCTAssert(events.count == 2)
    }
}
