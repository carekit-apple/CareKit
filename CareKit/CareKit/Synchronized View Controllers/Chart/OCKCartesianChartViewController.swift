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

import CareKitUI
import Foundation
import UIKit

/// A view controller that is synchronized with a data series. Shows an `OCKCartesianChartView` and handles user interactions automatically.
open class OCKCartesianChartViewController<Store: OCKStoreProtocol>: OCKChartViewController<OCKCartesianChartView, Store> {
    /// The type of the view being displayed.
    public typealias View = OCKCartesianChartView

    private let plotType: OCKCartesianGraphView.PlotType

    /// Initialize with a store manager and an array of data series configurations.
    /// - Parameters:
    ///   - storeManager: The store manager used to provide synchronization with the underlying store.
    ///   - type: The type of plot to be used, e.g., bar, line, or scatter.
    ///   - dataSeriesConfigurations: An array of objects that specify which data should be plotted.
    ///   - date: The date lying in the week that will be displayed in the chart.
    public init(storeManager: OCKSynchronizedStoreManager<Store>,
                type: OCKCartesianGraphView.PlotType,
                dataSeriesConfigurations: [OCKDataSeriesConfiguration<Store>],
                date: Date) {
        self.plotType = type
        super.init(storeManager: storeManager, dataSeriesConfigurations: dataSeriesConfigurations, date: date)
    }

    /// Create an instance of the view to be displayed.
    override open func makeView() -> OCKCartesianChartView {
        let chartView = OCKCartesianChartView(type: plotType)
        chartView.graphView.selectedIndex = Calendar.current.component(.weekday, from: date) - Calendar.current.firstWeekday
        chartView.graphView.horizontalAxisMarkers = Calendar.current.orderedWeekdays()
        return chartView
    }

    /// Update the view whenever the view model changes.
    /// - Parameter view: The view to update.
    /// - Parameter context: The data associated with the updated state.
    override open func updateView(_ view: OCKCartesianChartView, context: OCKSynchronizationContext<[OCKDataSeries]>) {
        view.graphView.dataSeries = context.viewModel ?? []
    }
}
