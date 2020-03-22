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

class OCKGraphAxisView: UIView {
    var axisMarkers = [String]() {
        didSet { redrawLabels() }
    }

    var selectedIndex: Int? {
        didSet { redrawLabels() }
    }

    private var tickViews = [OCKCircleLabelView]()

    private func redrawLabels() {
        tickViews.forEach { $0.removeFromSuperview() }
        tickViews = axisMarkers.enumerated().map { index, text in
            let view = OCKCircleLabelView(textStyle: .callout)
            view.frame = frameForMarker(atIndex: index)
            view.label.text = text
            view.label.textAlignment = .center
            view.label.isAccessibilityElement = false
            view.isSelected = index == selectedIndex
            return view
        }
        tickViews.forEach(addSubview)
    }

    private func frameForMarker(atIndex index: Int) -> CGRect {
        guard !axisMarkers.isEmpty else { return .zero }
        guard axisMarkers.count > 1 else { return bounds }
        let spacing = bounds.width / CGFloat(axisMarkers.count - 1)
        let centerX = spacing * CGFloat(index)
        let origin = CGPoint(x: centerX - spacing / 2, y: 0)
        let size = CGSize(width: spacing, height: bounds.height)
        let rect = CGRect(origin: origin, size: size)
        return rect
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        tickViews.enumerated().forEach { index, view in
            view.frame = frameForMarker(atIndex: index)
        }
    }
}

private class OCKCircleLabelView: OCKView {
    let label: OCKLabel

    var circleLayer: CAShapeLayer {
        guard let layer = layer as? CAShapeLayer else { fatalError("Unsupported type.") }
        return layer
    }

    override class var layerClass: AnyClass {
        return CAShapeLayer.self
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        applyTintColor()
    }

    var isSelected: Bool = false {
        didSet {
            updateLabelColor()
            circleLayer.fillColor = isSelected ? tintColor.cgColor : nil
        }
    }

    init(textStyle: UIFont.TextStyle) {
        label = OCKCappedSizeLabel(textStyle: .caption1, weight: .medium)
        super.init()
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Unsupported initializer")
    }

    override func setup() {
        super.setup()
        addSubview(label)
        updateLabelColor()
        applyTintColor()

        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor),
            label.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let padding: CGFloat = 4.0
        let maxDimension = max(label.intrinsicContentSize.width, label.intrinsicContentSize.height) + padding
        let size = CGSize(width: maxDimension, height: maxDimension)
        let origin = CGPoint(x: label.center.x - maxDimension / 2, y: label.center.y - maxDimension / 2)

        circleLayer.path = UIBezierPath(ovalIn: CGRect(origin: origin, size: size)).cgPath
        circleLayer.fillColor = isSelected ? tintColor.cgColor : nil
    }

    private func updateLabelColor() {
        label.textColor = isSelected ? style().color.customBackground : style().color.label
    }

    override func styleDidChange() {
        super.styleDidChange()
        updateLabelColor()
    }

    private func applyTintColor() {
        // Note: If animation is not disabled, the axis will fly in from the top of the view.
        CATransaction.performWithoutAnimations {
            circleLayer.fillColor = isSelected ? tintColor.cgColor : nil
        }
    }
}
