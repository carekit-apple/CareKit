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
#if !os(watchOS)

import CareKitStore
import CareKitUI
import MessageUI
import UIKit

/// A view controller that displays a calendar view and keep it synchronized with a store.
open class OCKCalendarViewController<
    ViewSynchronizer: ViewSynchronizing
>: SynchronizedViewController<ViewSynchronizer>, OCKCalendarViewDelegate where
    ViewSynchronizer.View: OCKCalendarDisplayable,
    ViewSynchronizer.ViewModel == [OCKCompletionState]
{

    /// The view that is being synchronized against the store.
    @available(*, deprecated, renamed: "typedView")
    public var calendarView: ViewSynchronizer.View {
        return typedView
    }

    @available(*, unavailable, renamed: "init(dateInterval:store:viewSynchronizer:computeProgress:)")
    public init<Controller>(
        controller: Controller,
        viewSynchronizer: ViewSynchronizer
    ) {
        fatalError("Unavailable")
    }

    @available(*, unavailable, renamed: "init(dateInterval:store:viewSynchronizer:computeProgress:)")
    public convenience init(
        viewSynchronizer: ViewSynchronizer,
        dateInterval: DateInterval,
        aggregator: OCKAdherenceAggregator,
        storeManager: OCKSynchronizedStoreManager
    ) {
        fatalError("Unavailable")
    }

    /// Initialize a view controller that displays adherence per date. Fetches and stays synchronized
    /// with the adherence data.
    /// - Parameters:
    ///   - dateInterval: A date interval for which adherence will be displayed.
    ///   - store: Contains the task data for which adherence will be computed.
    ///   - viewSynchronizer: Capable of creating and updating the view.
    ///   - computeProgress: Used to compute the progress for an event.
    public init(
        dateInterval: DateInterval,
        store: OCKAnyStoreProtocol,
        viewSynchronizer: ViewSynchronizer,
        computeProgress: @escaping (OCKAnyEvent) -> CareTaskProgress = { event in
            event.computeProgress(by: .checkingOutcomeExists)
        }
    ) {

        let progress = store
            .dailyProgress(
                dateInterval: dateInterval,
                computeProgress: computeProgress
            )
            .map(Self.completionStates)

        super.init(
            initialViewModel: [],
            viewModels: progress,
            viewSynchronizer: viewSynchronizer
        )
    }

    private static func completionStates(
        forDailyProgress dailyProgress: [TemporalProgress<CareTaskProgress>]
    ) -> [OCKCompletionState] {

        return dailyProgress.map { dayProgress in

            let aggregatedProgress = AggregatedCareTaskProgress(combining: dayProgress.values)
            return .progress(aggregatedProgress.fractionCompleted)
        }
    }

    // MARK: - OCKCalendarViewDelegate

    open func calendarView(_ calendarView: UIView & OCKCalendarDisplayable, didSelectDate date: Date, at index: Int, sender: Any?) {}
}

#endif
