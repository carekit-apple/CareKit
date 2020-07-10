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

class TestSchedule: XCTestCase {
    func testScheduleCreatedFromElementsIsEqualToThatSchedulesElements() {
        let spacing = DateComponents(day: 1)
        let element = OCKScheduleElement(start: Date(), end: nil, interval: spacing, text: nil, targetValues: [])
        let schedule = OCKSchedule(composing: [element])
        XCTAssert(schedule.elements == [element], "The schedule elements was not equal to the elements that created it")
    }

    func testDailySchedule() {
        let schedule = OCKSchedule.dailyAtTime(hour: 8, minutes: 0, start: Date(), end: nil, text: nil)
        for index in 0..<5 {
            XCTAssert(schedule[index].start == Calendar.current.date(byAdding: DateComponents(day: index), to: schedule.startDate()))
        }
    }

    func testDailyScheduleOccurrenceIndices() {
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let threeDaysFromNow = Calendar.current.date(byAdding: .day, value: 3, to: thisMorning)!
        let schedule = OCKSchedule.dailyAtTime(hour: 8, minutes: 0, start: thisMorning, end: nil, text: nil)
        let events = schedule.events(from: thisMorning, to: threeDaysFromNow)
        XCTAssert(events.count == 3)
        XCTAssert(events[0].occurrence == 0)
        XCTAssert(events[1].occurrence == 1)
        XCTAssert(events[2].occurrence == 2)
    }

    func testAllDayEventsCapturedByEventsBetweenDates() {
        let morning = Calendar.current.startOfDay(for: Date())
        let breakfast = Calendar.current.date(byAdding: .hour, value: 7, to: morning)!
        let lunch = Calendar.current.date(byAdding: .hour, value: 12, to: morning)!
        let dinner = Calendar.current.date(byAdding: .hour, value: 18, to: morning)!
        let allDay = OCKScheduleElement(start: breakfast, end: nil, interval: DateComponents(day: 1), text: "Daily", duration: .allDay)
        let schedule = OCKSchedule(composing: [allDay])
        let events = schedule.events(from: lunch, to: dinner)
        XCTAssert(events.count == 1, "Expected 1 all day event, but got \(events.count)")
    }

    func testWeeklySchedule() {
        let schedule = OCKSchedule.weeklyAtTime(weekday: 1, hours: 0, minutes: 0, start: Date(), end: nil, targetValues: [], text: nil)
        for index in 0..<5 {
            XCTAssert(schedule[index].start == Calendar.current.date(byAdding: DateComponents(weekOfYear: index), to: schedule.startDate()))
        }
    }

    func testWeeklyScheduleStartDate() {
        let firstDay = Date()

        let weekly = OCKSchedule.weeklyAtTime(
            weekday: 1, hours: 5, minutes: 30,
            start: firstDay, end: nil, targetValues: [], text: nil)

        let hours = Calendar.current.component(.hour, from: weekly.startDate())
        let minutes = Calendar.current.component(.minute, from: weekly.startDate())

        XCTAssert(hours == 5, "Expected 5, but got \(hours)")
        XCTAssert(minutes == 30, "Expected 30, but got \(minutes)")
    }

    func testScheduleComposition() {
        let components = DateComponents(year: 2_019, month: 1, day: 19, hour: 15, minute: 30)
        let startDate = Calendar.current.date(from: components)!
        let scheduleA = OCKSchedule.mealTimesEachDay(start: startDate, end: nil)
        let scheduleB = OCKSchedule.mealTimesEachDay(start: startDate, end: nil)
        let schedule = OCKSchedule(composing: [scheduleA, scheduleB])
        XCTAssert(schedule.elements.count == 6)
    }

    func testStartDate() {
        let earlyDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let lateDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let scheduleA = OCKSchedule.dailyAtTime(hour: 10, minutes: 0, start: earlyDate, end: nil, text: nil)
        let scheduleB = OCKSchedule.dailyAtTime(hour: 11, minutes: 0, start: lateDate, end: nil, text: nil)
        let schedule = OCKSchedule(composing: [scheduleA, scheduleB])
        XCTAssert(schedule.startDate() == scheduleA.startDate())
    }

    func testEndDateIsNilIfAnyComponentHasANilStartDate() {
        let earlyDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let lateDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let scheduleA = OCKSchedule.dailyAtTime(hour: 10, minutes: 0, start: earlyDate, end: lateDate, text: nil)
        let scheduleB = OCKSchedule.dailyAtTime(hour: 11, minutes: 0, start: lateDate, end: nil, text: nil)
        let schedule = OCKSchedule(composing: [scheduleA, scheduleB])
        XCTAssert(schedule.endDate() == nil)
    }

    func testEndDateIsNonNilAndMatchesLatestEndDateIfAllComponentsHaveFiniteEndDate() {
        let earlyDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let lateDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let laterDate = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        let scheduleA = OCKSchedule.dailyAtTime(hour: 10, minutes: 0, start: earlyDate, end: lateDate, text: nil)
        let scheduleB = OCKSchedule.dailyAtTime(hour: 11, minutes: 0, start: earlyDate, end: laterDate, text: nil)
        let schedule = OCKSchedule(composing: [scheduleA, scheduleB])
        XCTAssert(schedule.endDate() == scheduleB.endDate())
        XCTAssertNotNil(schedule.endDate())
    }

    func testScheduleOffset() {
        let date = Date()
        let originalSchedule = OCKSchedule.dailyAtTime(hour: 0, minutes: 0, start: date, end: nil, text: nil)
        let offsetSchedule = originalSchedule.offset(by: DateComponents(hour: 1))
        let expectedSchedule = OCKSchedule.dailyAtTime(hour: 1, minutes: 0, start: date, end: nil, text: nil)
        XCTAssert(offsetSchedule == expectedSchedule)
    }

