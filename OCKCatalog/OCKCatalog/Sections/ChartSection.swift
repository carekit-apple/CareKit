/*
 Copyright (c) 2020, Apple Inc. All rights reserved.

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
import SwiftUI

struct ChartSection: View {

    var body: some View {
        Section(header: Text("Chart")) {
            ForEach(OCKCartesianGraphView.PlotType.allCases, id: \.rawValue) { style in
                NavigationLink(style.rawValue.capitalized, destination: ChartDestination(style: style))
            }
        }
    }
}

private struct ChartDestination: View {

    @Environment(\.storeManager) private var storeManager

    let style: OCKCartesianGraphView.PlotType

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)
            AdaptedChartView(style: style, storeManager: storeManager)
        }
        .navigationBarTitle(Text(style.rawValue.capitalized), displayMode: .inline)
    }
}

private struct AdaptedChartView: UIViewControllerRepresentable {

    let style: OCKCartesianGraphView.PlotType
    let storeManager: OCKSynchronizedStoreManager

    func makeUIViewController(context: Context) -> UIViewController {
        let listViewController = OCKListViewController()

        let spacer = UIView(frame: .init(origin: .zero, size: .init(width: 0, height: 32)))
        listViewController.appendView(spacer, animated: false)

        let viewController = makeChartViewController()

        listViewController.appendViewController(viewController, animated: false)
        return listViewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    private func makeChartViewController() -> UIViewController {
        let gradientStart = UIColor { traitCollection -> UIColor in
            return traitCollection.userInterfaceStyle == .light ? #colorLiteral(red: 0.9960784314, green: 0.3725490196, blue: 0.368627451, alpha: 1) : #colorLiteral(red: 0.8627432641, green: 0.2630574384, blue: 0.2592858295, alpha: 1)
        }
        let gradientEnd = UIColor { traitCollection -> UIColor in
            return traitCollection.userInterfaceStyle == .light ? #colorLiteral(red: 0.9960784314, green: 0.4732026144, blue: 0.368627451, alpha: 1) : #colorLiteral(red: 0.8627432641, green: 0.3598620686, blue: 0.2592858295, alpha: 1)
        }

        let markerSize: CGFloat = style == .bar ? 10 : 2
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let configurations = [
            OCKDataSeriesConfiguration(
                taskID: OCKStore.Tasks.doxylamine.rawValue,
                legendTitle: OCKStore.Tasks.doxylamine.rawValue.capitalized,
                gradientStartColor: gradientStart,
                gradientEndColor: gradientEnd,
                markerSize: markerSize,
                eventAggregator: .countOutcomeValues)
        ]

        let chartViewController = OCKCartesianChartViewController(plotType: style, selectedDate: startOfDay,
                                                                  configurations: configurations, storeManager: storeManager)
        chartViewController.chartView.headerView.titleLabel.text = OCKStore.Tasks.doxylamine.rawValue.capitalized
        return chartViewController
    }

}
