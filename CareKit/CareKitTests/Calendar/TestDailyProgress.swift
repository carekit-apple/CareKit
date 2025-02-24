/*
 Copyright (c) 2023, Apple Inc. All rights reserved.
 
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

import XCTest

final class TestDailyProgress: XCTestCase {

    private let calendar = Calendar.current

    private let store = OCKStore(
        name: "TestDailyProgress.Store",
        type: .inMemory
    )

    override func setUp() async throws {
        try await super.setUp()
        try store.reset()
    }

    func testDailyProgressInStandardEvenInterval() async throws {

        let components = DateComponents(year: 2_022, month: 2, day: 10)
        let date = calendar.date(from: components)!

        let daysInInterval = 8

        let interval = interval(
            surrounding: date,
            daysInInterval: daysInInterval
        )

        try await validateDailyProgress(in: interval, daysInInterval: daysInInterval, shouldExpectProgress: true)
        try await validateDailyProgress(in: interval, daysInInterval: daysInInterval, shouldExpectProgress: false)
    }

    func testDailyProgressInStandardOddInterval() async throws {

        let components = DateComponents(year: 2_022, month: 2, day: 10)
        let date = calendar.date(from: components)!

        let daysInInterval = 7

        let interval = interval(
            surrounding: date,
            daysInInterval: daysInInterval
        )

        try await validateDailyProgress(in: interval, daysInInterval: daysInInterval, shouldExpectProgress: true)
        try await validateDailyProgress(in: interval, daysInInterval: daysInInterval, shouldExpectProgress: false)
    }

    func testDailyProgressInIntervalWithYearChange() async throws {

        let components = DateComponents(year: 2_022, month: 1, day: 1)
        let date = calendar.date(from: components)!

        let daysInInterval = 400

        let interval = interval(
            surrounding: date,
            daysInInterval: daysInInterval
        )

        try await validateDailyProgress(in: interval, daysInInterval: daysInInterval, shouldExpectProgress: true)
        try await validateDailyProgress(in: interval, daysInInterval: daysInInterval, shouldExpectProgress: false)
    }

    func testDailyProgressOverIntervalWithDSTChange() async throws {

        // At the moment, CareKit uses the default system calendar and does not allow for injection of a custom calendar.
        // That's an issue here because not every region follows DST. If this test is run in a region that does
        // not follow DST, this test won't actually be performing the right validations. We should offer a way to
        // inject the calendar as internal API.

        let componentsForDSTChange = DateComponents(year: 2_023, month: 3, day: 12)
        let dateForDSTChange = calendar.date(from: componentsForDSTChange)!

        let daysInInterval = 3

        let interval = interval(
            surrounding: dateForDSTChange,
            daysInInterval: daysInInterval
        )

        // Ensure daylight savings actually changes over the date interval
        guard
            calendar.timeZone.isDaylightSavingTime(for: interval.start) == false &&
            calendar.timeZone.isDaylightSavingTime(for: interval.end) == true
        else {
            return
        }

        try await validateDailyProgress(in: interval, daysInInterval: daysInInterval, shouldExpectProgress: true)
        try await validateDailyProgress(in: interval, daysInInterval: daysInInterval, shouldExpectProgress: false)
    }

    func testDailyProgressOverIntervalWithLeapYear() async throws {

        let componentsForLeapYear = DateComponents(year: 2_024, month: 1, day: 1)
        let dateForLeapYear = calendar.date(from: componentsForLeapYear)!

        let daysInInterval = 400

        let interval = interval(
            surrounding: dateForLeapYear,
            daysInInterval: daysInInterval
        )

        try await validateDailyProgress(in: interval, daysInInterval: daysInInterval, shouldExpectProgress: true)
        try await validateDailyProgress(in: interval, daysInInterval: daysInInterval, shouldExpectProgress: false)
    }

    func testDailyProgressIsUpdated() async throws {

        // 1. Generate a task

        let components = DateComponents(year: 2_022, month: 2, day: 10)
        let start = calendar.date(from: components)!

        let daysInInterval = 3
        let interval = interval(surrounding: start, daysInInterval: daysInInterval)

        let task = dailyTask(startingOn: interval.start)
        let storedTask = try await store.addTask(task)

        // 2. Observe daily progress. Update the progress after the stream has started outputting results.

        let allDailyProgress = store.dailyProgress(
            dateInterval: interval,
            computeProgress: { $0.computeProgress(by: .checkingOutcomeExists) }
        )
        .prefix(2)

        var outputCount = 0
        var dailyProgress: [TemporalProgress<BinaryCareTaskProgress>] = []

        for try await output in allDailyProgress {

            outputCount += 1

            // Generate progress after the stream has already started outputting results.
            // This should trigger another output through the stream.
            if outputCount == 1 {

                let outcomes = (0..<daysInInterval).map { occurrence in
                    return OCKOutcome(taskUUID: storedTask.uuid, taskOccurrenceIndex: occurrence, values: [])
                }

                _ = try await store.addOutcomes(outcomes)

            } else if outputCount == 2 {

                dailyProgress = output
            }
        }

        // 3. Validate the result

        XCTAssertEqual(dailyProgress.count, daysInInterval)

        dailyProgress.forEach { dailyProgress in
            XCTAssertEqual(dailyProgress.values.count, 1)
            XCTAssertEqual(dailyProgress.values.first?.isCompleted, true)
        }
    }

    // MARK: - Utilities

    private func validateDailyProgress(
        in interval: DateInterval,
        daysInInterval: Int,
        shouldExpectProgress: Bool
    ) async throws {

        // 1. Generate task progress on days in the interval

        try store.reset()

        // Generate tasks
        let task = dailyTask(startingOn: interval.start)
        let storedTask = try await store.addTask(task)

        // Generate outcomes for the tasks if needed
        if shouldExpectProgress {

            let outcomes = (0..<daysInInterval).map { occurrence in
                return OCKOutcome(taskUUID: storedTask.uuid, taskOccurrenceIndex: occurrence, values: [])
            }

            _ = try await store.addOutcomes(outcomes)
        }

        // 3. Fetch the daily progress

        let allDailyProgress = try await store.dailyProgress(
            dateInterval: interval,
            computeProgress: { $0.computeProgress(by: .checkingOutcomeExists) }
        )
        .prefix(1)
        .reduce(into: []) { results, next in
            results.append(next)
        }

        // 4. Validate the daily progress

        let dailyProgress = allDailyProgress.first ?? []
        XCTAssertEqual(dailyProgress.count, daysInInterval)

        let expectedDates = datesPerDay(in: interval)
        XCTAssertEqual(expectedDates.count, daysInInterval)

        let expectedProgress = Array(
            repeating: BinaryCareTaskProgress(isCompleted: shouldExpectProgress),
            count: expectedDates.count
        )

        let expectedDailyProgress = zip(expectedDates, expectedProgress)
            .map { date, progress in
                TemporalProgress(values: [progress], date: date)
            }

        XCTAssertEqual(expectedDailyProgress.count, dailyProgress.count)

        zip(expectedDailyProgress, dailyProgress).forEach {
            XCTAssertEqual($0, $1)
        }
    }

    private func dailyTask(startingOn start: Date) -> OCKTask {

        let schedule = OCKSchedule.dailyAtTime(hour: 7, minutes: 0, start: start, end: nil, text: nil)
        let task = OCKTask(id: "task", title: nil, carePlanUUID: nil, schedule: schedule)
        return task
    }

    private func datesPerDay(in interval: DateInterval) -> [Date] {

        let calendar = Calendar.current
        let midnight = DateComponents(hour: 0, minute: 0, second: 0)

        var results: [Date] = []

        calendar.enumerateDates(
            startingAfter: interval.start - 1,  // To ensure an inclusive start date
            matching: midnight,
            matchingPolicy: .nextTime
        ) { result, _, stop in

            guard
                let result,
                result < interval.end  // Exclusive end date
            else {
                stop = true
                return
            }

            results.append(result)
        }

        return results
    }

    private func interval(
        surrounding date: Date,
        daysInInterval: Int
    ) -> DateInterval {

        let startOfMidDate = calendar.startOfDay(for: date)

        let calendar = Calendar.current
        let leftOffset = daysInInterval / 2
        let rightOffset = daysInInterval % 2 == 0 ?
            daysInInterval / 2 - 1 :
            daysInInterval / 2

        assert(leftOffset + rightOffset == daysInInterval - 1)

        // Start of first day
        let start = calendar.date(byAdding: .day, value: -leftOffset, to: startOfMidDate)!

        // End of last day
        let endDay = calendar.date(byAdding: .day, value: rightOffset, to: startOfMidDate)!
        let end = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: endDay)!

        let interval = DateInterval(start: start, end: end)
        return interval
    }
}
