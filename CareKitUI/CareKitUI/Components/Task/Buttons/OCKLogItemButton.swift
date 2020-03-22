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

open class OCKLogItemButton: OCKAnimatedButton<OCKStackView> {

    private enum Constants {
        static let spacing: CGFloat = 3
    }

    // MARK: Properties

    /// The icon on the leading end of the button.
    public let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "clock")
        imageView.preferredSymbolConfiguration = .init(textStyle: .caption1)
        return imageView
    }()

    /// Main content label.
    public let titleLabel: OCKLabel = {
        let label = OCKLabel(textStyle: .caption1, weight: .regular)
        return label
    }()

    /// Tinted accessory label.
    public let detailLabel: OCKLabel = {
        let label = OCKLabel(textStyle: .caption1, weight: .regular)
        return label
    }()

    /// Holds the main content in the button.
    public let contentStackView: OCKStackView = {
        let stackView = OCKStackView.horizontal()
        stackView.alignment = .center
        stackView.distribution = .fill
        return stackView
    }()

    // MARK: - Life cycle

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
        addSubviews()
        constrainSubviews()
        styleSubviews()
    }

    private func styleSubviews() {
        contentStackView.setCustomSpacing(Constants.spacing, after: imageView)
        applyTintColor()
    }

    private func addSubviews() {
        addSubview(contentStackView)
        [imageView, detailLabel, titleLabel].forEach { contentStackView.addArrangedSubview($0) }
    }

    private func constrainSubviews() {
        [contentStackView].forEach { $0?.translatesAutoresizingMaskIntoConstraints = false }
        detailLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        NSLayoutConstraint.activate(
            contentStackView.constraints(equalTo: self, directions: [.horizontal]) +
            contentStackView.constraints(equalTo: layoutMarginsGuide, directions: [.vertical])
        )
    }

    private func applyTintColor() {
        detailLabel.textColor = tintColor
    }

    override open func styleDidChange() {
        super.styleDidChange()
        let style = self.style()
        titleLabel.textColor = style.color.label
        contentStackView.setCustomSpacing(style.dimension.directionalInsets1.top, after: detailLabel)
        directionalLayoutMargins = style.dimension.directionalInsets1
    }

    override open func tintColorDidChange() {
        super.tintColorDidChange()
        applyTintColor()
    }
}
