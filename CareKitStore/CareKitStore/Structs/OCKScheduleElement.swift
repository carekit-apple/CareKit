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

import Foundation

/// The simplest possible `OCKSchedulable`, representing a single event that repeats at
/// fixed intervals. It may have fixed duration or repeat indefinitely.
public struct OCKScheduleElement: Codable, Equatable {

    // Disabled because nested types are an internal implementation detail.

    /// A duration describing the length of an event. Options include all day, or a deterministic number of hours, minutes, or seconds.
    public enum Duration: Codable, Equatable {
        /// Describes an duration that fills an entire date
        case allDay

        /// Describes a fixed duration in seconds
        case seconds(Double)

        /// Creates a duration that represents a given number of hours.
        public static func hours(_ hours: Double) -> Duration {
            .seconds(60 * 60 * hours)
        }

        /// Creates a duration that represents a given number of minutes.
        public static func minutes(_ minutes: Double) -> Duration {
            .seconds(60 * minutes)
        }

        private enum CodingKeys: CodingKey {
            case isAllDay
            case seconds
        }

        var seconds: TimeInterval {
            switch self {
            case .allDay: return 0
            case .seconds(let seconds): return seconds
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self == .allDay, forKey: .isAllDay)
            if case .seconds(let seconds) = self {
                try container.encode(seconds, forKey: .seconds)
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if try container.decodeIfPresent(Bool.self, forKey: .isAllDay) == true {
                self = .allDay
                return
            }
            if let seconds = try container.decodeIfPresent(Double.self, forKey: .seconds) {
                self = .seconds(seconds)
                return
            }
            throw DecodingError.dataCorruptedError(forKey: CodingKeys.seconds, in: container, debugDescription: "No seconds or allDay key was found!")
        }
    }

    private var calendar = Calendar.current

    /// An text about the time this element represents.
    /// e.g. before breakfast on Tuesdays, 5PM every day, etc.
    public var text: String?

    /// The amount of time that the event should take, in seconds.
    public var duration: Duration

    // Note: This must remain a constant because its value is modified by the `isAllDay` flag during initialization.
    //
    /// The date and time the first event occurs.
    public let start: Date

    /// The latest possible time for an event to occur.
    /// - Note: Depending on the interval chosen, it is not guaranteed that an event
    ///         will fall on this date.
    /// - Note: If no date is provided, the schedule will repeat indefinitely.
    public var end: Date?

    /// The amount of time between events specified using `DateCoponents`.
    /// - Note: `DateComponents` are chose over `TimeInterval` to account for edge
    ///         edge cases like daylight savings time and leap years.
    public var interval: DateComponents

    /// An array of values that specify what values the user is expected to record.
    /// For example, for a medication, it may be the dose that the patient is expected to take.
    public var targetValues: [OCKOutcomeValue]

    /// Create a `ScheduleElement` by specifying the start date, end date, and interval.
    ///
    /// - Precondition: `start` < `end`
    /// - Precondition: `interval` should move forwards in time
    ///
    /// - Parameters:
    ///   - start: Date specifying the exact day and time that the first occurrence of this task happens.
    ///   - end: Date specifying when the task ends. The end date is not inclusive.
    ///   - interval: DateComponents specifying the frequency at which the schedule repeats.
    ///   - text: A textual representation of this schedule element. Examples: "After breakfast", "08:00", "As needed throughout the day".
    ///   - targetValues: An array of values that represents goals for this schedule element.
    ///   - duration: A duration in seconds specifying how long the window to complete this event is.
    public init(start: Date, end: Date?, interval: DateComponents, text: String? = nil,
                targetValues: [OCKOutcomeValue] = [], duration: Duration = .hours(1)) {

        precondition(end == nil || start < end!, "Start date must be before the end date!")
        precondition(interval.movesForwardInTime(calendar: calendar), "Interval must not progress backwards in time!")

        self.start = duration == .allDay ? calendar.startOfDay(for: start) : start
        self.end = end
        self.interval = interval
        self.text = text
        self.duration = duration
        self.targetValues = targetValues
    }

    /// Compute the Nth event of this schedule.
    ///
    /// - Parameter occurrence: The Nth occurrence.
    public subscript(occurrence: Int) -> OCKScheduleEvent {

        guard let event = event(forOccurrenceIndex: occurrence) else {
            fatalError("Invalid occurrence index")
        }

        return event
    }

    @available(*, deprecated, message: "OCKScheduleElement.elements has been deprecated")
    public var elements: [OCKScheduleElement] {
        return [self]
    }

    /// - Returns: a new instance of with all event times offset by the given value.
    public func offset(by dateComponents: DateComponents) -> OCKScheduleElement {
        let newStart = calendar.date(byAdding: dateComponents, to: start)!
        let newEnd = end == nil ? nil : calendar.date(byAdding: dateComponents, to: end!)!
        return OCKScheduleElement(start: newStart, end: newEnd, interval: interval,
                                  text: text, targetValues: targetValues, duration: duration)
    }

