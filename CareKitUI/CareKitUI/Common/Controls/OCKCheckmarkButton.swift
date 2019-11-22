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

/// A button that shows a checkmark in the selected state, and an empty ring in the deselected state.
open class OCKCheckmarkButton: OCKAnimatedButton<UIView> {

    override open var intrinsicContentSize: CGSize {
        return .init(width: height.scaledValue, height: height.scaledValue)
    }

    /// Checkmark image in the center of the view.
    public let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "checkmark")
        return imageView
    }()

    lazy var height = OCKAccessibleValue(container: style(), keyPath: \.dimension.buttonHeight2) { [weak self] _ in
        self?.invalidateIntrinsicContentSize()
    }

    lazy var lineWidth = OCKAccessibleValue(container: style(), keyPath: \.appearance.borderWidth1) { [circleMaskBorderLayer] scaledValue in
        circleMaskBorderLayer.lineWidth = scaledValue
    }

    lazy var imageViewPointSize = OCKAccessibleValue(container: style(), keyPath: \.dimension.symbolPointSize3) { [imageView] scaledValue in
        imageView.preferredSymbolConfiguration = .init(pointSize: scaledValue, weight: .bold)
    }

    private let circleMaskBorderLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        return layer
    }()

    private let circleMask = CAShapeLayer()

    // MARK: Life cycle

    public init() {
        super.init(contentView: imageView)
        setup()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        updateMaskFor(rect: bounds)
    }

    // MARK: Methods

    private func setup() {
        constrainSubviews()
        styleSubviews()

        layer.mask = circleMask
        layer.addSublayer(circleMaskBorderLayer)
    }

    private func styleSubviews() {
        clipsToBounds = true
        setStyleForSelectedState(false)
    }

    private func constrainSubviews() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    private func updateMaskFor(rect: CGRect) {
        circleMask.path = UIBezierPath(ovalIn: rect).cgPath
        circleMaskBorderLayer.path = UIBezierPath(ovalIn: rect).cgPath
    }

    override open func styleDidChange() {
        super.styleDidChange()
        let style = self.style()
        height.update(withContainer: style)
        lineWidth.update(withContainer: style)
        imageViewPointSize.update(withContainer: style)
        if isSelected {
            imageView.tintColor = style.color.customBackground
        }
    }

    override open func tintColorDidChange() {
        super.tintColorDidChange()
        circleMaskBorderLayer.strokeColor = tintColor.cgColor

        if isSelected {
            backgroundColor = tintColor
        }
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            [lineWidth, height, imageViewPointSize].forEach { $0.apply() }
        }
    }

    /// Set the style for the selected state. This function may be called in an animation block if the state is being animated.
    /// - Parameter isSelected: True if the button is in the selected state.
    override open func setStyleForSelectedState(_ isSelected: Bool) {
        if isSelected {
            imageView.tintColor = style().color.customBackground
            backgroundColor = tintColor
        } else {
            imageView.tintColor = .clear
            backgroundColor = .clear
        }
    }
}
