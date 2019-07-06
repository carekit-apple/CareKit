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
import Combine
import UIKit
import CareKitUI
import CareKitStore

/// Conform to this protocol to receive callbacks when important events happen inside an `OCKCartesianChartViewController`
public protocol OCKCartesianChartViewControllerDelegate: class {
    func cartesianChartViewController<Store: OCKStoreProtocol>(
        _ cartesianChartViewController: OCKCartesianChartViewController<Store>,
        didFailWithError error: Error)
}

/// A synchronized view controller that displays a chart with one or more data series populated with outcomes from tasks.
open class OCKCartesianChartViewController<Store: OCKStoreProtocol>: UIViewController {
    
    /// A chart view containing a graph, a legend, and an axis.
    public let chartView: OCKCartesianChartView
    
    /// The store manager used to provide synchronization with the underlying store.
    public let storeManager: OCKSynchronizedStoreManager<Store>
    
    /// If set, the delegate will receive callbacks when important events occur.
    public weak var delegate: OCKCartesianChartViewControllerDelegate?
    
    private var subscription: AnyCancellable?
    
    /// The data series configurations determine which data will be displayed in the chart view.
    public var dataSeriesConfigurations: [DataSeriesConfiguration] {
        didSet { refetchEvents() }
    }
    
    /// The event query specifies the date range over which data will be queried and displayed.
    public var eventQuery: OCKEventQuery {
        didSet { refetchEvents() }
    }
    
