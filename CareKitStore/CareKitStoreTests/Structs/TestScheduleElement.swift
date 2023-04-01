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

    private let calendar = Calendar.current

    private lazy var beginningOfYear: Date = {
        let components = DateComponents(year: 2_023, month: 1, day: 1)
        let date = calendar.date(from: components)!
        return date
    }()

    private var everySecond: DateComponents {
        DateComponents(second: 1)
    }

    private var daily: DateComponents {
        DateComponents(day: 1)
    }
    
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

    // MARK: - Subscript

    func testSubscriptReturnsFirstEvent() {
        let dailySchedule = OCKScheduleElement(start: beginningOfYear, end: nil, interval: everySecond, duration: .seconds(1))
        let event = dailySchedule[0]
        XCTAssertEqual(event.start, beginningOfYear)
        XCTAssertEqual(event.end, beginningOfYear + 1)
    }

    func testSubscriptReturnsSecondEvent() {
        let dailySchedule = OCKScheduleElement(start: beginningOfYear, end: nil, interval: everySecond, duration: .seconds(1))
        let event = dailySchedule[1]
        XCTAssertEqual(event.start, beginningOfYear + 1)
        XCTAssertEqual(event.end, beginningOfYear + 2)
    }

    func testSubscriptReturnsTenthEvent() {
        let dailySchedule = OCKScheduleElement(start: beginningOfYear, end: nil, interval: everySecond, duration: .seconds(1))
        let event = dailySchedule[9]
        XCTAssertEqual(event.start, beginningOfYear + 9)
        XCTAssertEqual(event.end, beginningOfYear + 10)
    }

    // MARK: - Offset

    func testOffset() {
        let offset = DateComponents(year: 1)
        let originalElement = OCKScheduleElement(start: date, end: date.addingTimeInterval(10), interval: interval,
                                                 text: nil, targetValues: [])
        let offsetElement = originalElement.offset(by: offset)
        let expectedStartDate = Calendar.current.date(byAdding: offset, to: date)!
        XCTAssert(offsetElement.start == expectedStartDate)
    }

    // MARK: - Date of occurrence

    func testDateOfFirstOccurrence() {
        let dailySchedule = OCKScheduleElement(start: beginningOfYear, end: nil, interval: daily, duration: .seconds(1))
        let start = dailySchedule.date(ofOccurrence: 0)
        XCTAssertEqual(dailySchedule[0].start, start)
    }

    func testDateOfTenthOccurrence() {
        let dailySchedule = OCKScheduleElement(start: beginningOfYear, end: nil, interval: daily, duration: .seconds(1))
        let start = dailySchedule.date(ofOccurrence: 10)
        XCTAssertEqual(dailySchedule[10].start, start)
    }

    func testDateOccurrenceAfterExactScheduleEnd() {
        let nextDay = calendar.date(byAdding: .day, value: 1, to: beginningOfYear)
        let dailySchedule = OCKScheduleElement(start: beginningOfYear, end: nextDay, interval: daily, duration: .seconds(1))
        let start = dailySchedule.date(ofOccurrence: 1)
        XCTAssertNil(start)
    }

    func testDateOccurrenceAfterScheduleEnd() {
        let nextDay = calendar.date(byAdding: .hour, value: 1, to: beginningOfYear)
        let dailySchedule = OCKScheduleElement(start: beginningOfYear, end: nextDay, interval: daily, duration: .seconds(1))
        let start = dailySchedule.date(ofOccurrence: 1)
        XCTAssertNil(start)
    }

    // MARK: - Events between dates

    func testNoEventsBeforeStartDateForAllDayEvents() {
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let tonight = Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: thisMorning)!
        let aWeekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: thisMorning)!
        let element = OCKScheduleElement(start: aWeekAgo, end: nil, interval: DateComponents(day: 1),
                                         text: nil, targetValues: [], duration: .allDay)
        let events = element.events(from: thisMorning, to: tonight)
        XCTAssert(events.count == 1)
    }

    func testEventOccursExactlyOnStartDate() {
        let justAfter = Calendar.current.date(byAdding: .second, value: 1, to: element.start)!
        let events = element.events(from: date, to: justAfter)
        XCTAssert(events.first!.start == element.start)
    }

    func testEventCannotOccurExactlyOnEndDate() {
        
        var finiteElement = OCKScheduleElement(
            start: beginningOfYear,
            end: nil,
            interval: DateComponents(year: 1),
            text: "",
            targetValues: [],
            duration: .seconds(0)
        )
        
        // End the schedule right when the second event starts
        finiteElement.end = calendar.date(byAdding: .year, value: 1, to: beginningOfYear)!
        
        // Start the query after the first event
        let start = calendar.date(byAdding: .second, value: 1, to: finiteElement.start)!
        
        let events = finiteElement.events(from: start, to: finiteElement.end!)
        
        XCTAssert(events.isEmpty)
    }

    func testEventOccurrenceIsCorrectOnQueriesThatDontStartFromTheBeginning() {
        let mid = Calendar.current.date(byAdding: .year, value: 2, to: date)!
        let end = Calendar.current.date(byAdding: .year, value: 4, to: date)!
        let events = element.events(from: mid, to: end)
        XCTAssert(events.count == 2)
        XCTAssert(events[0].occurrence == 2)
        XCTAssert(events[1].occurrence == 3)
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
            XCTAssert(event.occurrence == index)
        }
    }

    func testEventsBetweenEqualIndicesReturnSingleElementArray() {
        XCTAssert(element.events(betweenOccurrenceIndex: 0, and: 1).count == 1)
    }

    func testEventsBetweenUnequalIndicesReturnsTheCorrectNumberOfElements() {
        XCTAssert(element.events(betweenOccurrenceIndex: 0, and: 2).count == 2)
        XCTAssert(element.events(betweenOccurrenceIndex: 2, and: 5).count == 3)
    }

    func testEventsBetweenIndicesStopsWhenHittingScheduleEnd() {
        let end = Calendar.current.date(byAdding: .year, value: 5, to: beginningOfYear)
        let interval = DateComponents(year: 1)
        let element = OCKScheduleElement(start: beginningOfYear, end: end, interval: interval, text: nil, targetValues: [])
        let events = element.events(betweenOccurrenceIndex: 2, and: 10)

        XCTAssertEqual(events.count, 3)

        let expectedOccurrences = Array(2...4)
        let observedOccurrences = events.map { $0.occurrence }
        XCTAssertEqual(expectedOccurrences, observedOccurrences)
    }

    func testEventsBetweenDatesIncludesEventsThatStartedBeforeTheStartDateButAreAllDayEvents() {
        let allDayElement = OCKScheduleElement(start: Calendar.current.startOfDay(for: Date()), end: nil,
                                               interval: DateComponents(weekOfYear: 1), duration: .allDay)

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
                                               interval: DateComponents(weekOfYear: 1), duration: .allDay)

        let events = allDayElement.events(from: morning, to: afternoon)
        XCTAssert(events.count == 1, "Expected 1 event, but got: \(events.count)")
    }

    func testEventsBetweenDatesIncludeEventsWithMultidayDurationsThatStartedOnPreviousDays() {
        let morning = Calendar.current.startOfDay(for: Date())
        let element = OCKScheduleElement(start: morning, end: nil, interval: DateComponents(day: 7), duration: .hours(24 * 3))
        let twoDaysLater = Calendar.current.date(byAdding: .day, value: 2, to: morning)!
        let fourDaysLater = Calendar.current.date(byAdding: .day, value: 4, to: morning)!
        let events = element.events(from: twoDaysLater, to: fourDaysLater)
        XCTAssert(events.count == 1, "Expected 1 event, but got: \(events.count)")
    }

    func testEventsBetweenDatesCanOverlap() {
        let morning = Calendar.current.startOfDay(for: Date())
        let element = OCKScheduleElement(start: morning, end: nil, interval: DateComponents(hour: 1), duration: .hours(2))
        let queryStart = morning.addingTimeInterval(60 * 60 * 1.5)
        let queryEnd = queryStart.addingTimeInterval(1)
        let events = element.events(from: queryStart, to: queryEnd)
        XCTAssert(events.count == 2)
    }

    func testAllDayEventIsFoundWhenScheduleEndsBeforeEventStart() {

        let scheduleStart = beginningOfYear + 2
        let scheduleEnd = beginningOfYear + 3

        let schedule = OCKScheduleElement(
            start: scheduleStart,
            end: scheduleEnd,
            interval: daily,
            duration: .allDay
        )

        let events = schedule.events(from: scheduleEnd, to: scheduleEnd + 1)
        XCTAssertEqual(events.count, 1)
    }

    func testAllDayEventIsFoundWhenScheduleEndsBeforeStartOfEvent() {

        let scheduleStart = beginningOfYear + 1

        // Schedule should end before start of the second event
        let scheduleEnd = calendar.date(
            byAdding: DateComponents(day: 1),
            to: scheduleStart
        )!

        let schedule = OCKScheduleElement(
            start: scheduleStart,
            end: scheduleEnd,
            interval: daily,
            duration: .allDay
        )

        let events = schedule.events(from: scheduleStart, to: scheduleEnd)
        XCTAssertEqual(events.count, 2)
    }

    func testAllDayEventIsNotFoundWhenScheduleEndsBeforeStartOfEvent() {

        let scheduleStart = beginningOfYear

        // Schedule should end  when the second event starts event ends
        let scheduleEnd = calendar.date(
            byAdding: DateComponents(day: 1),
            to: beginningOfYear
        )!

        let schedule = OCKScheduleElement(
            start: scheduleStart,
            end: scheduleEnd,
            interval: daily,
            duration: .allDay
        )

        let events = schedule.events(from: scheduleStart, to: scheduleEnd)
        XCTAssertEqual(events.count, 1)
    }

    // MARK: - Serialization

    func testSerialization() throws {
        let morning = Calendar.current.startOfDay(for: Date())
        let element = OCKScheduleElement(start: morning, end: nil, interval: DateComponents(hour: 1), duration: .hours(2))
        let data = try JSONEncoder().encode(element)
        let decodedElement = try JSONDecoder().decode(OCKScheduleElement.self, from: data)
        XCTAssert(element == decodedElement)
    }
}
