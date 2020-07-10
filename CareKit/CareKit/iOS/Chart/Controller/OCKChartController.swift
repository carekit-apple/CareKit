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
#if canImport(UIKit) && !os(watchOS)

import CareKitStore
import CareKitUI
import Combine
import Foundation
import UIKit

/// A basic controller capable of updating charts.
open class OCKChartController: ObservableObject {

    // MARK: Properties

    /// Multiple data series. Subscribe to the projected value to be notified when the data series changes.
    @Published public final var dataSeries: [OCKDataSeries] = []

    /// The error encountered by the controller.
    @Published public internal(set) var error: Error?

    /// The store manager against which the chart will be synchronized.
    public let storeManager: OCKSynchronizedStoreManager

    private let eventQuery: OCKEventQuery
    private var cancellables: Set<AnyCancellable> = Set()

    // MARK: - Life Cycle

    /// Initialize the controller.
    /// - Parameter weekOfDate: A date in the week of the insights range.
    /// - Parameter storeManager: Wraps the store that contains the insight data.
    public required init(weekOfDate: Date, storeManager: OCKSynchronizedStoreManager) {
        self.eventQuery = OCKEventQuery(dateInterval: Calendar.current.dateIntervalOfWeek(for: weekOfDate))
        self.storeManager = storeManager
    }

    // MARK: - Methods

    /// Begin observing an array of data series configurations.
    /// - Parameters:
    ///   - configurations: An array of configurations to be plotted.
    open func fetchAndObserveInsights(forConfigurations configurations: [OCKDataSeriesConfiguration]) {
        cancellables = Set()
        configurations.forEach { config in
            storeManager.store.fetchAnyEvents(taskID: config.taskID, query: eventQuery, callbackQueue: .main) { [weak self] result in

                switch result {
                case let .failure(error):
                    self?.error = error
                case let .success(events):
                    self?.refetchEvents(configurations: configurations, completion: nil)
                    events.forEach {
                        self?.subscribeTo(event: $0, configurations: configurations)
                    }
                }
            }
        }
    }

    private func refetchEvents(configurations: [OCKDataSeriesConfiguration],
                               completion: OCKResultClosure<[OCKDataSeries]>?) {
        var allDataSeries = [OCKDataSeries]()
        let group = DispatchGroup()

        // Aggregate events, then set the view model
        for config in configurations {
            let insightsQuery = OCKInsightQuery(taskID: config.taskID, dateInterval: eventQuery.dateInterval, aggregator: config.aggregator)
            group.enter()
            storeManager.store.fetchInsights(query: insightsQuery, callbackQueue: .main) { result in
                switch result {
                case .failure(let error):
                    completion?(.failure(error))
                    return
                case .success(let values):
                    var series = OCKDataSeries(values: values.map { CGFloat($0) }, title: config.legendTitle,
                                               gradientStartColor: config.gradientStartColor, gradientEndColor: config.gradientEndColor,
                                               size: config.markerSize)

                    let accessibilityLabels = zip(Calendar.current.orderedWeekdaySymbols(), values).map { "\(config.legendTitle), \($0), \($1)" }
                    series.accessibilityLabels = accessibilityLabels
                    allDataSeries.append(series)
                }
                group.leave()
            }
        }

        // Wait for the events to be aggregated, then set the view model
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.dataSeries = allDataSeries
            completion?(.success(allDataSeries))
        }
    }

    private func subscribeTo(event: OCKAnyEvent, configurations: [OCKDataSeriesConfiguration]) {
        storeManager
            .publisher(forEvent: event, categories: [.add, .update, .delete])
            .sink(receiveValue: { [weak self] _ in
                self?.refetchEvents(configurations: configurations) { [weak self] result in
                    if case let .failure(error) = result {
                        self?.error = error
                    }
                }
            })
            .store(in: &self.cancellables)
    }
}
#endif
