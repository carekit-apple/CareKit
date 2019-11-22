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

/// Base class that provides graph coordinates for use in plotting numeric data.
class OCKCartesianCoordinatesLayer: CALayer, OCKSinglePlotable {
    static var defaultWidth: CGFloat { return 10.0 }
    static var defaultHeight: CGFloat { return 10.0 }

    /// Data points for the graph.
    var dataPoints: [CGPoint] = [] {
        didSet {
            orderedDataPoints = dataPoints.sorted { $0.x < $1.x }
            let oldPoints = points
            points = convert(graphSpacePoints: orderedDataPoints)
            setNeedsLayout()

            // Don't animate if the data sets don't match. Prevents weird scaling animation the very first time data is set.
            if oldPoints.count == points.count {
                animateInGraphCoordinates(from: oldPoints, to: points)
            }
        }
    }

    func animateInGraphCoordinates(from oldPoints: [CGPoint], to newPoints: [CGPoint]) {}

    func setPlotBounds(rect: CGRect) {
        xMinimum = rect.minX
        xMaximum = rect.maxX
        yMinimum = rect.minY
        yMaximum = rect.maxY
    }

    /// Minimum x value dislpayed in the graph.
    var xMinimum: CGFloat? {
        didSet { setNeedsLayout() }
    }

    /// Maximum x value displayed in the graph.
    var xMaximum: CGFloat? {
        didSet { setNeedsLayout() }
    }

    /// Minimum y values displayed in the graph.
    var yMinimum: CGFloat? {
        didSet { setNeedsLayout() }
    }

    /// Maximum y value displayed in the graph.
    var yMaximum: CGFloat? {
        didSet { setNeedsLayout() }
    }

    /// Default width of the graph.
    var defaultWidth: CGFloat {
        return 100
    }

    /// Default height of the graph.
    var defaultHeight: CGFloat {
        return 100
    }

    private (set) var points: [CGPoint] = []
    private (set) var orderedDataPoints: [CGPoint] = []

    /// Create an instance if a graoh layer.
    override init() {
        super.init()
        setNeedsLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setNeedsLayout()
    }

    override init(layer: Any) {
        super.init(layer: layer)
        setNeedsLayout()
    }

    override func layoutSublayers() {
        super.layoutSublayers()
        points = convert(graphSpacePoints: orderedDataPoints)
    }

    /// Get the rectangle that will be displayed in graph space.
    ///
    /// - Returns: The rectangle in graph space.
    func graphBounds() -> CGRect {
        let xCoords = dataPoints.map { $0.x }
        let xMin = xMinimum ?? xCoords.min() ?? 0
        let xMax = xMaximum ?? xCoords.max() ?? defaultWidth
        let width = xMax - xMin

        let yCoords = dataPoints.map { $0.y }
        let yMin = yMinimum ?? yCoords.min() ?? 0
        let yMax = yMaximum ?? yCoords.max() ?? defaultHeight
        let height = yMax - yMin

        return CGRect(x: xMin, y: yMin, width: width, height: height)
    }

    /// Convert a CGPoint to graph coordinates.
    ///
    /// - Parameter point: The point in screen space.
    /// - Returns: The point in graph space.
    func graphCoordinates(at point: CGPoint) -> CGPoint {
        return convert(viewSpacePoints: [point]).first!
    }

    /// Distance is calculated only in the horizontal direction

    /// Get the closest graph coordinates for a given view coordinate.
    ///
    /// - Parameter location: The coordinate in screen space.
    /// - Returns: The closest coordinate in graph space, and the correspoing screen coordinate.
    func closestDataPoint(toViewCoordinates location: CGPoint) -> (viewCoordinates: CGPoint, graphCoordinates: CGPoint)? {
        guard !orderedDataPoints.isEmpty else { return nil }
        let graphCoords = graphCoordinates(at: location)
        let distances = orderedDataPoints.map { point -> CGFloat in
            let dx = graphCoords.x - point.x
            let distance = sqrt(pow(dx, 2))
            return distance
        }
        let minDistance = distances.min()!
        let indexOfMin = distances.firstIndex(of: minDistance)!
        let closestViewCoords = points[indexOfMin]
        let closestGraphCoords = orderedDataPoints[indexOfMin]
        return (closestViewCoords, closestGraphCoords)
    }

    private struct Bounds {
        let lower: CGFloat
        let upper: CGFloat
    }

    /// Converts points from graph space to view space
    func convert(graphSpacePoints points: [CGPoint]) -> [CGPoint] {
        let graphRect = graphBounds()
        let viewRect = bounds

        let graphXBounds = Bounds(lower: graphRect.minX, upper: graphRect.maxX)
        let viewXBounds = Bounds(lower: viewRect.minX, upper: viewRect.maxX)
        let xMapper = make2DMapper(from: graphXBounds, to: viewXBounds)

        let graphYBounds = Bounds(lower: graphRect.minY, upper: graphRect.maxY)
        let viewYBounds = Bounds(lower: viewRect.minY, upper: viewRect.maxY)
        let yMapper = make2DMapper(from: graphYBounds, to: viewYBounds)

        return points.map { CGPoint(x: xMapper($0.x), y: viewRect.height - yMapper($0.y)) }
    }

    /// Converts points from view space to graph space
    private func convert(viewSpacePoints points: [CGPoint]) -> [CGPoint] {
        let graphRect = graphBounds()
        let viewRect = bounds

        let graphXBounds = Bounds(lower: graphRect.minX, upper: graphRect.maxX)
        let viewXBounds = Bounds(lower: viewRect.minX, upper: viewRect.maxX)
        let xMapper = make2DMapper(from: viewXBounds, to: graphXBounds)

        let graphYBounds = Bounds(lower: graphRect.minY, upper: graphRect.maxY)
        let viewYBounds = Bounds(lower: viewRect.maxY, upper: viewRect.minY)
        let yMapper = make2DMapper(from: viewYBounds, to: graphYBounds)

        return points.map { CGPoint(x: xMapper($0.x), y: yMapper($0.y)) }
    }

    /// Creates a method that linearly interpolate between two sets of bounds
    private func make2DMapper(from start: Bounds, to end: Bounds) -> ((CGFloat) -> CGFloat) {
        let rise = end.upper - end.lower
        let run = start.upper - start.lower
        let slope = rise / run
        let intercept = end.lower - start.lower * slope
        return { slope * $0 + intercept }
    }
}
