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

import Foundation
import UIKit

/// A button with an icon and title label.
///
///     +--------------------------+
///     | [Title]           [Icon] |
///     +--------------------------+
///
class OCKChecklistItemButton: OCKButton {
    // MARK: Properties

    private enum Constants {
        static let marginFactor: CGFloat = 1.5
    }

    private var circleButtonHeightConstraint: NSLayoutConstraint?

    override var titleButton: OCKButton? { _titleButton }
    override var imageButton: OCKButton? { circleButton }

    /// The title button embedded inside this button.
    private let _titleButton: OCKButton = {
        let button = OCKButton(titleTextStyle: .subheadline, titleWeight: .regular)
        button.isUserInteractionEnabled = false
        button.setTitle(OCKStrings.event, for: .normal)
        button.setTitle(OCKStrings.event, for: .selected)
        button.contentHorizontalAlignment = .left
        button.sizesToFitTitleLabel = true
        return button
    }()

    /// The icon embedded inside this button.
    private let circleButton: OCKCircleButton = {
        let button = OCKCircleButton()
        button.isUserInteractionEnabled = false
        return button
    }()

    private let contentStackView: OCKStackView = {
        let stackView = OCKStackView()
        stackView.axis = .horizontal
        stackView.isUserInteractionEnabled = false
        return stackView
    }()

    // MARK: Methods

    override func setup() {
        super.setup()
        addSubviews()
        constrainSubviews()
    }

    private func addSubviews() {
        [_titleButton, circleButton].forEach { contentStackView.addArrangedSubview($0) }
        addSubview(contentStackView)
    }

    private func constrainSubviews() {
        [contentStackView, circleButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        circleButtonHeightConstraint = circleButton.heightAnchor.constraint(equalToConstant: 0)
        _titleButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        NSLayoutConstraint.activate([
            circleButtonHeightConstraint!,
            circleButton.widthAnchor.constraint(equalTo: circleButton.heightAnchor),

            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])
    }

    override func styleDidChange() {
        super.styleDidChange()
        let cachedStyle = style()
        _titleButton.setTitleColor(cachedStyle.color.label, for: .normal)
        _titleButton.setTitleColor(cachedStyle.color.secondaryLabel, for: .selected)
        circleButtonHeightConstraint?.constant = cachedStyle.dimension.buttonHeight3
        circleButton.checkmarkHeight = cachedStyle.dimension.iconHeight5
        directionalLayoutMargins = cachedStyle.dimension.directionalInsets1
    }
}