    /// Initialize with a store manager and an array of data series configurations.
    ///
    /// - Parameters:
    ///   - storeManager: The store manager used to provide synchronization with the underlying store.
    ///   - dataSeriesConfigurations: An array of objects that specify which data should be plotted.
    public init(storeManager: OCKSynchronizedStoreManager<Store>, dataSeriesConfigurations: [DataSeriesConfiguration],
                date: Date, plotType: OCKCartesianGraphView.PlotType) {
        self.storeManager = storeManager
        self.dataSeriesConfigurations = dataSeriesConfigurations
        self.eventQuery = OCKEventQuery(dateInterval: Calendar.current.week(of: date))
        self.chartView = OCKCartesianChartView(type: plotType)
        self.chartView.graphView.selectedIndex = Calendar.current.component(.weekday, from: date) - 1
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func loadView() {
        view = chartView
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        chartView.graphView.horizontalAxisMarkers = ["S", "M", "T", "W", "T", "F", "S"]
        subscribe()
    }
    
    /// A configuration object that specifies which data should be queried and how it should be displayed by the graph.
    public struct DataSeriesConfiguration {
        
        /// A user-provided unique identifier for a task.
        public var taskIdentifier: String
        
        /// The title that will be used to represent this data series in the legend.
        public var legendTitle: String
        
        /// The first of two colors that will be used in the gradient when plotting the data.
        public var gradientStartColor: UIColor
        
        /// The second of two colors that will be used in the gradient when plotting the data.
        public var gradientEndColor: UIColor
        
        /// The marker size determines the size of the line, bar, or scatter plot elements. The precise behavior is different for each type of plot.
        /// - For line plots, it will be the width of the line.
        /// - For scatter plots, it will be the radius of the markers.
        /// - For bar plots, it will be the width of the bar.
        public var markerSize: CGFloat
        
        /// A closure that accepts as an argument a day's worth of events and returns a y-axis value for that day.
        public var aggregator: ([Store.Event]) -> Double
        
        /// Initialize a new `DataSeriesConfiguration`.
        ///
        /// - Parameters:
        ///   - taskIdentifier: A user-provided unique identifier for a task.
        ///   - legendTitle: The title that will be used to represent this data series in the legend.
        ///   - gradientStartColor: The first of two colors that will be used in the gradient when plotting the data.
        ///   - gradientEndColor: The second of two colors that will be used in the gradient when plotting the data.
        ///   - markerSize: The marker size determines the size of the line, bar, or scatter plot elements. The precise behavior varies by plot type.
        ///   - customAggregator: A closure that accepts as an argument a day's worth of events and returns a y-axis value for that day.
        public init(taskIdentifier: String, legendTitle: String, gradientStartColor: UIColor, gradientEndColor: UIColor,
                    markerSize: CGFloat, customAggregator: @escaping (_ events: [Store.Event]) -> Double) {
            self.taskIdentifier = taskIdentifier
            self.legendTitle = legendTitle
            self.gradientStartColor = gradientStartColor
            self.gradientEndColor = gradientEndColor
            self.markerSize = markerSize
            self.aggregator = customAggregator
        }
        
        /// Initialize a new `DataSeriesConfiguration`.
        ///
        /// - Parameters:
        ///   - taskIdentifier: A user-provided unique identifier for a task.
        ///   - legendTitle: The title that will be used to represent this data series in the legend.
        ///   - gradientStartColor: The first of two colors that will be used in the gradient when plotting the data.
        ///   - gradientEndColor: The second of two colors that will be used in the gradient when plotting the data.
        ///   - markerSize: The marker size determines the size of the line, bar, or scatter plot elements. The precise behavior varies by plot type.
        ///   - eventAggregator: A closure that accepts as an argument a day's worth of events and returns a y-axis value for that day.
        public init(taskIdentifier: String, legendTitle: String, gradientStartColor: UIColor, gradientEndColor: UIColor,
                    markerSize: CGFloat, eventAggregator: OCKEventAggregator<Store>) {
            self.taskIdentifier = taskIdentifier
            self.legendTitle = legendTitle
            self.gradientStartColor = gradientStartColor
            self.gradientEndColor = gradientEndColor
            self.markerSize = markerSize
            self.aggregator = eventAggregator.aggregator
        }
    }
    
    private func subscribe() {
        let taskQuery = OCKTaskQuery(for: eventQuery.end)
        storeManager.store.fetchTasks(.taskIdentifiers(dataSeriesConfigurations.map { $0.taskIdentifier }),
                                      query: taskQuery, queue: .main) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                self.delegate?.cartesianChartViewController(self, didFailWithError: error)
            case .success(let tasks):
                self.refetchEvents()
                let taskSubscriptions = tasks.map { task in
                    return self.storeManager.publisher(forTask: task, categories: [.add, .update, .delete],
                                                       fetchImmediately: false).sink { _ in
                        self.refetchEvents()
                    }
                }
                let eventSubscriptions = tasks.map { task in
                    return self.storeManager.publisher(forEventsBelongingToTask: task,
                                                       categories: [.add, .update, .delete]).sink { _ in
                        self.refetchEvents()
                    }
                }
                self.subscription = AnyCancellable {
                    taskSubscriptions.forEach { $0.cancel() }
                    eventSubscriptions.forEach { $0.cancel() }
                }
            }
        }
    }
    
    private func refetchEvents() {
        var allDataSeries = [OCKDataSeries]()
        var errors = [Error]()
        let group = DispatchGroup()
        let insightsQuery = OCKInsightQuery(from: eventQuery)
        for config in dataSeriesConfigurations {
            group.enter()
            storeManager.store.fetchInsights(forTask: config.taskIdentifier, query: insightsQuery, dailyAggregator: config.aggregator) { result in
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
            self.chartView.graphView.dataSeries = allDataSeries
            errors.forEach { self.delegate?.cartesianChartViewController(self, didFailWithError: $0) }
        }
    }
}

private extension Calendar {
    func week(of date: Date) -> DateInterval {
        let morning = startOfDay(for: date)
        let year = component(.year, from: morning)
        let weekNumber = component(.weekOfYear, from: morning)
        let firstDayOfWeek = self.date(from: DateComponents(year: year, weekday: 1, weekOfYear: weekNumber))!
        let firstDayOfNextWeek = self.date(byAdding: .weekOfYear, value: 1, to: firstDayOfWeek)!
        let lastMomentOfWeek = self.date(byAdding: .second, value: -1, to: firstDayOfNextWeek)!
        return DateInterval(start: firstDayOfWeek, end: lastMomentOfWeek)
    }
}
