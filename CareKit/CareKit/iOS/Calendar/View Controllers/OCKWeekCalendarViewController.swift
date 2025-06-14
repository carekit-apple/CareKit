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
#if !os(watchOS)

import CareKitStore
import Foundation

/// A view controller that displays a weekly calendar view and synchronizes it with a store.
open class OCKWeekCalendarViewController: OCKCalendarViewController<OCKWeekCalendarViewSynchronizer> {

    @available(*, unavailable, renamed: "init(dateInterval:store:viewSynchronizer:computeProgress:)")
    public convenience init(
        controller: OCKWeekCalendarController,
        viewSynchronizer: OCKWeekCalendarViewSynchronizer
    ) {
        fatalError("Unavailable")
    }

    @available(*, unavailable, renamed: "init(dateInterval:store:viewSynchronizer:computeProgress:)")
    public convenience init(
        viewSynchronizer: OCKWeekCalendarViewSynchronizer,
        dateInterval: DateInterval,
        aggregator: OCKAdherenceAggregator,
        storeManager: OCKSynchronizedStoreManager
    ) {
        fatalError("Unavailable")
    }

    @available(*, unavailable, renamed: "init(dateInterval:store:computeProgress:)")
    public convenience init(
        weekOfDate date: Date,
        aggregator: OCKAdherenceAggregator,
        storeManager: OCKSynchronizedStoreManager
    ) {
        fatalError("Unavailable")
    }

    /// Initialize a view controller that displays adherence. Fetches and stays synchronized with the adherence data.
    /// - Parameters:
    ///   - date: A date in the week for which adherence will be fetched.
    ///   - store: Contains the task data for which adherence will be computed.
    ///   - computeProgress: Used to compute the progress for an event.
    public init(
        weekOfDate date: Date,
        store: OCKAnyStoreProtocol,
        computeProgress: @escaping (OCKAnyEvent) -> CareTaskProgress = { event in
            event.computeProgress(by: .checkingOutcomeExists)
        }
    ) {
        let weekInterval = Self.weekInterval(for: date)
        let viewSynchronizer = OCKWeekCalendarViewSynchronizer(weekOfDate: date)

        super.init(
            dateInterval: weekInterval,
            store: store,
            viewSynchronizer: viewSynchronizer,
            computeProgress: computeProgress
        )
    }

    /// Initialize a view controller that displays adherence. Fetches and stays synchronized with the adherence data.
    /// - Parameters:
    ///   - store: Wraps the store that contains the adherence data.
    ///   - viewSynchronizer: Capable of creating and updating the view using the data series.
    ///   - computeProgress: Used to compute the progress for an event.
    public init(
        store: OCKAnyStoreProtocol,
        viewSynchronizer: OCKWeekCalendarViewSynchronizer,
        computeProgress: @escaping (OCKAnyEvent) -> CareTaskProgress = { event in
            event.computeProgress(by: .checkingOutcomeExists)
        }
    ) {
        let weekInterval = Self.weekInterval(for: viewSynchronizer.date)

        super.init(
            dateInterval: weekInterval,
            store: store,
            viewSynchronizer: viewSynchronizer,
            computeProgress: computeProgress
        )
    }

    private static func weekInterval(for date: Date) -> DateInterval {
        var weekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: date)!
        weekInterval.duration -= 1  // Standard interval returns 1 second of the next week
        return weekInterval
    }
}

#endif
