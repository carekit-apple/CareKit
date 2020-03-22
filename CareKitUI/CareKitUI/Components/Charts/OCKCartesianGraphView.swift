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

import UIKit

/// Displays a `OCKMultiGraphableView` above an axis. The initializer takes an enum `PlotType` that allows you to choose from
/// several common graph types.
///
///     +-------------------------------------------------------+
///     |                                                       |
///     | [title]                                               |
///     | [detail]                                              |
///     |                                                       |
///     | [graph]                                               |
///     |                                                       |
///     +-------------------------------------------------------+
///
open class OCKCartesianGraphView: OCKView, OCKMultiPlotable {

    /// An enumerator specifying the types of plots this view can display.
    public enum PlotType: String, CaseIterable {
        case line
        case scatter
        case bar
    }

    // MARK: Properties

    /// The data points displayed in the graph.
    public var dataSeries: [OCKDataSeries] {
        get { return plotView.dataSeries }
        set {
            updateScaling(for: newValue)
            plotView.dataSeries = newValue
            legend.setDataSeries(newValue)
        }
    }

    /// The labels for the horizontal axis.
    public var horizontalAxisMarkers: [String] = [] {
        didSet { axisView.axisMarkers = horizontalAxisMarkers }
    }

    /// Get the bounds of the graph.
    ///
    /// - Returns: The bounds of the graph.
    public func graphBounds() -> CGRect {
        return plotView.graphBounds()
    }

    /// The minimum x value in the graph.
    public var xMinimum: CGFloat? {
        get { return plotView.xMinimum }
        set {
            plotView.xMinimum = newValue
            gridView.xMinimum = newValue
        }
    }

    /// The maximum x value in the graph.
    public var xMaximum: CGFloat? {
        get { return plotView.xMaximum }
        set {
            plotView.xMaximum = newValue
            gridView.xMaximum = newValue
        }
    }

    /// The minimum y value in the graph.
    public var yMinimum: CGFloat? {
        get { return plotView.yMinimum }
        set {
            plotView.yMinimum = newValue
            gridView.yMinimum = newValue
        }
    }

    /// The maximum y value in the graph.
    public var yMaximum: CGFloat? {
        get { return plotView.yMaximum }
        set {
            plotView.yMaximum = newValue
            gridView.yMaximum = newValue
        }
    }

    /// The index of the selected label in the x-axis.
    public var selectedIndex: Int? {
        get { return axisView.selectedIndex }
        set { axisView.selectedIndex = newValue }
    }

    private let gridView: OCKGridView
    private let plotView: UIView & OCKMultiPlotable
    private let axisView: OCKGraphAxisView
    private let axisHeight: CGFloat = 44
    private let horizontalPlotPadding: CGFloat = 50
    private let legend = OCKGraphLegendView()

    // MARK: - Life Cycle

    /// Create a graph view with the specified style.
    ///
    /// - Parameter plotType: The style of the graph view.
    public init(type: PlotType) {
        self.gridView = OCKGridView()
        self.axisView = OCKGraphAxisView()
        self.plotView = {
            switch type {
            case .line: return OCKLinePlotView()
            case .scatter: return OCKScatterPlotView()
            case .bar: return OCKBarPlotView()
            }
        }()
        super.init()
        setup()
    }

    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods

    override open func tintColorDidChange() {
        super.tintColorDidChange()
        axisView.tintColor = tintColor
    }

    private func updateScaling(for dataSeries: [OCKDataSeries]) {
        let maxValue = max(CGFloat(gridView.numberOfDivisions), dataSeries.flatMap { $0.dataPoints }.map { $0.y }.max() ?? 0)
        let chartMax = ceil(maxValue / CGFloat(gridView.numberOfDivisions)) * CGFloat(gridView.numberOfDivisions)
        plotView.yMaximum = chartMax
        gridView.yMaximum = chartMax
    }

    override func setup() {
        super.setup()
        [gridView, plotView, axisView, legend].forEach { addSubview($0) }

        gridView.xMinimum = plotView.xMinimum
        gridView.xMaximum = plotView.xMaximum
        gridView.yMinimum = plotView.yMinimum
        gridView.yMaximum = plotView.yMaximum

        [gridView, plotView, axisView, legend].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            gridView.topAnchor.constraint(equalTo: plotView.topAnchor),
            gridView.leadingAnchor.constraint(equalTo: leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: plotView.bottomAnchor),
            plotView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: horizontalPlotPadding),
            plotView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -horizontalPlotPadding),
            plotView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            plotView.bottomAnchor.constraint(equalTo: axisView.topAnchor),
            axisView.leadingAnchor.constraint(equalTo: plotView.leadingAnchor),
            axisView.trailingAnchor.constraint(equalTo: plotView.trailingAnchor),
            axisView.heightAnchor.constraint(equalToConstant: axisHeight),
            axisView.bottomAnchor.constraint(equalTo: legend.topAnchor),
            legend.leadingAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.leadingAnchor),
            legend.trailingAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.trailingAnchor),
            legend.centerXAnchor.constraint(equalTo: centerXAnchor),
            legend.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}
