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
#if !os(watchOS) && !os(macOS) && !os(visionOS)

import CareKitStore
import CareKitUI
import Foundation

open class OCKCartesianChartViewController: OCKChartViewController<OCKCartesianChartViewSynchronizer> {

    @available(*, unavailable, renamed: "init(weekOfDate:configurations:store:viewSynchronizer:)")
    public init(
        controller: OCKCartesianChartController,
        viewSynchronizer: OCKCartesianChartViewSynchronizer
    ) {
        fatalError("Unavailable")
    }

    @available(*, unavailable, renamed: "init(plotType:selectedDate:configurations:store:)")
    public convenience init(
        viewSynchronizer: OCKCartesianChartViewSynchronizer,
        weekOfDate: Date,
        configurations: [OCKDataSeriesConfiguration],
        storeManager: OCKSynchronizedStoreManager
    ) {
        fatalError("Unavailable")
    }

    @available(*, unavailable, renamed: "init(plotType:selectedDate:configurations:store:)")
    public convenience init(
        plotType: OCKCartesianGraphView.PlotType,
        selectedDate: Date,
        configurations: [OCKDataSeriesConfiguration],
        storeManager: OCKSynchronizedStoreManager
    ) {
        fatalError("Unavailable")
    }

    /// A view controller that displays a chart view and keep it synchronized with a store.
    /// - Parameters:
    ///   - weekOfDate: A date in the week of the insights range to fetch.
    ///   - configurations: Specifies which data should be queried and how it should be displayed by the graph.
    ///   - store: Contains the task data that will be displayed.
    ///   - viewSynchronizer: Capable of creating and updating the view using the data series.
    override public init(
        weekOfDate: Date,
        configurations: [OCKDataSeriesConfiguration],
        store: OCKAnyStoreProtocol,
        viewSynchronizer: OCKCartesianChartViewSynchronizer
    ) {
        super.init(
            weekOfDate: weekOfDate,
            configurations: configurations,
            store: store,
            viewSynchronizer: viewSynchronizer
        )
    }

    /// A view controller that displays a chart view and keep it synchronized with a store.
    /// - Parameters:
    ///   - plotType: The type of plot that is displayed in the view.
    ///   - selectedDate: The currently selected date in the chart.
    ///   - configurations: Specifies which data should be queried and how it should be displayed by the graph.
    ///   - store: Contains the task data that will be displayed.
    public init(
        plotType: OCKCartesianGraphView.PlotType,
        selectedDate: Date,
        configurations: [OCKDataSeriesConfiguration],
        store: OCKAnyStoreProtocol
    ) {
        super.init(
            weekOfDate: selectedDate,
            configurations: configurations,
            store: store,
            viewSynchronizer: OCKCartesianChartViewSynchronizer(plotType: plotType, selectedDate: selectedDate)
        )
    }
}

#endif
