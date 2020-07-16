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

class TestTask: XCTestCase {

    func testBelongsToReturnsFalseIfIDsDontMatch() {
        let plan = OCKCarePlan(id: "A", title: "obesity", patientUUID: nil)
        let task = OCKTask(id: "B", title: nil, carePlanUUID: nil, schedule: .mealTimesEachDay(start: Date(), end: nil))
        XCTAssertFalse(task.belongs(to: plan))
    }

    func testBelongsToReturnsTrueIfIDsDoMatch() {
        var plan = OCKCarePlan(id: "A", title: "obesity", patientUUID: nil)
        plan.uuid = UUID()
        let task = OCKTask(id: "B", title: nil, carePlanUUID: plan.uuid, schedule: .mealTimesEachDay(start: Date(), end: nil))
        XCTAssertTrue(task.belongs(to: plan))
    }

    // MARK: Task Query Filtering

    func testFilteringIncludesEventsThatStartBeforeTheQueryButHaveADurationIntoTheQueryInterval() {
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let schedule = OCKSchedule.dailyAtTime(hour: 9, minutes: 0, start: thisMorning, end: nil, text: nil, duration: .hours(2))
        let task = OCKTask(id: "abc123", title: "TaskA", carePlanUUID: nil, schedule: schedule)

        let queryStart = Calendar.current.date(byAdding: .hour, value: 1, to: schedule.startDate())! // 10:00
        let queryEnd = Calendar.current.date(byAdding: .hour, value: 4, to: schedule.startDate())! // 13:00
        let query = OCKTaskQuery(dateInterval: DateInterval(start: queryStart, end: queryEnd))
        XCTAssert([task].filtered(against: query) == [task])
    }

    func testFilteringIncludesAllDayEventsThatStartBeforeTheQuery() {
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let element = OCKScheduleElement(start: thisMorning, end: nil, interval: DateComponents(weekOfYear: 1), text: nil, duration: .allDay)
        let schedule = OCKSchedule(composing: [element])
        let task = OCKTask(id: "abc123", title: "TaskA", carePlanUUID: nil, schedule: schedule)

        let queryStart = Calendar.current.date(byAdding: .hour, value: 10, to: thisMorning)! // 10:00
        let queryEnd = Calendar.current.date(byAdding: .hour, value: 13, to: thisMorning)! // 13:00
        let query = OCKTaskQuery(dateInterval: DateInterval(start: queryStart, end: queryEnd))
        XCTAssert([task].filtered(against: query) == [task])
    }

    func testFilteringIncludesAllDayEventsThatStartAfterTheQuery() {
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let tonight = Calendar.current.date(byAdding: .hour, value: 20, to: thisMorning)! // 20:00
        let element = OCKScheduleElement(start: tonight, end: nil, interval: DateComponents(weekOfYear: 1), text: nil, duration: .allDay)
        let schedule = OCKSchedule(composing: [element])
        let task = OCKTask(id: "abc123", title: "TaskA", carePlanUUID: nil, schedule: schedule)

        let queryStart = Calendar.current.date(byAdding: .hour, value: 10, to: thisMorning)! // 10:00
        let queryEnd = Calendar.current.date(byAdding: .hour, value: 13, to: thisMorning)! // 13:00
        let query = OCKTaskQuery(dateInterval: DateInterval(start: queryStart, end: queryEnd))
        XCTAssert([task].filtered(against: query) == [task])
    }

    func testFilteringIncludesTasksForWhichNoEventOccursDuringTheQueryRange() {
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let schedule = OCKSchedule.dailyAtTime(hour: 6, minutes: 0, start: thisMorning, end: nil, text: nil)
        let task = OCKTask(id: "abc123", title: "TaskA", carePlanUUID: nil, schedule: schedule)

        let queryStart = Calendar.current.date(byAdding: .hour, value: 10, to: thisMorning)! // 10:00
        let queryEnd = Calendar.current.date(byAdding: .hour, value: 13, to: thisMorning)! // 13:00
        let query = OCKTaskQuery(dateInterval: DateInterval(start: queryStart, end: queryEnd))
        XCTAssert([task].filtered(against: query) == [task])
    }

