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

class OCKContactButton: OCKButton {
    // MARK: Properties

    enum `Type`: String {
        case call = "Call"
        case message = "Message"
        case email = "E-mail"

        var image: UIImage? {
            let image: UIImage?
            switch self {
            case .call: image = UIImage(systemName: "phone")
            case .message: image = UIImage(systemName: "text.bubble")
            case .email: image = UIImage(systemName: "envelope")
            }
            return image?.applyingSymbolConfiguration(.init(weight: .medium))
        }
    }

    override var imageButton: OCKButton? { _imageButton }
    override var titleButton: OCKButton? { _titleButton }

    private let _imageButton: OCKButton = {
        let button = OCKButton()
        button.imageView?.contentMode = .scaleAspectFit
        button.isUserInteractionEnabled = false
        button.contentHorizontalAlignment = .fill
        return button
    }()

    private let _titleButton: OCKButton = {
        let button = OCKButton(titleTextStyle: .footnote, titleWeight: .semibold)
//        button.titleLabel?.textAlignment = .center
        button.isUserInteractionEnabled = false
        button.sizesToFitTitleLabel = true
        button.tintedTraits = [.init(trait: .titleColor, state: .normal)]
        return button
    }()

    private let contentStackView: OCKStackView = {
        let stackView = OCKStackView()
        stackView.axis = .vertical
        stackView.spacing = 2
        stackView.isUserInteractionEnabled = false
        return stackView
    }()

    let type: Type

    private var imageButtonHeightConstraint: NSLayoutConstraint?

    // MARK: Life cycle

    init(type: Type) {
        self.type = type
        super.init()
    }

    // MARK: Methods

    override func setup() {
        super.setup()
        styleSubviews()
        addSubviews()
        constrainSubviews()
    }

    private func styleSubviews() {
        setImage(type.image, for: .normal)
        _titleButton.setTitle(type.rawValue, for: .normal)
        clipsToBounds = true
        adjustsImageWhenHighlighted = false
    }

    func addSubviews() {
        addSubview(contentStackView)
        [_imageButton, _titleButton].forEach { contentStackView.addArrangedSubview($0) }
    }

    func constrainSubviews() {
        [contentStackView, _imageButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        imageButtonHeightConstraint = _imageButton.heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate(
            [imageButtonHeightConstraint!] +
            contentStackView.constraints(equalTo: layoutMarginsGuide))
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        _imageButton.imageView?.tintColor = tintColor
    }

    override func styleDidChange() {
        super.styleDidChange()
        let cachedStyle = style()
        setBackgroundColor(cachedStyle.color.quaternarySystemFill, for: .normal)
        layer.cornerRadius = cachedStyle.appearance.cornerRadius2
        imageButtonHeightConstraint?.constant = cachedStyle.dimension.buttonHeight3
        directionalLayoutMargins = cachedStyle.dimension.directionalInsets1
    }
}
