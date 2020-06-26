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

import CareKit
import CareKitUI
import Foundation
import XCTest

class TestCartesianChartViewSynchronizer: XCTestCase {

    var viewSynchronizer: OCKCartesianChartViewSynchronizer!
    var view: OCKCartesianChartView!
    let firstDayOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())!.start

    override func setUp() {
        super.setUp()
        viewSynchronizer = .init(plotType: .bar, selectedDate: firstDayOfWeek)
        view = viewSynchronizer.makeView()
    }

    func testSelectedIndex() {
        for offset in 0..<7 {
            let date = Calendar.current.date(byAdding: DateComponents(day: offset), to: firstDayOfWeek)!
            let viewSynchronizer = OCKCartesianChartViewSynchronizer(plotType: .bar, selectedDate: date)
            let view = viewSynchronizer.makeView()
            XCTAssertEqual(view.graphView.selectedIndex, offset)
        }
    }

    // View should be cleared in the initial state
    func testInitialStateIsEmpty() {
        XCTAssertEqual(view.graphView.selectedIndex, 0)
        XCTAssertTrue(view.graphView.dataSeries.isEmpty)
    }

    // View should fill with data
    func testDoesUpdate() {
        let dataSeries = [OCKDataSeries.mock]
        viewSynchronizer.updateView(view, context: .init(viewModel: dataSeries, oldViewModel: [], animated: false))
        XCTAssertEqual(view.graphView.dataSeries, dataSeries)
    }

    // View should be cleared after updating with no data
    func testDoesClear() {
        let dataSeries = [OCKDataSeries.mock]
        viewSynchronizer.updateView(view, context: .init(viewModel: dataSeries, oldViewModel: [], animated: false))
        XCTAssertFalse(view.graphView.dataSeries.isEmpty)

        // Update with no data
        viewSynchronizer.updateView(view, context: .init(viewModel: [], oldViewModel: [], animated: false))
        XCTAssertTrue(view.graphView.dataSeries.isEmpty)
    }
}

private extension OCKDataSeries {
    static var mock: OCKDataSeries {
        return OCKDataSeries(dataPoints: [], title: "")
    }
}