    func testFilteringIncludesEventsThatStartedOnThePreviousDay() {
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: thisMorning)!
        let schedule = OCKSchedule.dailyAtTime(hour: 11, minutes: 0, start: yesterday, end: nil, text: nil, duration: .hours(5))
        let task = OCKTask(id: "abc123", title: "TaskA", carePlanUUID: nil, schedule: schedule)

        let queryStart = Calendar.current.date(byAdding: .hour, value: 1, to: thisMorning)! // 01:00
        let queryEnd = Calendar.current.date(byAdding: .hour, value: 2, to: thisMorning)!
        let query = OCKTaskQuery(dateInterval: DateInterval(start: queryStart, end: queryEnd))
        XCTAssert([task].filtered(against: query) == [task])
    }

    func testFilteringRespectsEffectiveDate() throws {
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: thisMorning)!

        let schedule = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: tomorrow, end: nil, text: nil)
        var task = OCKTask(id: "A", title: "a", carePlanUUID: nil, schedule: schedule)
        task.effectiveDate = thisMorning

        let query = OCKTaskQuery(dateInterval: DateInterval(start: thisMorning, end: tomorrow))
        XCTAssert([task].filtered(against: query) == [task])
    }

    func testFilteringExcludesTasksNotDefinedInTheQueryInterval() {
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let tomorrowMorning = Calendar.current.date(byAdding: .day, value: 1, to: thisMorning)!
        let schedule = OCKSchedule.dailyAtTime(hour: 6, minutes: 0, start: thisMorning, end: tomorrowMorning, text: nil)
        let task = OCKTask(id: "abc123", title: "TaskA", carePlanUUID: nil, schedule: schedule)

        let queryStart = Calendar.current.date(byAdding: .hour, value: 10, to: tomorrowMorning)! // 10:00
        let queryEnd = Calendar.current.date(byAdding: .hour, value: 13, to: tomorrowMorning)! // 13:00
        let query = OCKTaskQuery(dateInterval: DateInterval(start: queryStart, end: queryEnd))
        XCTAssert([task].filtered(against: query).isEmpty)
    }

    func testThatAMultiDayEventIsIncludedByQueriesOnAllDays() {
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let nextWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: thisMorning)!
        let element = OCKScheduleElement(start: thisMorning, end: nextWeek, interval: DateComponents(day: 7), duration: .hours(24 * 3 + 1))
        let schedule = OCKSchedule(composing: [element])
        let task = OCKTask(id: "abc123", title: "TaskA", carePlanUUID: nil, schedule: schedule)

        for dayOffset in 0...3 {
            let day = Calendar.current.date(byAdding: .day, value: dayOffset, to: thisMorning)!
            var query = OCKTaskQuery(for: day)
            query.excludesTasksWithNoEvents = true
            XCTAssert([task].filtered(against: query) == [task], "Failed on offset: \(dayOffset)")
        }

        for dayOffset in 4...7 {
            let day = Calendar.current.date(byAdding: .day, value: dayOffset, to: thisMorning)!
            var query = OCKTaskQuery(for: day)
            query.excludesTasksWithNoEvents = true
            XCTAssert([task].filtered(against: query) == [], "Failed on offset: \(dayOffset)")
        }
    }

    func testIdentitiesMatch() {
        let schedule = OCKSchedule.dailyAtTime(hour: 7, minutes: 0, start: Date(), end: nil, text: nil)

        var task1 = OCKTask(id: "doxylamine", title: "Title1", carePlanUUID: nil, schedule: schedule)
        var task2 = OCKTask(id: "doxylamine", title: "Title2", carePlanUUID: nil, schedule: schedule)
        XCTAssertEqual(task1.uuid, task2.uuid)

        let uuid = UUID()
        task1.uuid = uuid
        task2.uuid = uuid
        XCTAssertEqual(task1.uuid, task2.uuid)
    }

    func testIdentitiesDoNotMatch() {
        let schedule = OCKSchedule.dailyAtTime(hour: 7, minutes: 0, start: Date(), end: nil, text: nil)

        var task1 = OCKTask(id: "doxylamine", title: "Title1", carePlanUUID: nil, schedule: schedule)
        var task2 = OCKTask(id: "doxylamine", title: "Title2", carePlanUUID: nil, schedule: schedule)
        task1.uuid = UUID()
        task2.uuid = UUID()
        XCTAssertNotEqual(task1.uuid, task2.uuid)
    }
}
