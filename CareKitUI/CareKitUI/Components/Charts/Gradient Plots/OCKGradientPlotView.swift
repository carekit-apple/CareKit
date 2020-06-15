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

private let accessibilityElementBoundingBoxSize = CGSize(width: 10, height: 10)

/// This is an abstract base class for plots that use a gradient mask.
class OCKGradientPlotView<LayerType: OCKCartesianCoordinatesLayer> : UIView, OCKGradientPlotable, OCKMultiPlotable {
    
    let gradientLayer = CAGradientLayer()
    let pointsLayer = CAShapeLayer()

    func makePath(points: [CGPoint]) -> CGPath {
        return UIBezierPath().cgPath
    }

    var dataSeries: [OCKDataSeries] = [] {
        didSet { resetLayers() }
    }

    var xMinimum: CGFloat? {
        didSet { seriesLayers.forEach { $0.xMinimum = xMinimum } }
    }

    var xMaximum: CGFloat? {
        didSet { seriesLayers.forEach { $0.xMaximum = xMaximum } }
    }

    var yMinimum: CGFloat? {
        didSet { seriesLayers.forEach { $0.yMinimum = yMinimum } }
    }

    var yMaximum: CGFloat? {
        didSet { seriesLayers.forEach { $0.yMaximum = yMaximum } }
    }

    var seriesLayers: [LayerType] = []

    override func layoutSubviews() {
        super.layoutSubviews()
        seriesLayers.forEach { $0.frame = bounds }
        resetAccessibilityElements()
    }

    func resetLayers() {
        fatalError("This method must be overridden in subclasses!")
    }

    func resetAccessibilityElements() {
        accessibilityElements = []

        dataSeries.enumerated().forEach { seriesIndex, series in
            series.dataPoints.enumerated().forEach { pointIndex, point in

                let pointInViewSpace = seriesLayers[seriesIndex].convert(graphSpacePoints: [point]).first!
                let axOrigin = CGPoint(x: pointInViewSpace.x - accessibilityElementBoundingBoxSize.width / 2,
                                       y: pointInViewSpace.y - accessibilityElementBoundingBoxSize.height / 2)
                let axFrame = CGRect(origin: axOrigin, size: accessibilityElementBoundingBoxSize)

                // Create the labels for this data point
                let useProvidedLabel = pointIndex < series.accessibilityLabels.count
                let label = useProvidedLabel ? series.accessibilityLabels[pointIndex] : "\(series.title), \(point.x), \(point.y)"

                // Create an accessibility element for this singular data point
                let element = UIAccessibilityElement(accessibilityContainer: self)
                element.accessibilityFrameInContainerSpace = axFrame
                element.accessibilityLabel = label
                element.accessibilityTraits = UIAccessibilityTraits.staticText

                accessibilityElements?.append(element)
            }
        }
    }
}
