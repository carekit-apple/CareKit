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

/// An implementation of `OCKSchedulable` that can be created by composing together any number of other
/// `OCKSchedulable` objects, including other instance of `OCKSchedule`. This allows for the creation
/// of arbitrarily complex schedules.
///
/// - Note: A variety of initializers are provided to quickly create commonly used schedules. Used in
///         combination with the offset method, building up complex schedules can be performed quite
///         efficiently.
public struct OCKSchedule: Codable, Equatable, OCKSchedulable {
    /// The constituent components this schedule was built from.
    public let elements: [OCKScheduleElement]

    /// Create a new schedule by combining an array of other `OCKSchedule` objects.
    public init(composing schedules: [OCKSchedulable]) {
        assert(!schedules.isEmpty, "You cannot create a schedule with 0 elements")
        self.elements = schedules.flatMap { $0.elements }
    }

    /// Returns the Nth event of this schedule, or nil if the schedule ends before the Nth occurence.
    ///
    /// - Parameter occurence: The Nth occurence.
    public subscript(occurence: Int) -> OCKScheduleEvent? {
        return event(forOccurenceIndex: occurence)
    }

    /// The date of the first event of this schedule.
    ///
    /// - Note: This operation has an upperbound complexity of O(NlogN).
    public var start: Date {
        guard let earliestStartDate = elements.map({ $0.start }).sorted().min()
            else { fatalError("OCKSchedule should always have at least 1 element!") }
        return earliestStartDate
    }

    /// The date of the last event of this schedule, or nil if the schedule is of infinite length.
    ///
    /// - Note: This operation has an upperbound complexity of O(NlogN)
    public var end: Date? {
        let endDates = elements.map { $0.end }
        if endDates.contains(nil) { return nil }
        let finiteEndDates = endDates.compactMap({ $0 }).sorted()
        guard let lastEndDate = finiteEndDates.last else { fatalError("OCKSchedule should always have at least 1 element!") }
        return lastEndDate
    }

    public func events(from start: Date, to end: Date) -> [OCKScheduleEvent] {
        var allEvents = elements
            .flatMap { $0.events(from: self.start, to: end) }
            .sorted()
        for index in 0..<allEvents.count {
            allEvents[index] = allEvents[index].changing(occurenceIndex: index)
        }
        return allEvents.filter { $0.start + $0.element.duration >= start }
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
                                   text: String?, duration: TimeInterval = 3_600,
                                   targetValues: [OCKOutcomeValue] = []) -> OCKSchedule {
        let interval = DateComponents(day: 1)
        let startTime = Calendar.current.date(bySettingHour: hour, minute: minutes, second: 0, of: start)!
        let element = OCKScheduleElement(start: startTime, end: end, interval: interval,
                                         text: text, targetValues: targetValues, duration: duration)
        return OCKSchedule(composing: [element])
    }

    /// Create a schedule that happens once per week, every week, at a fixed time.
    public static func weeklyAtTime(weekday: Int, hours: Int, minutes: Int, start: Date, end: Date?, targetValues: [OCKOutcomeValue],
                                    text: String?, duration: TimeInterval = 0) -> OCKSchedule {
        let interval = DateComponents(weekOfYear: 1)
        var startTime = Calendar.current.date(bySettingHour: hours, minute: minutes, second: 0, of: start)!
        startTime = Calendar.current.date(bySetting: .weekday, value: weekday, of: startTime)!
        let element = OCKScheduleElement(start: startTime, end: end, interval: interval,
                                         text: text, targetValues: targetValues, duration: duration)
        return OCKSchedule(composing: [element])
    }

    /// Computes the date of the Nth occurence of a schedule element. If the Nth occurence is beyond the end date, then nil will be returned.
    public func event(forOccurenceIndex occurence: Int) -> OCKScheduleEvent? {
        // This could be optimized. It is not an efficient algorithm.
        assert(occurence >= 0, "Schedule events cannot have negative occurence indices")
        let events = elements.flatMap { $0.events(betweenOccurenceIndex: 0, and: occurence + 1) }
        let sortedEvents = events.sorted { eventA, eventB -> Bool in
            if let eventA = eventA, let eventB = eventB {
                return eventA < eventB
            } else {
                return eventA != nil && eventB == nil
            }
        }
        guard let localEvent = sortedEvents[occurence] else { return nil }
        let globalEvent = OCKScheduleEvent(start: localEvent.start, end: localEvent.end,
                                           element: localEvent.element, occurence: occurence)
        return globalEvent
    }
}
