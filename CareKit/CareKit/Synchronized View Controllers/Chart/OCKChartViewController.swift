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

/// An abstract superclass to all synchronized view controllers that display a chart with one or more data series populated with outcomes from
/// tasks. Actions in the view sent through the `OCKContactViewDelegate` protocol will be automatically hooked up to controller logic.
///
/// Alternatively, subclass and use your custom view by specializing the `View` generic and overriding the `makeView()` method. Override the
/// `updateView(view:context)` method to hook up the contact to the view. This method will be called any time the contact is added, updated, or
/// deleted.
open class OCKChartViewController<View: UIView & OCKChartDisplayable, Store: OCKStoreProtocol>:
OCKSynchronizedViewController<View, [OCKDataSeries]>, OCKChartDisplayer {
    // MARK: Properties

    /// A chart view containing a graph, a legend, and an axis.
    public var chartView: UIView & OCKChartDisplayable { return synchronizedView }

    /// The store manager used to provide synchronization with the underlying store.
    public let storeManager: OCKSynchronizedStoreManager<Store>

    /// If set, the delegate will receive callbacks when important events occur.
    public weak var delegate: OCKChartViewControllerDelegate?

    /// The data series configurations determine which data will be displayed in the chart view.
    public var dataSeriesConfigurations: [OCKDataSeriesConfiguration<Store>]

    /// The event query specifies the date range over which data will be queried and displayed.
    public var eventQuery: OCKEventQuery {
        didSet { refetchEvents() }
    }

    /// The tasks that have events that will be shown in the chart
    private var tasks: [Store.Task] = []

    /// The date used to select the week to show in the chart
    let date: Date

    // MARK: Life Cycle

    /// Initialize with a store manager and an array of data series configurations.
    /// - Parameters:
    ///   - storeManager: The store manager used to provide synchronization with the underlying store.
    ///   - dataSeriesConfigurations: An array of objects that specify which data should be plotted.
    ///   - date: The date lying in the week that will be displayed in the chart.
    init(storeManager: OCKSynchronizedStoreManager<Store>, dataSeriesConfigurations: [OCKDataSeriesConfiguration<Store>], date: Date) {
        self.storeManager = storeManager
        self.date = date
        self.dataSeriesConfigurations = dataSeriesConfigurations
        self.eventQuery = OCKEventQuery(dateInterval: Calendar.current.dateIntervalOfWeek(for: date))
        super.init()
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        fetchTasks()
    }

    // MARK: Methods

    private func fetchTasks() {
        let taskQuery = OCKTaskQuery(for: eventQuery.end)
        storeManager.store.fetchTasks(.taskIdentifiers(dataSeriesConfigurations.map { $0.taskIdentifier }),
                                      query: taskQuery, queue: .main) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                self.delegate?.chartViewController(self, didFailWithError: error)
            case .success(let tasks):
                self.tasks = tasks
                self.refetchEvents()
                self.subscribe()
            }
        }
    }

    /// Create a subscription that listens to update and delete notifications for the tasks associated with the data series, and update, delete, and
    /// add notifications for the events related to the tasks.
    override open func makeSubscription() -> AnyCancellable? {
        let taskSubscriptions = tasks.map { task in
            return self.storeManager.publisher(forTask: task, categories: [.update, .delete], fetchImmediately: false)
                .sink { _ in self.refetchEvents() }
        }
        let eventSubscriptions = tasks.map { task in
            return self.storeManager.publisher(forEventsBelongingToTask: task, categories: [.update, .add, .delete])
                .sink { _ in self.refetchEvents() }
        }
        return AnyCancellable {
            taskSubscriptions.forEach { $0.cancel() }
            eventSubscriptions.forEach { $0.cancel() }
        }
    }

    private func refetchEvents() {
        var allDataSeries = [OCKDataSeries]()
        var errors = [Error]()
        let group = DispatchGroup()

        for config in dataSeriesConfigurations {
            var insightsQuery = OCKInsightQuery<Store.Event>(from: eventQuery)
            insightsQuery.aggregator = config.aggregator
            group.enter()
            storeManager.store.fetchInsights(forTask: config.taskIdentifier, query: insightsQuery) { result in
                switch result {
                case .failure(let error): errors.append(error)
                case .success(let values):
                    allDataSeries.append(OCKDataSeries(values: values.map { CGFloat($0) }, title: config.legendTitle,
                                                       gradientStartColor: config.gradientStartColor,
                                                       gradientEndColor: config.gradientEndColor,
                                                       size: config.markerSize))
                }
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.setViewModel(allDataSeries, animated: true)
            errors.forEach { self.delegate?.chartViewController(self, didFailWithError: $0) }
        }
    }
}