    /// Compute all events that occur between `startIndex` (inclusive) and `stopIndex` (exclusive). The result
    /// might not contain the desired events if the schedule ends before a particular event starts.
    ///
    /// - Precondition: `startIndex` < `stopIndex`
    ///
    /// - Parameters:
    ///   - startIndex: The inclusive lower bound for the event indices.
    ///   - stopIndex: The exclusive upper bound for the event indices.
    public func events(betweenOccurrenceIndex startIndex: Int, and stopIndex: Int) -> [OCKScheduleEvent] {

        precondition(stopIndex > startIndex, "Stop index must be greater than or equal to start index")

        // Compute events from 0 -> stopIndex
        let eventsUpToStopIndex = computeEventsWhile { event in
            return event.occurrence < stopIndex
        }

        // Drop events 0 -> startIndex. The result is events from startIndex -> stopIndex.
        let events = eventsUpToStopIndex
            .dropFirst(startIndex)

        return Array(events)
    }

    /// Compute all events that occur between `start` (inclusive) and `end` (exclusive).
    ///
    /// - Precondition: `start` < `end`
    ///
    /// - Parameters:
    ///   - start: The inclusive earliest start time for an event.
    ///   - end: The exclusive latest start time for an event.
    public func events(from start: Date, to end: Date) -> [OCKScheduleEvent] {

        precondition(start < end)

        // Compute event from schedule start -> query end
        let eventsUpToQueryEnd = computeEventsWhile { event in
            return isEventStart(event.start, beforeLimit: end)
        }

        // Drop events from schedule start -> query end. The result is events from
        // query start -> query end.
        let events = eventsUpToQueryEnd.filter { event in
            return event.end >= start
        }

        return events
    }

    /// Computes the date of the Nth event. The result will be nil if the Nth event starts after the end of the schedule.
    ///
    /// - Precondition: `occurrence >= 0`
    ///
    /// - Parameter occurrence: The occurrence of the desired event.
    public func date(ofOccurrence occurrence: Int) -> Date? {

        precondition(occurrence >= 0, "Schedule events cannot have negative occurrence indices")

        // Compute events from 0 -> occurrence
        let eventsUpToDesiredOccurrence = computeEventsWhile { event in
            // +1 to include event occurrence matching `occurrence` due to exclusive upper bound
            return event.occurrence < occurrence + 1
        }

        guard
            let event = eventsUpToDesiredOccurrence.last,
            // The occurrence may not exist if the schedule ends too early
            event.occurrence == occurrence
        else {
            return nil
        }

        return event.start
    }

    func event(forOccurrenceIndex occurrence: Int) -> OCKScheduleEvent? {
        let events = events(betweenOccurrenceIndex: occurrence, and: occurrence + 1)
        let event = events.first
        return event
    }

    // Compute events starting from the start of the schedule moving forward in time. Stop the computation when
    // the provided predicate evaluates to `false`, or when the end of the schedule is reached.
    private func computeEventsWhile(
        shouldContinue: (OCKScheduleEvent) -> Bool
    ) -> [OCKScheduleEvent] {

        // The first possible event
        var nextEvent = computeEvent(on: start, occurrence: 0)

        // The result to accumulate
        var events: [OCKScheduleEvent] = []

        while
            let event = nextEvent,
            shouldContinue(event)
        {
            // Store the current event in the result
            events.append(event)

            // Create a new event for the next iteration
            let start = calendar.date(byAdding: interval, to: event.start)!

            nextEvent = computeEvent(
                on: start,
                occurrence: event.occurrence + 1
            )
        }

        return events
    }

    /// Compute an event on a particular date. Returns nil if the event starts after the end of the schedule.
    private func computeEvent(
        on date: Date,
        occurrence: Int
    ) -> OCKScheduleEvent? {

        let start: Date
        let end: Date

        switch duration {

        case .allDay:
            start = calendar.startOfDay(for: date)
            end = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: start)!

        case let .seconds(seconds):
            start = date
            end = start.addingTimeInterval(seconds)
        }

        // Don't create an event after the end of the schedule
        if
            let scheduleEnd = self.end,
            isEventStart(start, beforeLimit: scheduleEnd) == false
        {
            return nil
        }

        let event = OCKScheduleEvent(start: start, end: end, element: self, occurrence: occurrence)
        return event
    }

    private func isEventStart(
        _ eventStart: Date,
        beforeLimit limit: Date
    ) -> Bool {

        let occursBeforeLimit = eventStart < limit

        switch duration {

        // Fixed length events are valid if they start before the limit
        case .seconds:
            return occursBeforeLimit

        // All day events are valid if they start before or on the same day as the limit
        case .allDay:

            // Subtract a second from the limit to ensure an exclusive end date
            let adjustedLimit = calendar.date(byAdding: .second, value: -1, to: limit)!
            let occursOnSameDayAsLimit = calendar.isDate(eventStart, inSameDayAs: adjustedLimit)

            return occursBeforeLimit || occursOnSameDayAsLimit
        }
    }
}

private extension DateComponents {

    func movesForwardInTime(calendar: Calendar) -> Bool {
        let now = Date()
        let then = calendar.date(byAdding: self, to: now)!
        return then > now
    }
}
