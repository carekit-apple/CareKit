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
#if !os(watchOS)

import UIKit

class OCKBarLayer: OCKCartesianCoordinatesLayer, OCKGradientPlotable {
    let gradientLayer = CAGradientLayer()
    let pointsLayer = CAShapeLayer()

    var startColor: UIColor = OCKStyle().color.customGray {
        didSet { gradientLayer.colors = [startColor.cgColor, endColor.cgColor] }
    }

    var endColor: UIColor = OCKStyle().color.customGray {
        didSet { gradientLayer.colors = [startColor.cgColor, endColor.cgColor] }
    }

    var barWidth: CGFloat = 10 {
        didSet { setNeedsLayout() }
    }

    var horizontalOffset: CGFloat = 0 {
        didSet { setNeedsLayout() }
    }

    override init() {
        super.init()
        setupSublayers()
    }

    override init(layer: Any) {
        super.init(layer: layer)
        setupSublayers()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSublayers()
    }

    private func setupSublayers() {
        gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.mask = pointsLayer
        addSublayer(gradientLayer)

        pointsLayer.fillColor = OCKStyle().color.customGray.cgColor
        pointsLayer.strokeColor = nil
    }

    override func layoutSublayers() {
        super.layoutSublayers()
        drawPoints(points)
    }

    override func animateInGraphCoordinates(from oldPoints: [CGPoint], to newPoints: [CGPoint]) {
        let grow = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.path))
        grow.fromValue = pointsLayer.presentation()?.path ?? makePath(points: oldPoints)
        grow.toValue = makePath(points: newPoints)
        grow.timingFunction = CAMediaTimingFunction(name: .easeOut)
        grow.duration = 1.0
        pointsLayer.add(grow, forKey: "grow")
    }

    func makePath(points: [CGPoint]) -> CGPath {
        let path = UIBezierPath()
        for point in points {
            let origin = CGPoint(x: point.x - barWidth / 2 + horizontalOffset, y: point.y)
            let size = CGSize(width: barWidth, height: bounds.height - point.y)
            let rectangle = CGRect(origin: origin, size: size)
            let cornerRadii = CGSize(width: barWidth / 4, height: barWidth / 4)
            let rectPath = UIBezierPath(roundedRect: rectangle, byRoundingCorners: [.topLeft, .topRight], cornerRadii: cornerRadii)
            path.append(rectPath)
        }
        return path.cgPath
    }
}
#endif
