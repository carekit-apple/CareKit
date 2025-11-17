/*
 Copyright (c) 2016-2025, Apple Inc. All rights reserved.

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

import Foundation

/// An implementation of `OCKSchedulable` that can be created by composing together any number of other
/// `OCKSchedulable` objects, including other instance of `OCKSchedule`. This allows for the creation
/// of arbitrarily complex schedules.
///
/// - Note: A variety of initializers are provided to quickly create commonly used schedules. Used in
///         combination with the offset method, building up complex schedules can be performed quite
///         efficiently.
public struct OCKSchedule: Codable, Hashable, Sendable {

    /// The constituent components this schedule was built from.
    public let elements: [OCKScheduleElement]

    /// Create a new schedule by combining an array of other `OCKSchedule` objects.
    public init(composing schedules: [OCKSchedule]) {
        assert(!schedules.isEmpty, "You cannot create a schedule with 0 elements")
        self.elements = schedules.flatMap { $0.elements }.sorted(by: { $0.start < $1.start })
    }

    /// Create a new schedule by combining an array of other `OCKSchedule` objects.
    public init(composing elements: [OCKScheduleElement]) {
        assert(!elements.isEmpty, "You cannot create a schedule with 0 elements")
        self.elements = elements.sorted(by: { $0.start < $1.start })
    }

    /// Returns the Nth event of this schedule.
    ///
    /// - Parameter occurrence: The Nth occurrence.
    public subscript(occurrence: Int) -> OCKScheduleEvent {
        return event(forOccurrenceIndex: occurrence)!
    }

    /// The date of the first event of this schedule.
    ///
    /// - Note: This operation has an upperbound complexity of O(NlogN).
    public func startDate() -> Date {
        guard let earliestStartDate = elements.map({ $0.start }).sorted().min()
            else { fatalError("OCKSchedule should always have at least 1 element!") }
        return earliestStartDate
    }

    /// The date of the last event of this schedule, or nil if the schedule is of infinite length.
    ///
    /// - Note: This operation has an upperbound complexity of O(NlogN)
    public func endDate() -> Date? {
        let endDates = elements.map { $0.end }
        if endDates.contains(nil) { return nil }
        let finiteEndDates = endDates.compactMap({ $0 }).sorted()
        guard let lastEndDate = finiteEndDates.last else { fatalError("OCKSchedule should always have at least 1 element!") }
        return lastEndDate
    }

    /// Compute a list of events that occur between two dates. The lower bound is inclusive
    /// and the upper bound is exclusive.
    ///
    /// - Precondition: `start` < `end`
    ///
    /// - Parameters:
    ///   - start: The earliest date (inclusive) when an event can occur.
    ///   - end: The latest date (exclusive) when an event can occur.
    public func events(from start: Date, to end: Date) -> [OCKScheduleEvent] {

        precondition(start < end)

        // Algorithm:
        //
        // 1. Compute ALL events since the start of the schedule. Need to do that in order to
        //    compute the right occurrence index for each event. This is key and creates a need
        //    for the next complicated steps, and also makes this algorithm somewhat inefficient.
        // 2. Filter out events that fall outside of the query interval
        // 3. Sort all events and recompute their occurrence indices
        // 4. Remove events whose schedules ended before the query interval

        // Compute events from schedule start -> query end.
        let eventsBeforeQueryEnd = elements
            .filter { $0.start < end }
            .flatMap { $0.events(from: $0.start, to: end) }

        // Compute events from query start -> query end.
        let eventsMatchingQuery = eventsBeforeQueryEnd
            .filter { $0.end >= start }

        // Sort the events and adjust their occurrence indices to ensure they are
        // constantly increasing.
        let firstOccurrence = eventsBeforeQueryEnd.count - eventsMatchingQuery.count
        let events = stableSort(events: eventsMatchingQuery, startingOccurrence: firstOccurrence)

        // Filter out events whose schedules have ended
        let eventWithActiveSchedules = events.filter { event in
            event.element.end ?? .distantFuture > start
        }

        return eventWithActiveSchedules
    }

    /// Create a new schedule by shifting this schedule.
    ///
    /// - Parameter dateComponents: The amount of time to offset this schedule by.
    /// - Returns: A new instance of with all event times offset by the given value.
    public func offset(by dateComponents: DateComponents) -> OCKSchedule {
        return OCKSchedule(composing: elements.compactMap { $0.offset(by: dateComponents) })
    }

    /// Create a schedule that happens once per day, every day, at a fixed time.
    public static func dailyAtTime(hour: Int, minutes: Int, start: Date, end: Date?,
                                   text: String?, duration: OCKScheduleElement.Duration = .hours(1),
                                   targetValues: [OCKOutcomeValue] = []) -> OCKSchedule {
        let interval = DateComponents(day: 1)
        let startTime = Calendar.current.date(bySettingHour: hour, minute: minutes, second: 0, of: start)!
        let element = OCKScheduleElement(start: startTime, end: end, interval: interval,
                                         text: text, targetValues: targetValues, duration: duration)
        return OCKSchedule(composing: [element])
    }


    /// Create a schedule that happens once per week, every week, at a fixed time.
    public static func weeklyAtTime(weekday: Int, hours: Int, minutes: Int, start: Date, end: Date?, targetValues: [OCKOutcomeValue],
                                    text: String?, duration: OCKScheduleElement.Duration = .hours(1)) -> OCKSchedule {
        let interval = DateComponents(weekOfYear: 1)
        var startTime = Calendar.current.date(bySetting: .weekday, value: weekday, of: start)!
        startTime = Calendar.current.date(bySettingHour: hours, minute: minutes, second: 0, of: startTime)!
        let element = OCKScheduleElement(start: startTime, end: end, interval: interval,
                                         text: text, targetValues: targetValues, duration: duration)
        return OCKSchedule(composing: [element])
    }

    /// Compute the date of the Nth event. The result will be nil if the Nth event starts after the end of the schedule.
    ///
    /// - Precondition: `occurrence >= 0`
    ///
    /// - Parameter occurrence: The occurrence of the desired event.
    public func event(forOccurrenceIndex occurrence: Int) -> OCKScheduleEvent? {

        // This could be optimized. It is not an efficient algorithm.

        precondition(occurrence >= 0, "Schedule events cannot have negative occurrence indices")

        // Compute all events from 0 -> occurrence. This upper bound guarantees to compute
        // event with `occurrence` if it exists in the schedule.
        let allEvents = elements.flatMap { element in
            element.events(betweenOccurrenceIndex: 0, and: occurrence + 1)
        }

        // Sort the events and adjust their occurrence indices to ensure they are
        // constantly increasing.
        let mergedEvents = stableSort(events: allEvents, startingOccurrence: 0)

        // We are not guaranteed to find the occurrence if the schedule ends before it occurs.
        guard occurrence < mergedEvents.count else { return nil }

        return mergedEvents[occurrence]
    }

    func exists(onDay date: Date) -> Bool {
        let firstMomentOfTheDay = Calendar.current.startOfDay(for: date)
        let lastMomentOfTheDay = Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: firstMomentOfTheDay)!

        // If there is no end date, we just have to check that it starts before the end of the given day.
        guard let end = endDate() else {
            return startDate() <= lastMomentOfTheDay
        }

        // If there is an end date, the we need to ensure that it has already started, and hasn't ended yet.
        let startedOnTime = startDate() < lastMomentOfTheDay
        let didntEndTooEarly = end > firstMomentOfTheDay

        return startedOnTime && didntEndTooEarly
    }

    /// Sort the events and update their occurrences to range from `startingOccurrence` to n. It's important that
    /// we use a stable sort on the events because their occurrence indices should never change across calls to this
    /// method. The occurrence index is computed based on the sort order, and the occurrence index is stored in the
    /// database when an outcome for the event is created. We need to ensure an occurrence index will always map
    /// to the same event.
    private func stableSort(
        events: [OCKScheduleEvent],
        startingOccurrence: Int
    ) -> [OCKScheduleEvent] {

        // Sort events by start time
        let sortedEvents = events.sorted { $0.start < $1.start }

        // Now that the events are sorted, their occurrence indices are out of order.
        // Adjust them and make sure they start at `startingOccurrence`.
        let eventsWithAdjustedOccurrences = sortedEvents
            .enumerated()
            .map { occurrenceOffset, event in
                var newEvent = event
                newEvent.occurrence = startingOccurrence + occurrenceOffset
                return newEvent
            }

        return eventsWithAdjustedOccurrences
    }
}
