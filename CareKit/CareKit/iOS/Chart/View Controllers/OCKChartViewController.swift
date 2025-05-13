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
#if canImport(MessageUI)

import CareKitStore
import CareKitUI
import MessageUI
import os.log
import UIKit

/// A view controller that displays a chart view and keeps it synchronized with a store.
open class OCKChartViewController<
    ViewSynchronizer: ViewSynchronizing
>: SynchronizedViewController<ViewSynchronizer>, OCKChartViewDelegate where
    ViewSynchronizer.View: OCKChartDisplayable,
    ViewSynchronizer.ViewModel == [OCKDataSeries]
{

    /// The view that is being synchronized against the store.
    @available(*, deprecated, renamed: "typedView")
    public var chartView: ViewSynchronizer.View {
        return typedView
    }

    @available(*, unavailable, renamed: "init(weekOfDate:configurations:store:viewSynchronizer:)")
    public init<Controller>(
        controller: Controller,
        viewSynchronizer: ViewSynchronizer
    ) {
        fatalError("Unavailable")
    }

    @available(*, unavailable, renamed: "init(weekOfDate:configurations:store:viewSynchronizer:)")
    public convenience init(
        viewSynchronizer: ViewSynchronizer,
        weekOfDate: Date,
        configurations: [OCKDataSeriesConfiguration],
        storeManager: OCKSynchronizedStoreManager
    ) {
        fatalError("Unavailable")
    }

    /// A view controller that displays a chart view and keeps it synchronized with a store.
    /// - Parameters:
    ///   - weekOfDate: A date in the week of the insights range to fetch.
    ///   - configurations: Specifies which data should be queried and how it should be displayed by the graph.
    ///   - store: Contains the task data that will be displayed.
    ///   - viewSynchronizer: Capable of creating and updating the view using the data series.
    public init(
        weekOfDate: Date,
        configurations: [OCKDataSeriesConfiguration],
        store: OCKAnyStoreProtocol,
        viewSynchronizer: ViewSynchronizer
    ) {
        // Convert the params to an event query
        let weekInterval = Calendar.current.dateIntervalOfWeek(for: weekOfDate)
        var query = OCKEventQuery(dateInterval: weekInterval)
        query.taskIDs = configurations.map(\.taskID)

        let progressSplitByTask = store.dailyProgressSplitByTask(
            query: query,
            dateInterval: weekInterval,
            computeProgress: { event in
                Self.computeProgress(for: event, configurations: configurations)
            }
        )

        // Convert the progress to data series recognized by the chart
        let dataSeries = progressSplitByTask.map { dailyProgressForAllTasks -> [OCKDataSeries] in

            // Iterating first through the configurations ensures the final data series order
            // matches the order of the configurations
            let dataSeries = configurations.map { configuration -> OCKDataSeries in

                let dailyProgress = dailyProgressForAllTasks
                    .first { $0.taskID == configuration.taskID }?
                    .progressPerDates

                let dataSeries = Self.dataSeries(
                    forDailyProgress: dailyProgress ?? [],
                    configuration: configuration
                )

                return dataSeries
            }

            return dataSeries
        }

        super.init(
            initialViewModel: [],
            viewModels: dataSeries,
            viewSynchronizer: viewSynchronizer
        )
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        typedView.delegate = self
    }

    private static func dataSeries(
        forDailyProgress dailyProgress: [TemporalProgress<LinearCareTaskProgress>],
        configuration: OCKDataSeriesConfiguration
    ) -> OCKDataSeries {

        let summedProgressValuesPerDay = dailyProgress.map { progressOnDay -> CGFloat in

            let summedProgressValue = progressOnDay.values
                .map { $0.value }
                .reduce(0, +)

            return summedProgressValue
        }

        var series = OCKDataSeries(
            values: summedProgressValuesPerDay,
            title: configuration.legendTitle,
            gradientStartColor: configuration.gradientStartColor,
            gradientEndColor: configuration.gradientEndColor,
            size: configuration.markerSize
        )

        let accessibilityLabels = zip(
            Calendar.current.orderedWeekdaySymbols(),
            summedProgressValuesPerDay
        )
        .map { "\(configuration.legendTitle), \($0), \($1)" }

        series.accessibilityLabels = accessibilityLabels

        return series
    }

    private static func computeProgress(
        for event: OCKAnyEvent,
        configurations: [OCKDataSeriesConfiguration]
    ) -> LinearCareTaskProgress {

        let computeProgress = configurations
            .first { $0.taskID == event.task.id }?
            .computeProgress

        guard let computeProgress else {
            return event.computeProgress(by: .summingOutcomeValues)
        }

        return computeProgress(event)

    }

    // MARK: - OCKChartViewDelegate

    open func didSelectChartView(_ chartView: UIView & OCKChartDisplayable) {}
}
#endif
