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
open class OCKChecklistItemButton: OCKAnimatedButton<OCKStackView> {

    // MARK: Properties

    /// The label on the leading side of the button.
    public let label: OCKLabel = {
        let label = OCKLabel(textStyle: .subheadline, weight: .regular)
        label.text = loc("EVENT")
        return label
    }()

    /// The checkmark button on the trailing end of the view.
    public let checkmarkButton: OCKCheckmarkButton = {
        let button = OCKCheckmarkButton()
        button.isUserInteractionEnabled = false
        return button
    }()

    /// Holds the main content in the button.
    public let contentStackView: OCKStackView = {
        let stackView = OCKStackView.horizontal()
        stackView.alignment = .center
        return stackView
    }()

    // MARK: - Life Cycle

    public init() {
        super.init(contentView: contentStackView, handlesSelection: true)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(contentView: contentStackView, handlesSelection: true)
        setup()
    }

    // MARK: Methods

    private func setup() {
        addSubviews()
        constrainSubviews()
        setupAccessibility()
    }

    private func addSubviews() {
        [label, checkmarkButton].forEach { contentStackView.addArrangedSubview($0) }
        addSubview(contentStackView)
    }

    private func constrainSubviews() {
        [contentStackView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        checkmarkButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        NSLayoutConstraint.activate(
            contentStackView.constraints(equalTo: self, directions: [.horizontal]) +
            contentStackView.constraints(equalTo: layoutMarginsGuide, directions: [.vertical])
        )
    }

    private func setupAccessibility() {
        accessibilityValue = isSelected ? loc("COMPLETED") : loc("INCOMPLETE")
        accessibilityHint = isSelected ? loc("DOUBLE_TAP_TO_COMPLETE") : loc("DOUBLE_TAP_TO_INCOMPLETE")
    }

    override open func styleDidChange() {
        super.styleDidChange()
        let style = self.style()
        directionalLayoutMargins = style.dimension.directionalInsets1
        checkmarkButton.height.update(withContainer: style, keyPath: \.dimension.buttonHeight3)
        checkmarkButton.imageViewPointSize.update(withContainer: style, keyPath: \.dimension.symbolPointSize5)
        label.textColor = style.color.label
    }

    override open func setSelected(_ isSelected: Bool, animated: Bool) {
        super.setSelected(isSelected, animated: animated)
        checkmarkButton.setSelected(isSelected, animated: animated)
        setupAccessibility()
    }

    override open func setStyleForSelectedState(_ isSelected: Bool) {}
}
