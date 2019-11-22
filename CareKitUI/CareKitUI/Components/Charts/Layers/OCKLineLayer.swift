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

/// This layer displays a single line graph. Multiple line graph layers can be stacked to
/// generate plots with more than one data series.
class OCKLineLayer: OCKCartesianCoordinatesLayer {
    var startColor: UIColor = OCKStyle().color.customGray {
        didSet { gradient.colors = [startColor.cgColor, endColor.cgColor] }
    }

    var endColor: UIColor = OCKStyle().color.customGray {
        didSet { gradient.colors = [startColor.cgColor, endColor.cgColor] }
    }

    var outlineColor: UIColor? = nil {
        didSet { outline.strokeColor = outlineColor?.cgColor }
    }

    var lineWidth: CGFloat = 4 {
        didSet { line.lineWidth = lineWidth }
    }

    var offset: CGSize = .zero {
        didSet { setNeedsLayout() }
    }

    let gradient = CAGradientLayer()
    let line = CAShapeLayer()

    /// The layer for the ooutline around the line connecting the data points.
    let outline = CAShapeLayer()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSublayers()
    }

    override init() {
        super.init()
        setupSublayers()
    }

    override init(layer: Any) {
        super.init(layer: layer)
        setupSublayers()
    }

    override func layoutSublayers() {
        super.layoutSublayers()
        drawLine()
    }

    override func animateInGraphCoordinates(from oldPoints: [CGPoint], to newPoints: [CGPoint]) {
        animateLine(from: oldPoints, to: newPoints)
        animateOutline(from: oldPoints, to: newPoints)
    }

    private func setupSublayers() {
        addSublayer(outline)
        addSublayer(gradient)
    }

    private func drawLine() {
        // The gradient must be made wider so that the line doesn't get clipped if at the edge
        let offset = lineWidth * 2
        gradient.frame = CGRect(x: -offset, y: 0, width: bounds.width + 2 * offset, height: bounds.height)
        gradient.mask = line
        gradient.startPoint = CGPoint(x: 0.5, y: 1)
        gradient.endPoint = CGPoint(x: 0.5, y: 0)
        gradient.colors = [startColor.cgColor, endColor.cgColor]

        // The line is a sublayer of the gradient, so it needs to be shifted right as far as the gradient is
        // shifted to the left so that it lines up properly with the outline layer, which is not a sublayer
        // of the gradient layer.
        line.path = linePath(for: points)
        line.lineWidth = lineWidth
        line.lineCap = .round
        line.lineJoin = .round
        line.strokeColor = OCKStyle().color.customGray.cgColor
        line.fillColor = nil
        line.frame = bounds.applying(CGAffineTransform(translationX: offset, y: 0))

        outline.path = linePath(for: points)
        outline.lineWidth = lineWidth + 2
        outline.lineCap = .round
        outline.lineJoin = .round
        outline.strokeColor = outlineColor?.cgColor
        outline.fillColor = nil
        outline.frame = bounds
    }

    /// Points should be given in view coordinates
    private func linePath(for points: [CGPoint]) -> CGPath {
        let path = UIBezierPath()
        guard let firstPoint = points.first else { return path.cgPath }
        path.move(to: firstPoint)
        for (index, point) in points.enumerated() {
            guard index > 0 else { continue }
            let adjustedPoint = CGPoint(x: point.x + offset.width, y: point.y + offset.height)
            path.addLine(to: adjustedPoint)

            if index == points.count - 1 {
                path.addArc(withCenter: adjustedPoint, radius: lineWidth, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
            }
        }
        return path.cgPath
    }

    private func animateLine(from oldPoints: [CGPoint], to newPoints: [CGPoint]) {
        let grow = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.path))
        grow.fromValue = line.presentation()?.path ?? linePath(for: oldPoints)
        grow.toValue = linePath(for: newPoints)
        grow.duration = 1.0
        line.add(grow, forKey: "grow")
    }

    private func animateOutline(from oldPoints: [CGPoint], to newPoints: [CGPoint]) {
        let grow = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.path))
        grow.fromValue = outline.presentation()?.path ?? linePath(for: oldPoints)
        grow.toValue = linePath(for: newPoints)
        grow.duration = 1.0
        outline.add(grow, forKey: "grow")
    }
}
