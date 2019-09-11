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

/// A card that displays information for a contact. The header is an `OCKHeaderView`
/// The body contains a multi-line istructions label, and four buttons; call, message,
/// email, and address. The first three buttons have title labels and image views that can
/// be modified, while the last has a title label, body label, and image view.
///
///     +-------------------------------------------------------+
///     | +------+                                              |
///     | | icon | [title]                                      |
///     | | img  | [detail]                                     |
///     | +------+                                              |
///     |                                                       |
///     |  --------------------------------------------------   |
///     |                                                       |
///     | [Instructions]                                        |
///     |                                                       |
///     | +------------+      +------------+     +------------+ |
///     | |  [title]   |      |   [title]  |     |   [title]  | |
///     | |            |      |            |     |            | |
///     | +------------+      +------------+     +------------+ |
///     |                                                       |
///     | +---------------------------------------------------+ |
///     | |  [title]                                          | |
///     | |  [detail]                                         | |
///     | |                                                   | |
///     | +---------------------------------------------------+ |
///     +-------------------------------------------------------+
///
open class OCKDetailedContactView: OCKView, OCKContactDisplayable {
    /// Handles events related to an `OCKContactDisplayable` object.
    public weak var delegate: OCKContactViewDelegate?

    private var buttons: [OCKButton] {
        return [addressButton, callButton, messageButton, emailButton]
    }

    private var contactButtons: [OCKContactButton] {
        return buttons.compactMap { $0 as? OCKContactButton }
    }

    let contentView = OCKView()

    private lazy var cardAssembler = OCKCardAssembler(cardView: self, contentView: contentView)

    /// A vertical stack view that holds the main content in the view.
    public let contentStackView: OCKStackView = {
        let stackView = OCKStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        return stackView
    }()

    /// Header stack view that shows an `iconImageView` and a separator.
    public let headerView = OCKHeaderView {
        $0.showsIconImage = true
        $0.showsSeparator = true
    }

    /// Stack view that holds phone, message, and email contact action buttons.
    private let contactStackView: OCKStackView = {
        let stackView = OCKStackView(style: .plain)
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        return stackView
    }()

    /// Stack view that holds buttons in `contactStack` and `directionsButton`.
    /// You may choose to add or hide buttons
    private let buttonStackView: OCKStackView = {
        let stackView = OCKStackView(style: .plain)
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        return stackView
    }()

    /// Multi-line label under the `headerView`.
    public let instructionsLabel: OCKLabel = {
        let label = OCKLabel(textStyle: .subheadline, weight: .medium)
        label.numberOfLines = 0
        return label
    }()

    /// Button with a phone image and `titleLabel`.
    /// Set the `isHidden` property to `false` to hide the button.
    public let callButton: OCKButton = OCKContactButton(type: .call)

    /// Button with a messages images and `titleLabel`.
    /// Set the `isHidden` property to `false` to hide the button.
    public let messageButton: OCKButton = OCKContactButton(type: .message)

    /// Button with an email image and `titleLabel`.
    /// Set the `isHidden` property to `false` to hide the button.
    public let emailButton: OCKButton = OCKContactButton(type: .email)

    /// Button with a location image, `titleLabel`, and `detailLabel`.
    /// Set the `isHidden` property to `false` to hide the button.
    public let addressButton: OCKButton = OCKAddressButton()

    /// The default image that can be used as a placeholder for the `iconImageView` in the `headerView`.
    public static let defaultImage = UIImage(systemName: "person.crop.circle")!

    /// Prepares interface after initialization
    override func setup() {
        super.setup()
        addSubviews()
        constrainSubviews()
        styleSubviews()
        setupGestures()
    }

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        headerView.addGestureRecognizer(tapGesture)

        [messageButton, callButton, addressButton, emailButton].forEach {
            $0.addTarget(self, action: #selector(didTapButton(_:)), for: .touchUpInside)
        }
    }

    private func addSubviews() {
        addSubview(contentView)
        contentView.addSubview(contentStackView)
        [headerView, instructionsLabel, buttonStackView].forEach { contentStackView.addArrangedSubview($0) }
        [callButton, messageButton, emailButton].forEach { contactStackView.addArrangedSubview($0) }
        [contactStackView, addressButton].forEach { buttonStackView.addArrangedSubview($0) }
    }

    private func constrainSubviews() {
        [contentView, contentStackView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate(
            contentView.constraints(equalTo: layoutMarginsGuide) +
            contentStackView.constraints(equalTo: contentView)
        )
    }

    private func styleSubviews() {
        headerView.iconImageView?.image = OCKDetailedContactView.defaultImage   // set default profile picture
    }

    @objc
    private func didTapButton(_ sender: OCKButton) {
        switch sender {
        case messageButton: delegate?.contactView(self, senderDidInitiateMessage: sender)
        case callButton: delegate?.contactView(self, senderDidInitiateCall: sender)
        case addressButton: delegate?.contactView(self, senderDidInitiateAddressLookup: sender)
        case emailButton: delegate?.contactView(self, senderDidInitiateEmail: sender)
        default: fatalError("Target not set up properly")
        }
    }

    @objc
    func viewTapped(_ sender: UITapGestureRecognizer) {
        delegate?.didSelectContactView(self)
    }

    override open func styleDidChange() {
        super.styleDidChange()
        let cachedStyle = style()
        cardAssembler.enableCardStyling(true, style: cachedStyle)
        instructionsLabel.textColor = cachedStyle.color.label
        directionalLayoutMargins = cachedStyle.dimension.directionalInsets1
        addressButton.detailButton?.setTitleColor(cachedStyle.color.label, for: .normal)

        buttons.forEach {
            $0.setBackgroundColor(cachedStyle.color.quaternarySystemFill, for: .normal)
            $0.layer.cornerRadius = cachedStyle.appearance.cornerRadius2
        }

        let topInset = cachedStyle.dimension.directionalInsets1.top
        contentStackView.spacing = topInset
        [contactStackView, buttonStackView].forEach { $0.spacing = topInset / 2.0 }
    }
}
