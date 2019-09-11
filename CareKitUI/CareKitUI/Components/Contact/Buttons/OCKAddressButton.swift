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

class OCKAddressButton: OCKButton {
    // MARK: Properties

    override var detailButton: OCKButton? { _detailButton }
    override var titleButton: OCKButton? { _titleButton }
    override var imageButton: OCKButton? { _imageButton }

    private var imageButtonHeightConstraint: NSLayoutConstraint?

    private enum Constants {
        static let textSpacing: CGFloat = 2
    }

    private let textStackView: OCKStackView = {
        let stackView = OCKStackView()
        stackView.axis = .vertical
        stackView.spacing = Constants.textSpacing
        stackView.isUserInteractionEnabled = false
        return stackView
    }()

    private let contentStackView: OCKStackView = {
        let stackView = OCKStackView()
        stackView.axis = .horizontal
        stackView.alignment = .top
        stackView.isUserInteractionEnabled = false
        return stackView
    }()

    private let _imageButton: OCKButton = {
        let button = OCKButton()
        button.isUserInteractionEnabled = false
        let image = UIImage(systemName: "location")?.applyingSymbolConfiguration(.init(weight: .bold))
        button.setImage(image, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.contentHorizontalAlignment = .fill   // Sizes the button's frame to the image view
        button.tag = 1
        return button
    }()

    private let _titleButton: OCKButton = {
        let button = OCKButton(titleTextStyle: .footnote, titleWeight: .semibold)
        button.titleLabel?.numberOfLines = 0
        button.isUserInteractionEnabled = false
        button.sizesToFitTitleLabel = true
        button.setTitle(OCKStrings.address, for: .normal)
        button.tintedTraits = [.init(trait: .titleColor, state: .normal)]
        button.contentHorizontalAlignment = .leading
        return button
    }()

    private let _detailButton: OCKButton = {
        let button = OCKButton(titleTextStyle: .footnote, titleWeight: .regular)
        button.titleLabel?.numberOfLines = 0
        button.isUserInteractionEnabled = false
        button.sizesToFitTitleLabel = true
        button.contentHorizontalAlignment = .leading
        return button
    }()

    // MARK: Methods

    override func setup() {
        super.setup()
        styleSubviews()
        addSubviews()
        constrainSubviews()
    }

    private func styleSubviews() {
        clipsToBounds = true
        adjustsImageWhenHighlighted = false
    }

    private func addSubviews() {
        [_titleButton, _detailButton].forEach { textStackView.addArrangedSubview($0) }
        [textStackView, _imageButton].forEach { contentStackView.addArrangedSubview($0) }
        addSubview(contentStackView)
    }

    func constrainSubviews() {
        [contentStackView, _imageButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        imageButtonHeightConstraint = _imageButton.heightAnchor.constraint(equalToConstant: 0)
        _imageButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        NSLayoutConstraint.activate(
            [imageButtonHeightConstraint!] +
            contentStackView.constraints(equalTo: layoutMarginsGuide))
    }

    override func styleDidChange() {
        super.styleDidChange()
        let cachedStyle = style()
        _detailButton.setTitleColor(cachedStyle.color.label, for: .normal)
        setBackgroundColor(cachedStyle.color.quaternarySystemFill, for: .normal)
        directionalLayoutMargins = cachedStyle.dimension.directionalInsets1
        layer.cornerRadius = cachedStyle.appearance.cornerRadius2
        imageButtonHeightConstraint?.constant = cachedStyle.dimension.iconHeight3
        contentStackView.spacing = cachedStyle.dimension.directionalInsets1.leading
    }
}
