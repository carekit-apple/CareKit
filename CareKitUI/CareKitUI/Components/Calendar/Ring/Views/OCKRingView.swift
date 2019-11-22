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

/// A fillable progress ring drawing.
class OCKRingView: OCKView {

    // MARK: Properties

    /// The progress of the ring between 0 and 1. The ring will fill based on the value.
    private(set) var progress: CGFloat = 1.0

    private let ringLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineCap = .round
        layer.fillColor = nil
        layer.strokeStart = 0
        return layer
    }()

    /// The line width of the ring.
    var lineWidth: CGFloat = 10 {
        didSet { ringLayer.lineWidth = lineWidth }
    }

    /// The stroke color of the ring.
    var strokeColor: UIColor = OCKStyle().color.customBlue {
        didSet { ringLayer.strokeColor = strokeColor.cgColor }
    }

    /// The start angle of the ring to begin drawing.
    var startAngle: CGFloat = -.pi / 2 {
        didSet { ringLayer.path = ringPath() }
    }

    /// The end angle of the ring to end drawing.
    var endAngle: CGFloat = 1.5 * .pi {
        didSet { ringLayer.path = ringPath() }
    }

    /// Duration of the ring's fill animation.
    var duration: TimeInterval = 1.0

    /// The radius oof the ring.
    var radius: CGFloat {
        return min(bounds.height, bounds.width) / 2 - lineWidth / 2
    }

    // MARK: Life Cycle

    override func layoutSubviews() {
        super.layoutSubviews()
        configureRing()
    }

    // MARK: Methods

    override func setup() {
        super.setup()
        layer.addSublayer(ringLayer)
        styleRingLayer()
    }

    /// Set the progress value of the ring. The ring will fill based on the value.
    ///
    /// - Parameters:
    ///   - value: Progress value between 0 and 1.
    ///   - animated: Flag for the fill ring's animation.
    func setProgress(_ value: CGFloat, animated: Bool) {
        layoutIfNeeded()

        let oldValue = ringLayer.presentation()?.strokeEnd ?? progress
        progress = value
        ringLayer.strokeEnd = progress
        guard animated else { return }

        let path = #keyPath(CAShapeLayer.strokeEnd)
        let fill = CABasicAnimation(keyPath: path)
        fill.fromValue = oldValue
        fill.toValue = value
        fill.duration = duration
        fill.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        ringLayer.add(fill, forKey: "fill")
    }

    private func styleRingLayer() {
        strokeColor = tintColor
        ringLayer.strokeColor = strokeColor.cgColor
        ringLayer.strokeEnd = min(progress, 1.0)
        ringLayer.lineWidth = lineWidth
    }

    private func configureRing() {
        ringLayer.frame = bounds
        ringLayer.path = ringPath()
    }

    private func ringPath() -> CGPath {
        let center = CGPoint(x: bounds.origin.x + frame.width / 2.0, y: bounds.origin.y + frame.height / 2.0)
        let circlePath = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        return circlePath.cgPath
    }
}
