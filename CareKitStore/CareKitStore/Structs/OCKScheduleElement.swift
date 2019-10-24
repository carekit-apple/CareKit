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
public struct OCKScheduleElement: Codable, Equatable, OCKSchedulable, OCKLocalPersistableSettable, OCKObjectCompatible {
    public internal (set) var localDatabaseID: OCKLocalVersionID?

    /// An text about the time this element represents.
    /// e.g. before breakfast on Tuesdays, 5PM every day, etc.
    public var text: String?

    /// The amount of time that the event should take, in seconds.
    public var duration: TimeInterval

    /// If the event should be considered to fill the whole day that it occurs on.
    // Note: This must remain a constant because it changes how `start` is initialized.
    public let isAllDay: Bool

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

    // MARK: OCKObjectCompatible
    public internal(set) var createdDate: Date?
    public internal(set) var updatedDate: Date?
    public internal(set) var schemaVersion: OCKSemanticVersion?
    public var groupIdentifier: String?
    public var tags: [String]?
    public var versionID: OCKLocalVersionID?
    public var remoteID: String?
    public var source: String?
    public var userInfo: [String: String]?
    public var asset: String?
    public var notes: [OCKNote]?

    /// Create a `ScheduleElement` by specying the start date, end date, and interval.
    ///
    /// - Parameters:
    ///   - start: DateComponents specifying the exact day and time that the first occurence of this task happens.
    ///   - end: DateComponents specifying when the task ends. The end date is not inclusive.
    ///   - interval: DateComponents specifying the frequency at which the schedule repeats.
    ///   - text: A textual representation of this schedule element. Examples: "After breakfast", "08:00", "As needed throughout the day".
    ///   - targetValues: An array of values that represents goals for this schedule element.
    ///   - duration: A duration in seconds specifying how long the window to complete this event is.
    ///   - isAllDay: A boolean flag that specifies if this event is an all day task. False by default.
    public init(start: DateComponents, end: DateComponents?, interval: DateComponents,
                text: String? = nil, targetValues: [OCKOutcomeValue] = [],
                duration: TimeInterval = 0, isAllDay: Bool = false) {
        guard let startDate = Calendar.current.date(from: start) else { fatalError("Date components must resolve to a valid date!") }
        self.start = isAllDay ? Calendar.current.startOfDay(for: startDate): startDate
        self.end = end == nil ? nil : Calendar.current.date(from: end!)!
        self.interval = interval
        self.text = text
        self.duration = duration
        self.isAllDay = isAllDay
        self.targetValues = targetValues
    }

    /// Create a `ScheduleElement` by specying the start date, end date, and interval.
    ///
    /// - Parameters:
    ///   - start: Date specifying the exact day and time that the first occurence of this task happens.
    ///   - end: Date specifying when the task ends. The end date is not inclusive.
    ///   - interval: DateComponents specifying the frequency at which the schedule repeats.
    ///   - text: A textual representation of this schedule element. Examples: "After breakfast", "08:00", "As needed throughout the day".
    ///   - targetValues: An array of values that represents goals for this schedule element.
    ///   - duration: A duration in seconds specifying how long the window to complete this event is.
    ///   - isAllDay: A boolean flag that specifies if this event is an all day task. False by default.
    public init(start: Date, end: Date?, interval: DateComponents, text: String? = nil,
                targetValues: [OCKOutcomeValue] = [], duration: Double = 0, isAllDay: Bool = false) {
        assert(end == nil || start < end!, "Start date must be before the end date!")
        self.start = isAllDay ? Calendar.current.startOfDay(for: start) : start
        self.end = end
        self.interval = interval
        self.text = text
        self.duration = duration
        self.isAllDay = isAllDay
        self.targetValues = targetValues
    }

    /// Returns the Nth event of this schedule, or nil if the schedule ends before the Nth occurence.
    ///
    /// - Parameter occurence: The Nth occurence.
    public subscript(occurence: Int) -> OCKScheduleEvent? {
            guard let date = date(ofOccurence: occurence) else { return nil }
            return makeScheduleEvent(on: date, for: occurence)
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
    public func events(betweenOccurenceIndex startIndex: Int, and stopIndex: Int) -> [OCKScheduleEvent?] {
        assert(stopIndex > startIndex, "Stop index must be greater than or equal to start index")
        let numberOfEvents = stopIndex - startIndex
        var currentOccurence = 0
        var events = [OCKScheduleEvent?](repeating: nil, count: numberOfEvents)

        // Move to start index
        var currentDate = start
        for _ in 0..<startIndex {
            currentDate = Calendar.current.date(byAdding: interval, to: currentDate)!
            currentOccurence += 1
        }

        // Calculate the event at each index in between start and top indices
        for index in 0..<numberOfEvents {
            if let endDate = end, currentDate > endDate { continue }
            events[index] = makeScheduleEvent(on: currentDate, for: currentOccurence)
            currentDate = Calendar.current.date(byAdding: interval, to: currentDate)!
            currentOccurence += 1
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
            if isAllDay { return true }
            return event.start + duration >= start
        }
    }

    /// Computes the date of the Nth occurence of a schedule element. If the Nth occurence is beyond the end date, then nil will be returned.
    public func date(ofOccurence occurence: Int) -> Date? {
        assert(occurence >= 0, "Schedule events cannot have negative occurence indices")
        var currentDate = start
        for _ in 0..<occurence {
            guard let nextDate = Calendar.current.date(byAdding: interval, to: currentDate) else { fatalError("Invalid date!") }
            if let endDate = end, nextDate <= endDate { return nil }
            currentDate = nextDate
        }
        return currentDate
    }

    /// Determines the last date at which an event could possibly occur
    private func determineStopDate(onOrBefore date: Date) -> Date {
        guard let endDate = end else { return date }
        return min(endDate, date)
    }

    private func makeScheduleEvent(on date: Date, for occurence: Int) -> OCKScheduleEvent {
        let startDate = isAllDay ? Calendar.current.startOfDay(for: date) : date
        let endDate = isAllDay ?
            Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: startDate)! :
            startDate.addingTimeInterval(duration)
        return OCKScheduleEvent(start: startDate, end: endDate, element: self, occurence: occurence)
    }
}
