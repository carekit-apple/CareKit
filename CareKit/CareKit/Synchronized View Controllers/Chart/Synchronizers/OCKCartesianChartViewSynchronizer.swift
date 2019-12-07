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
import Foundation

/// A chart view controller capable of displaying charts drawn on a Cartesian coordinate system.
open class OCKCartesianChartViewSynchronizer: OCKChartViewSynchronizerProtocol {

    /// The type of the plot that this view controller displays.
    public let plotType: OCKCartesianGraphView.PlotType

    /// The currently selected date.
    public let selectedDate: Date

    /// Initialize by providing a chart type and date.
    public required init(plotType: OCKCartesianGraphView.PlotType, selectedDate: Date) {
        self.plotType = plotType
        self.selectedDate = selectedDate
    }

    open func updateView(_ view: OCKCartesianChartView, context: OCKSynchronizationContext<[OCKDataSeries]>) {
        view.updateWith(dataSeries: context.viewModel, animated: context.animated)
    }

    open func makeView() -> OCKCartesianChartView {
        let chartView = OCKCartesianChartView(type: plotType)
        let currentWeekday = Calendar.current.component(.weekday, from: selectedDate)
        let firstWeekday = Calendar.current.firstWeekday
        var offset = (currentWeekday - 1) - (firstWeekday - 1)
        if offset < 0 {
            offset += 7
        }
        chartView.graphView.selectedIndex = offset
        chartView.graphView.horizontalAxisMarkers = Calendar.current.orderedWeekdaySymbolsVeryShort()
        return chartView
    }
}
