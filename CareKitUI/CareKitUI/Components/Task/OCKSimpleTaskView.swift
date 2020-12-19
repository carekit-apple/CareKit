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

/// A card that displays an `OCKHeaderView` and a circular checkmark button `completionButton`.
/// In CareKit, this view is intended to display a particular event for a task. The state of the `completionButton`
/// indicates the completion state of the event.
///
/// To insert custom views vertically the view, see `contentStack`
///
///     +-------------------------------------------------------+
///     |                                                       |
///     | [title]                                 [completion   |
///     | [detail]                                 button]      |
///     |                                                       |
///     +-------------------------------------------------------+
///
open class OCKSimpleTaskView: OCKView, OCKTaskDisplayable {

    // MARK: Properties

    private let contentView: OCKView = {
        let view = OCKView()
        view.clipsToBounds = true
        return view
    }()

    // Button that displays the highlighted state for the view.
    private lazy var backgroundButton = OCKAnimatedButton(contentView: horizontalContentStackView, handlesSelection: false)

    private let horizontalContentStackView: OCKStackView = {
        let stack = OCKStackView.horizontal()
        stack.alignment = .center
        return stack
    }()

    /// The button in the trailing end of the card. Has an image that is defaulted to a checkmark when selected.
    public let completionButton: OCKCheckmarkButton = {
        let button = OCKCheckmarkButton()
        button.isUserInteractionEnabled = false
        return button
    }()

    /// Handles events related to an `OCKTaskDisplayable` object.
    public weak var delegate: OCKTaskViewDelegate?

    /// A default version of an `OCKHeaderView`.
    public let headerView = OCKHeaderView()

    // MARK: Methods

    override func setup() {
        super.setup()
        setupGestures()
        addSubviews()
        constrainSubviews()

        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    private func setupGestures() {
        backgroundButton.addTarget(self, action: #selector(didCompleteEvent(_:)), for: .touchUpInside)
    }

    private func addSubviews() {
        addSubview(contentView)
        contentView.addSubview(backgroundButton)
        [headerView, completionButton].forEach { horizontalContentStackView.addArrangedSubview($0) }
    }

    private func constrainSubviews() {
        [contentView, backgroundButton, horizontalContentStackView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        completionButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        NSLayoutConstraint.activate(
            contentView.constraints(equalTo: self) +
            backgroundButton.constraints(equalTo: contentView) +
            horizontalContentStackView.constraints(equalTo: backgroundButton.layoutMarginsGuide))
    }

    @objc
    private func didCompleteEvent(_ sender: UIControl) {
        completionButton.setSelected(!completionButton.isSelected, animated: true)
        delegate?.taskView(self, didCompleteEvent: completionButton.isSelected, at: .init(row: 0, section: 0), sender: sender)
    }

    override open func styleDidChange() {
        super.styleDidChange()
        let style = self.style()
        let cardBuilder = OCKCardBuilder(cardView: self, contentView: contentView)
        cardBuilder.enableCardStyling(true, style: style)
        backgroundButton.directionalLayoutMargins = style.dimension.directionalInsets1
    }
}
