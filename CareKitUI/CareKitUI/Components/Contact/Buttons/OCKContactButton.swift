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

open class OCKContactButton: OCKAnimatedButton<OCKStackView> {
    // MARK: Properties

    /// Determines the label text and image shown in the button.
    public enum `Type`: String {

        /// Button for phone calls.
        case call = "Call"

        /// Button for text messages.
        case message = "Message"

        /// Button for emails.
        case email = "E-mail"

        var image: UIImage? {
            let image: UIImage?
            switch self {
            case .call: image = UIImage(systemName: "phone")
            case .message: image = UIImage(systemName: "text.bubble")
            case .email: image = UIImage(systemName: "envelope")
            }
            return image
        }
    }

    /// Image above the title label.
    public let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    /// Title label under the image.
    public let label: OCKLabel = {
        let label = OCKLabel(textStyle: .footnote, weight: .semibold)
        label.textAlignment = .center
        return label
    }()

    /// Holds the main content for the view.
    public let contentStackView: OCKStackView = {
        let stackView = OCKStackView.vertical()
        stackView.spacing = 2
        stackView.isUserInteractionEnabled = false
        return stackView
    }()

    let type: Type

    private lazy var imageViewPointSize = OCKAccessibleValue(container: style(), keyPath: \.dimension.symbolPointSize2) { [imageView] scaledValue in
        imageView.preferredSymbolConfiguration = .init(pointSize: scaledValue, weight: .regular)
    }

    // MARK: Life cycle

    /// Initialize the button with a type. The type determines the label text and image.
    /// - Parameter type: The type of the button.
    public init(type: Type) {
        self.type = type
        super.init(contentView: contentStackView, handlesSelection: false)
        setup()
    }

    public required init?(coder: NSCoder) {
        self.type = .call
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
        imageView.image = type.image
        label.text = type.rawValue

        switch type {
        case .call: accessibilityLabel = loc("CALL")
        case .email: accessibilityLabel = loc("EMAIL")
        case .message: accessibilityLabel = loc("MESSAGE")
        }

        applyTintColor()
    }

    private func addSubviews() {
        [imageView, label].forEach { contentStackView.addArrangedSubview($0) }
    }

    private func constrainSubviews() {
        [contentStackView, imageView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate(contentStackView.constraints(equalTo: layoutMarginsGuide))
    }

    private func applyTintColor() {
        imageView.tintColor = tintColor
        label.textColor = tintColor
    }

    override open func tintColorDidChange() {
        super.tintColorDidChange()
        applyTintColor()
    }

    override open func styleDidChange() {
        super.styleDidChange()
        let style = self.style()
        backgroundColor = style.color.quaternaryCustomFill
        layer.cornerRadius = style.appearance.cornerRadius2
        imageViewPointSize.update(withContainer: style)
        directionalLayoutMargins = style.dimension.directionalInsets1
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            imageViewPointSize.apply()
        }
    }
}
