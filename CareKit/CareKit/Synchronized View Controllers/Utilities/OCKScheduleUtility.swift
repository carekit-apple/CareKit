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
import Foundation

struct OCKScheduleUtility {

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter
    }()

    static func scheduleLabel(for events: [OCKAnyEvent]) -> String? {
        let result = [completionLabel(for: events), dateLabel(for: events)]
            .compactMap { $0 }
            .joined(separator: " ")
        return !result.isEmpty ? result : nil
    }

    static func scheduleLabel(for event: OCKAnyEvent) -> String? {
        let result = [
            timeLabel(for: event),
            dateLabel(forStart: event.scheduleEvent.start, end: event.scheduleEvent.end)
        ]
            .compactMap { $0 }
            .joined(separator: " ")

        return !result.isEmpty ? result : nil
    }

    static func timeLabel(for event: OCKAnyEvent, includesEnd: Bool = true) -> String {
        switch event.scheduleEvent.element.duration {

        case .allDay: return "all day"
        case .seconds:
            if includesEnd && event.scheduleEvent.start != event.scheduleEvent.end {
                let start = event.scheduleEvent.start
                let end = event.scheduleEvent.end
                return "\(timeFormatter.string(from: start)) to \(timeFormatter.string(from: end))"
            }
        }
        let label = timeFormatter.string(from: event.scheduleEvent.start).description
        return label
    }

    static func completedTimeLabel(for event: OCKAnyEvent) -> String? {
        guard let completedDate = event.outcome?.values
            .max(by: { isMoreRecent(lhs: $0.createdDate, rhs: $1.createdDate) })?
            .createdDate
        else { return nil }
        return timeFormatter.string(from: completedDate)
    }

    private static func dateLabel(for events: [OCKAnyEvent]) -> String? {
        guard !events.isEmpty else { return nil }
        if events.count > 1 {
            let schedule = events.first!.scheduleEvent
            return dateLabel(forStart: schedule.start, end: schedule.end)
        }
        return dateLabel(forStart: events.first!.scheduleEvent.start, end: events.last!.scheduleEvent.end)
    }

    private static func isMoreRecent(lhs: Date?, rhs: Date?) -> Bool {
        guard let lhs = lhs else { return false }
        guard let rhs = rhs else { return true }
        return lhs > rhs
    }

    private static func dateLabel(forStart start: Date, end: Date) -> String? {
        let datesAreInSameDay = Calendar.current.isDate(start, inSameDayAs: end)
        if datesAreInSameDay {
            let datesAreToday = Calendar.current.isDateInToday(start)
            return !datesAreToday ? "on \(label(for: start))" : nil
        }
        return "from \(label(for: start)) to \(label(for: end))"
    }

    private static func label(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return loc("TODAY")
        }
        let label = dateFormatter.string(from: date)
        return label
    }

    private static func completionLabel(for events: [OCKAnyEvent]) -> String? {
        guard !events.isEmpty else { return nil }
        let completed = events.filter { $0.outcome != nil }.count
        let remaining = events.count - completed
        let format = OCKLocalization.localized("EVENTS_REMAINING",
                                               tableName: "Localizable",
                                               bundle: nil,
                                               value: "",
                                               comment: "The number of events that the user has not yet marked completed")
        return String.localizedStringWithFormat(format, remaining)
    }
}
