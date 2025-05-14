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

import CareKitStore
import Foundation
import UIKit

extension OCKAnyReadOnlyEventStore {

    /// Computes ordered aggregated daily progress for each day in the provided interval.
    /// Days with no events will have a nil progress value.
    /// - Parameters:
    ///   - dateInterval: Progress will be computed for each day in the interval.
    ///   - computeProgress: Used to compute progress for an event.
    func dailyProgress<Progress>(
        dateInterval: DateInterval,
        computeProgress: @escaping (OCKAnyEvent) -> Progress
    ) -> AsyncMapSequence<CareStoreQueryResults<OCKAnyEvent>, [TemporalProgress<Progress>]> {

        let query = OCKEventQuery(dateInterval: dateInterval)
        let events = anyEvents(matching: query)

        let progress = events.map { events in

            Self.dailyProgress(
                for: events,
                dateInterval: dateInterval,
                computeProgress: computeProgress
            )
        }

        return progress
    }

    /// Computes ordered daily progress for each day in the provided interval. The progress for each day will be split by task.
    /// Days with no events will have a nil progress value.
    /// - Parameters:
    ///   - query: Used to fetch the event data.
    ///   - dateInterval: Progress will be computed for each day in the interval.
    ///   - computeProgress: Used to compute progress for an event.
    func dailyProgressSplitByTask<Progress>(
        query: OCKEventQuery,
        dateInterval: DateInterval,
        computeProgress: @escaping (OCKAnyEvent) -> Progress
    ) -> AsyncMapSequence<CareStoreQueryResults<OCKAnyEvent>, [TemporalTaskProgress<Progress>]> {

        let events = anyEvents(matching: query)

        let progress = events.map { events -> [TemporalTaskProgress] in

            // Group the events by task
            let eventsGroupedByTask = Dictionary(
                grouping: events,
                by: { $0.task.id }
            )

            // Compute the progress for each task
            let progress = eventsGroupedByTask.map { taskID, events -> TemporalTaskProgress<Progress> in

                let progressPerDays = Self.dailyProgress(
                    for: events,
                    dateInterval: dateInterval,
                    computeProgress: computeProgress
                )

                return TemporalTaskProgress(taskID: taskID, progressPerDates: progressPerDays)
            }

            return progress
        }

        return progress
    }

    private static func dailyProgress<Progress>(
        for events: [OCKAnyEvent],
        dateInterval: DateInterval,
        computeProgress: @escaping (OCKAnyEvent) -> Progress
    ) -> [TemporalProgress<Progress>] {

        let calendar = Calendar.current

        // Create a dictionary that has a key for each day in the provided interval.

        var daysInInterval: [DateComponents] = []
        var currentDate = dateInterval.start

        while currentDate < dateInterval.end {
            let day = uniqueDayComponents(for: currentDate)
            daysInInterval.append(day)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        // Group the events by the day they started

        let eventsGroupedByDay = Dictionary(
            grouping: events,
            by: { uniqueDayComponents(for: $0.scheduleEvent.start) }
        )

        // Iterate through the events on each day and update the stored progress values
        let progressPerDay = daysInInterval.map { day -> TemporalProgress<Progress> in

            let events = eventsGroupedByDay[day] ?? []

            let progressForEvents = events.map { event in
                computeProgress(event)
            }

            let dateOfDay = calendar.date(from: day)!

            let temporalProgress = TemporalProgress(
                values: progressForEvents,
                date: dateOfDay
            )

            return temporalProgress
        }

        return progressPerDay
    }

    private static func uniqueDayComponents(for date: Date) -> DateComponents {
        return Calendar.current.dateComponents(
            [.year, .month, .day],
            from: date
        )
    }
}