    func testScheduleEventsAreSortedByDate() {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 10, to: startDate)!

        let scheduleA = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: startDate, end: nil, text: nil)
        let scheduleB = OCKSchedule.mealTimesEachDay(start: startDate, end: nil)
        let schedule = OCKSchedule(composing: [scheduleA, scheduleB])

        let events = schedule.events(from: startDate, to: endDate)
        for index in 0..<events.count - 1 {
            XCTAssert(events[index] <= events[index + 1])
        }
    }

    func testSubscriptZeroIsEqualToStartDate() {
        let schedule = OCKSchedule.dailyAtTime(hour: 8, minutes: 0, start: Date(), end: nil, text: nil)
        XCTAssert(schedule[0].start == schedule.startDate())
    }

    func testScheduleSubscriptInterleavesComposedSchedulesEventsInChronologicalOrder() {
        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .day, value: 2, to: startDate)!
        let scheduleA = OCKSchedule.mealTimesEachDay(start: startDate, end: endDate) // 07:30, 12:00, 17:30
        let scheduleB = OCKSchedule.dailyAtTime(hour: 11, minutes: 0, start: startDate, end: endDate, text: nil)
        let scheduleC = OCKSchedule.dailyAtTime(hour: 13, minutes: 0, start: startDate, end: endDate, text: nil)
        let schedule = OCKSchedule(composing: [scheduleA, scheduleB, scheduleC])

        func compareScheduleEventExcludingOccurrence(left: OCKScheduleEvent, right: OCKScheduleEvent) {
            XCTAssert(left.element == right.element)
            XCTAssert(left.start == right.start)
            XCTAssert(left.end == right.end)
        }

        compareScheduleEventExcludingOccurrence(left: schedule[0], right: scheduleA[0])    // 07:30 Day 1
        compareScheduleEventExcludingOccurrence(left: schedule[1], right: scheduleB[0])    // 11:00 Day 1
        compareScheduleEventExcludingOccurrence(left: schedule[2], right: scheduleA[1])    // 12:00 Day 1
        compareScheduleEventExcludingOccurrence(left: schedule[3], right: scheduleC[0])    // 13:00 Day 1
        compareScheduleEventExcludingOccurrence(left: schedule[4], right: scheduleA[2])    // 17:30 Day 1
        compareScheduleEventExcludingOccurrence(left: schedule[5], right: scheduleA[3])    // 07:30 Day 2
        compareScheduleEventExcludingOccurrence(left: schedule[6], right: scheduleB[1])    // 11:00 Day 2
        compareScheduleEventExcludingOccurrence(left: schedule[7], right: scheduleA[4])    // 12:00 Day 2
        compareScheduleEventExcludingOccurrence(left: schedule[8], right: scheduleC[1])    // 13:00 Day 2
        compareScheduleEventExcludingOccurrence(left: schedule[9], right: scheduleA[5])    // 17:30 Day 2
        for index in 0..<10 {
            XCTAssert(schedule[index].occurrence == index)
        }
    }

    func testScheduleCorrectlyComposesOccurrenceNumbers() {
        let startDate = Calendar.current.startOfDay(for: Date())
        let middleDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
        let endDate = Calendar.current.date(byAdding: .day, value: 2, to: startDate)!
        let mealSchedule = OCKSchedule.mealTimesEachDay(start: startDate, end: nil)
        let events = mealSchedule.events(from: middleDate, to: endDate)
        XCTAssert(events.count == 3)
        XCTAssert(events[0].occurrence == 3)
        XCTAssert(events[1].occurrence == 4)
        XCTAssert(events[2].occurrence == 5)
    }

    func testScheduleIntervalsHaveInclusiveLowerBoundAndExclusiveUpperBound() {
        let element = OCKScheduleElement(start: Date(), end: nil, interval: DateComponents(day: 1), text: nil, targetValues: [], duration: .allDay)
        let schedule = OCKSchedule(composing: [element])
        let events = schedule.events(from: schedule[1].start, to: schedule[1].end)
        XCTAssert(events.count == 1)
        XCTAssert(events.first?.occurrence == 1)
    }

    // Measure how long it takes to generate 10 years worth of events for a highly complex schedule with hourly events.
    // Results in the computatin of about 100,000 events.
    func testEventGenerationPerformanceHeavySchedule() {
        let now = Calendar.current.startOfDay(for: Date())
        let hourElement = OCKScheduleElement(start: now, end: nil, interval: DateComponents(hour: 1))
        let halfdayElement = OCKScheduleElement(start: now, end: nil, interval: DateComponents(hour: 12))
        let dayElement = OCKScheduleElement(start: now, end: nil, interval: DateComponents(day: 1))
        let weekElement = OCKScheduleElement(start: now, end: nil, interval: DateComponents(weekOfYear: 1))
        let fortnightElement = OCKScheduleElement(start: now, end: nil, interval: DateComponents(day: 14))
        let schedule = OCKSchedule(composing: [hourElement, halfdayElement, dayElement, weekElement, fortnightElement])
        let farFuture = Calendar.current.date(byAdding: .year, value: 10, to: now)!

        measure {
            _ = schedule.events(from: now, to: farFuture)
        }
    }

    // Measures how long it takes to generate 2 years of events for a typical schedule with daily events.
    // Results in the computation of about 730 events.
    func testEventGenerationPerformanceBasicSchedule() {
        let now = Calendar.current.startOfDay(for: Date())
        let schedule = OCKSchedule.dailyAtTime(hour: 8, minutes: 0, start: now, end: nil, text: nil)
        let farFuture = Calendar.current.date(byAdding: .year, value: 2, to: now)!

        measure {
            _ = schedule.events(from: now, to: farFuture)
        }
    }
}
