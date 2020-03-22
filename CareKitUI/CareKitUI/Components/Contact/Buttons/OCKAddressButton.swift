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

open class OCKAddressButton: OCKAnimatedButton<OCKStackView> {
    // MARK: Properties

    private enum Constants {
        static let textSpacing: CGFloat = 2
    }

    private lazy var imageViewPointSize = OCKAccessibleValue(container: style(), keyPath: \.dimension.symbolPointSize3) { [imageView] scaledValue in
        imageView.preferredSymbolConfiguration = .init(pointSize: scaledValue, weight: .regular)
    }

    private let textStackView: OCKStackView = {
        let stackView = OCKStackView.vertical()
        stackView.spacing = Constants.textSpacing
        return stackView
    }()

    /// Holds the main content in the button.
    public let contentStackView: OCKStackView = {
        let stackView = OCKStackView.horizontal()
        stackView.alignment = .top
        return stackView
    }()

    /// Image in the corner of the view. The default image is set to the location icon.
    public let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "location")
        return imageView
    }()

    /// The main text in the button.
    public let titleLabel: OCKLabel = {
        let label = OCKLabel(textStyle: .footnote, weight: .semibold)
        label.numberOfLines = 0
        label.text = loc("ADDRESS")
        return label
    }()

    /// Below the main text in the button.
    public let detailLabel: OCKLabel = {
        let label = OCKLabel(textStyle: .footnote, weight: .regular)
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Life Cycle

    public init() {
        super.init(contentView: contentStackView, handlesSelection: false)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(contentView: contentStackView, handlesSelection: false)
        setup()
    }

    // MARK: Methods

    private func setup() {
        styleSubviews()
        addSubviews()
        constrainSubviews()
    }

    private func styleSubviews() {
        accessibilityLabel = titleLabel.text
        accessibilityHint = loc("DOUBLE_TAP_MAP")
        applyTintColor()
    }

    private func applyTintColor() {
        titleLabel.textColor = tintColor
    }

    private func addSubviews() {
        [titleLabel, detailLabel].forEach { textStackView.addArrangedSubview($0) }
        [textStackView, imageView].forEach { contentStackView.addArrangedSubview($0) }
        addSubview(contentStackView)
    }

    private func constrainSubviews() {
        [contentStackView, imageView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        NSLayoutConstraint.activate(contentStackView.constraints(equalTo: layoutMarginsGuide))
    }

    override open func styleDidChange() {
        super.styleDidChange()
        let style = self.style()
        detailLabel.textColor = style.color.label
        backgroundColor = style.color.quaternaryCustomFill
        directionalLayoutMargins = style.dimension.directionalInsets1
        layer.cornerRadius = style.appearance.cornerRadius2
        imageViewPointSize.update(withContainer: style)
        contentStackView.spacing = style.dimension.directionalInsets1.leading
    }

    override open func tintColorDidChange() {
        super.tintColorDidChange()
        applyTintColor()
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            imageViewPointSize.apply()
        }
    }
}
