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

class OCKLogItemButton: OCKButton {
    // MARK: Properties

    private enum Constants {
        static let spacing: CGFloat = 2
    }

    override var imageButton: OCKButton? { return _imageButton }
    override var detailButton: OCKButton? { _detailButton }
    override var titleButton: OCKButton? { _titleButton }

    private var imageButtonConstraint: NSLayoutConstraint?

    private let _imageButton: OCKButton = {
        let button = OCKButton()
        let image = UIImage(systemName: "clock")
        button.setImage(image, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.isUserInteractionEnabled = false
        button.contentHorizontalAlignment = .fill
        return button
    }()

    private let _titleButton: OCKButton = {
        let button = OCKButton(titleTextStyle: .caption1, titleWeight: .regular)
        button.isUserInteractionEnabled = false
        button.sizesToFitTitleLabel = true
        return button
    }()

    private let _detailButton: OCKButton = {
        let button = OCKButton(titleTextStyle: .caption1, titleWeight: .regular)
        button.tintedTraits = [TintedTrait(trait: .titleColor, state: .normal)]
        button.isUserInteractionEnabled = false
        button.sizesToFitTitleLabel = true
        return button
    }()

    private let contentStackView: OCKStackView = {
        let stackView = OCKStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.isUserInteractionEnabled = false
        return stackView
    }()

    // MARK: Methods

    override func setup() {
        super.setup()
        addSubviews()
        constrainSubviews()
        styleSubviews()
    }

    private func styleSubviews() {
        contentStackView.setCustomSpacing(Constants.spacing, after: _imageButton)
    }

    private func addSubviews() {
        addSubview(contentStackView)
        [_imageButton, _detailButton, _titleButton].forEach { contentStackView.addArrangedSubview($0) }
    }

    private func constrainSubviews() {
        [_imageButton, contentStackView].forEach { $0?.translatesAutoresizingMaskIntoConstraints = false }

        _detailButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        _titleButton.contentHorizontalAlignment = .left

        imageButtonConstraint = _imageButton.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            imageButtonConstraint!,
            _imageButton.widthAnchor.constraint(equalTo: _imageButton.heightAnchor),

            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])
    }

    override func setDetailColor(_ color: UIColor?, for state: UIControl.State) {
        super.setDetailColor(color, for: state)
        // match the detail image tint with the detail color
        if state == .normal {
            imageButton?.tintColor = color
        }
    }

    override func styleDidChange() {
        super.styleDidChange()
        let cachedStyle = style()
        _titleButton.setTitleColor(cachedStyle.color.label, for: .normal)
        imageButtonConstraint?.constant = cachedStyle.dimension.iconHeight4
        contentStackView.setCustomSpacing(cachedStyle.dimension.directionalInsets1.top, after: _detailButton)
        directionalLayoutMargins = cachedStyle.dimension.directionalInsets1
    }
}
