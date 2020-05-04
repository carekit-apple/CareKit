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

    /// An text about the time this element represents.
    /// e.g. before breakfast on Tuesdays, 5PM every day, etc.
    public var text: String?

    /// The amount of time that the event should take, in seconds.
    public var duration: Duration

    /// The date and time the first event occurs.
    // Note: This must remain a constant because its value is modified by the `isAllDay` flag during initialization.
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
    /// For example, for a medcation, it may be the dose that the patient is expected to take.
    public var targetValues: [OCKOutcomeValue]

    /// Create a `ScheduleElement` by specying the start date, end date, and interval.
    ///
    /// - Parameters:
    ///   - start: Date specifying the exact day and time that the first occurrence of this task happens.
    ///   - end: Date specifying when the task ends. The end date is not inclusive.
    ///   - interval: DateComponents specifying the frequency at which the schedule repeats.
    ///   - text: A textual representation of this schedule element. Examples: "After breakfast", "08:00", "As needed throughout the day".
    ///   - targetValues: An array of values that represents goals for this schedule element.
    ///   - duration: A duration in seconds specifying how long the window to complete this event is.
    public init(start: Date, end: Date?, interval: DateComponents, text: String? = nil,
                targetValues: [OCKOutcomeValue] = [], duration: Duration = .hours(0)) {
        assert(end == nil || start < end!, "Start date must be before the end date!")
        assert(interval.movesForwardInTime, "Interval must not progress backwards in time!")

        self.start = duration == .allDay ? Calendar.current.startOfDay(for: start) : start
        self.end = end
        self.interval = interval
        self.text = text
        self.duration = duration
        self.targetValues = targetValues
    }

    /// Returns the Nth event of this schedule.
    ///
    /// - Parameter occurrence: The Nth occurrence.
    public subscript(occurrence: Int) -> OCKScheduleEvent {
        makeScheduleEvent(on: date(ofOccurrence: occurrence)!, for: occurrence)
    }

    public var elements: [OCKScheduleElement] {
        return [self]
    }

    /// - Returns: a new instance of with all event times offset by the given value.
    public func offset(by dateComponents: DateComponents) -> OCKScheduleElement {
        let newStart = Calendar.current.date(byAdding: dateComponents, to: start)!
        let newEnd = end == nil ? nil : Calendar.current.date(byAdding: dateComponents, to: end!)!
        return OCKScheduleElement(start: newStart, end: newEnd, interval: interval,
                                  text: text, targetValues: targetValues, duration: duration)
    }

    /// - Returns: An array containing either an schedule event or nil
    /// - Remark: Lower bound is inclusive, upper bound is exclusive.
    public func events(betweenOccurrenceIndex startIndex: Int, and stopIndex: Int) -> [OCKScheduleEvent?] {
        assert(stopIndex > startIndex, "Stop index must be greater than or equal to start index")
        let numberOfEvents = stopIndex - startIndex
        var currentOccurrence = 0
        var events = [OCKScheduleEvent?](repeating: nil, count: numberOfEvents)

        // Move to start index
        var currentDate = start
        for _ in 0..<startIndex {
            currentDate = Calendar.current.date(byAdding: interval, to: currentDate)!
            currentOccurrence += 1
        }

        // Calculate the event at each index in between start and top indices
        for index in 0..<numberOfEvents {
            if let endDate = end, currentDate > endDate { continue }
            events[index] = makeScheduleEvent(on: currentDate, for: currentOccurrence)
            currentDate = Calendar.current.date(byAdding: interval, to: currentDate)!
            currentOccurrence += 1
        }
        return events
    }

    public func events(from start: Date, to end: Date) -> [OCKScheduleEvent] {
        let stopDate = determineStopDate(onOrBefore: end)
        var current = self.start
        var dates = [Date]()
        while current < stopDate {
            dates.append(current)
            current = Calendar.current.date(byAdding: interval, to: current)!
        }
        let events = dates.enumerated().map { index, date in makeScheduleEvent(on: date, for: index) }
        return events.filter { event in
            if duration == .allDay { return true }
            return event.start + duration.seconds >= start
        }
    }

    /// Computes the date of the Nth occurrence of a schedule element. If the Nth occurrence is beyond the end date, then nil will be returned.
    public func date(ofOccurrence occurrence: Int) -> Date? {
        assert(occurrence >= 0, "Schedule events cannot have negative occurrence indices")
        var currentDate = start
        for _ in 0..<occurrence {
            guard let nextDate = Calendar.current.date(byAdding: interval, to: currentDate) else { fatalError("Invalid date!") }
            if let endDate = end, nextDate <= endDate { return nil }
            currentDate = nextDate
        }
        return currentDate
    }

    /// Determines the last date at which an event could possibly occur
    private func determineStopDate(onOrBefore date: Date) -> Date {
        if duration == .allDay {
          let stopDay = end ?? date
          let morningOfStopDay = Calendar.current.startOfDay(for: stopDay)
          let endOfStopDay = Calendar.current.date(byAdding: .init(day: 1, second: -1), to: morningOfStopDay)!
          return endOfStopDay
        }
        
        guard let endDate = end else { return date }
        return min(endDate, date)
    }

    private func makeScheduleEvent(on date: Date, for occurrence: Int) -> OCKScheduleEvent {
        let startDate = duration == .allDay ? Calendar.current.startOfDay(for: date) : date
        let endDate = duration == .allDay ?
            Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: startDate)! :
            startDate.addingTimeInterval(duration.seconds)
        return OCKScheduleEvent(start: startDate, end: endDate, element: self, occurrence: occurrence)
    }
}

private extension DateComponents {
    var movesForwardInTime: Bool {
        let now = Date()
        let then = Calendar.current.date(byAdding: self, to: now)!
        return then > now
    }
}
