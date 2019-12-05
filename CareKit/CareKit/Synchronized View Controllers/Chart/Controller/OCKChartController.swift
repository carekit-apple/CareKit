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
import CareKitUI
import Combine
import Foundation
import UIKit

/// A basic controller capable of updating charts.
open class OCKChartController: OCKChartControllerProtocol, ObservableObject {

    // MARK: OCKChartControllerProtocol
    public var store: OCKAnyEventStore { storeManager.store }
    public let objectWillChange: CurrentValueSubject<[OCKDataSeries], Never>

    /// The store manager against which the chart will be synchronized.
    public let storeManager: OCKSynchronizedStoreManager

    // MARK: Properties

    private let weekOfDate: Date
    private var subscription: AnyCancellable?

    // MARK: - Life Cycle

    /// Initialize the controller.
    /// - Parameter weekOfDate: A date in the week of the insights range.
    /// - Parameter storeManager: Wraps the store that contains the insight data.
    public required init(weekOfDate: Date, storeManager: OCKSynchronizedStoreManager) {
        self.weekOfDate = weekOfDate
        self.storeManager = storeManager
        self.objectWillChange = .init([])
    }

    // MARK: - Methods

    /// Begin observing an array of data series configurations.
    /// - Parameters:
    ///   - configurations: An array of configurations to be plotted.
    open func fetchAndObserveInsights(forConfigurations configurations: [OCKDataSeriesConfiguration],
                                      errorHandler: ((Error) -> Void)? = nil) {

        // Fetch tasks, then fetch events for the tasks and set the view model
        let eventQuery = OCKEventQuery(dateInterval: Calendar.current.dateIntervalOfWeek(for: weekOfDate))
        fetchTasks(eventQuery: eventQuery, configurations: configurations, errorHandler: errorHandler)
    }

    private func fetchTasks(eventQuery: OCKEventQuery, configurations: [OCKDataSeriesConfiguration],
                            errorHandler: ((Error) -> Void)? = nil) {

        // Build up the task query
        var taskQuery = OCKTaskQuery(for: Date())
        taskQuery.ids = configurations.map { $0.taskID }

        storeManager.store.fetchAnyTasks(query: taskQuery, callbackQueue: .main) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let tasks):

                // Fetch events and set the view model. Also set the view model when the events change
                self.refetchEvents(eventQuery: eventQuery, configurations: configurations) { result in
                    if case let .failure(error) = result {
                        errorHandler?(error)
                    }
                }

                self.subscribeTo(tasks: tasks, eventQuery: eventQuery, configurations: configurations) { result in
                    if case let .failure(error) = result {
                        errorHandler?(error)
                    }
                }

            case .failure(let error):
                errorHandler?(error)
            }
        }
    }

    private func refetchEvents(eventQuery: OCKEventQuery, configurations: [OCKDataSeriesConfiguration],
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
            self.objectWillChange.value = allDataSeries
            completion?(.success(allDataSeries))
        }
    }

    private func subscribeTo(tasks: [OCKAnyTask],
                             eventQuery: OCKEventQuery, configurations: [OCKDataSeriesConfiguration],
                             completion: OCKResultClosure<[OCKDataSeries]>?) {
        // Set the view model when the tasks change
        let taskSubscriptions = tasks.map { task in
            return storeManager.publisher(forTask: task, categories: [.update, .delete], fetchImmediately: false)
                .sink { _ in self.refetchEvents(eventQuery: eventQuery, configurations: configurations, completion: completion) }
        }

        // Set the view model when the events for the tasks change
        let eventSubscriptions = tasks.map { task in
            return self.storeManager.publisher(forEventsBelongingToTask: task, categories: [.update, .add, .delete])
                .sink { _ in self.refetchEvents(eventQuery: eventQuery, configurations: configurations, completion: completion) }
        }

        subscription = AnyCancellable {
            taskSubscriptions.forEach { $0.cancel() }
            eventSubscriptions.forEach { $0.cancel() }
        }
    }
}
