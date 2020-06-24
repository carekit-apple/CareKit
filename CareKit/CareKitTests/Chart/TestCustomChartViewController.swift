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
import CareKitStore
import CareKitUI
import Foundation
import XCTest

// Just testing access level
private class CustomCartesianChartViewSynchronizer: OCKCartesianChartViewSynchronizer {
    override func makeView() -> OCKCartesianChartView {
        return super.makeView()
    }

    override func updateView(_ view: OCKCartesianChartView, context: OCKSynchronizationContext<[OCKDataSeries]>) {
        super.updateView(view, context: context)
    }
}

private class CustomChartView: UILabel, OCKChartDisplayable {
    weak var delegate: OCKChartViewDelegate?
}

private class CustomChartViewSynchronizer: OCKChartViewSynchronizerProtocol {
    func makeView() -> CustomChartView {
        return .init()
    }

    func updateView(_ view: CustomChartView, context: OCKSynchronizationContext<[OCKDataSeries]>) {
        view.text = context.viewModel.first?.title
    }
}

class TestCustomChartViewSynchronizer: XCTestCase {

    private var viewSynchronizer: CustomChartViewSynchronizer!
    private var view: CustomChartView!

    override func setUp() {
        super.setUp()
        viewSynchronizer = .init()
        view = viewSynchronizer.makeView()
    }

    // View should be cleared in the initial state
    func testInitialStateIsEmpty() {
        XCTAssertNil(view.text)
    }

    // View should fill with contact data
    func testDoesUpdate() {
        let dataSeries = [OCKDataSeries.mock]
        viewSynchronizer.updateView(view, context: .init(viewModel: dataSeries, oldViewModel: [], animated: false))
        XCTAssertEqual(view.text, dataSeries.first?.title)
    }

    // View should be cleared after updating with a nil contact
    func testDoesClear() {
        let dataSeries = [OCKDataSeries.mock]
        viewSynchronizer.updateView(view, context: .init(viewModel: dataSeries, oldViewModel: [], animated: false))
        XCTAssertNotNil(view.text)

        // Update with a nil contact
        viewSynchronizer.updateView(view, context: .init(viewModel: [], oldViewModel: [], animated: false))
        XCTAssertNil(view.text)
    }
}

private extension OCKDataSeries {
    static var mock: OCKDataSeries {
        return OCKDataSeries(dataPoints: [], title: "")
    }
}
