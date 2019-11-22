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

/// Any view or layer that can be plotted on conforms to this protocol.
protocol OCKCartesianGridProtocol: AnyObject {
    /// The smallest value shown on the x-axis. If not set, a reasonable default will be used.
    var xMinimum: CGFloat? { get set }

    /// The largest value shown on the x-axis. If not set, a reasonable default will be used.
    var xMaximum: CGFloat? { get set }

    /// The smallest value shown on the y-axis. If not set, a reasonable default will be used.
    var yMinimum: CGFloat? { get set }

    /// The largest value shown on the y-axis. If not set, a reasonable default will be used.
    var yMaximum: CGFloat? { get set }
}

extension OCKCartesianGridProtocol {
    /// The default width of the graph in plot space coordinates.
    static var defaultWidth: CGFloat { return 100 }

    /// The default height of the graph area in plot space coordinates.
    static var defaultHeight: CGFloat { return 100 }
}

/// Any view that only supports plotting a single data series should conform to this protocol.
protocol OCKSinglePlotable: OCKCartesianGridProtocol {
    var dataPoints: [CGPoint] { get set }
}

/// Any view that supports plotting multiple data series should conform to this protocol.
protocol OCKMultiPlotable: OCKCartesianGridProtocol {
    var dataSeries: [OCKDataSeries] { get set }
}

extension OCKMultiPlotable {
    /// Computes the bounds of the area shown on the graph in graph coordinate space.
    func graphBounds() -> CGRect {
        let xCoords = dataSeries.flatMap { $0.dataPoints }.map { $0.x }
        let xMin = xMinimum ?? xCoords.min() ?? 0
        let xMax = xMaximum ?? xCoords.max() ?? Self.defaultWidth
        let width = xMax - xMin

        let yCoords = dataSeries.flatMap { $0.dataPoints }.map { $0.y }
        let yMin = yMinimum ?? yCoords.min() ?? 0
        let yMax = yMaximum ?? yCoords.max() ?? Self.defaultHeight
        let height = yMax - yMin

        return CGRect(x: xMin, y: yMin, width: width, height: height)
    }
}

protocol OCKGradientPlotable {
    var gradientLayer: CAGradientLayer { get }
    var pointsLayer: CAShapeLayer { get }

    func makePath(points: [CGPoint]) -> CGPath
}

extension OCKGradientPlotable where Self: CALayer {
    func drawPoints(_ points: [CGPoint]) {
        let path = makePath(points: points)
        pointsLayer.path = path

        // Adjust the gradient's frame to capture the entire shape. It should clip top and bottom, but not sides.
        let minX = min(0, path.boundingBoxOfPath.minX)
        let maxX = max(bounds.width, path.boundingBoxOfPath.maxX)
        let gradientFrame = CGRect(x: minX, y: 0, width: maxX - minX, height: bounds.height)

        gradientLayer.frame = gradientFrame

        // The points layer is positioned as a sublayer in the gradient, but it needs to appear
        // in the same position it would if the gradient layer were exactly the same size as its parent.
        let translation = CGAffineTransform(translationX: -gradientFrame.minX, y: 0)
        let adjustedFrame = bounds.applying(translation)
        pointsLayer.frame = adjustedFrame
    }
}
