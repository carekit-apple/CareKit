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
open class OCKSimpleTaskView: OCKView, OCKEventDisplayable {
    // MARK: Properties

    let contentView = OCKView()

    private lazy var cardAssembler = OCKCardAssembler(cardView: self, contentView: contentView)

    /// Handles events related to an `OCKEventDisplayable` object.
    public weak var delegate: OCKEventViewDelegate?

    /// The vertical stack view that holds the main content in the view.
    public let contentStackView: OCKStackView = {
        let stack = OCKStackView()
        stack.axis = .vertical
        return stack
    }()

    private let innerContentStackView: OCKStackView = {
        let stack = OCKStackView()
        stack.axis = .horizontal
        return stack
    }()

    /// The button in the trailing end of the card. Has an image that is defaulted to a checkmark when selected.
    public let completionButton: OCKButton = {
        let button = OCKCircleButton()
        button.isUserInteractionEnabled = false
        return button
    }()

    /// A default version of an `OCKHeaderView`.
    public let headerView = OCKHeaderView()

    private var completionButtonHeightConstraint: NSLayoutConstraint?

    // MARK: Methods

    override func setup() {
        super.setup()
        setupGestures()
        addSubviews()
        constrainSubviews()
    }

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didCompleteEvent(_:)))
        addGestureRecognizer(tapGesture)
    }

    private func addSubviews() {
        addSubview(contentView)
        contentView.addSubview(contentStackView)
        contentStackView.addArrangedSubview(innerContentStackView)
        [headerView, completionButton].forEach { innerContentStackView.addArrangedSubview($0) }
    }

    private func constrainSubviews() {
        [contentView, contentStackView, completionButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        completionButtonHeightConstraint = completionButton.heightAnchor.constraint(equalToConstant: 0)    // will get set when style updates
        headerView.setContentHuggingPriority(.defaultLow, for: .horizontal)

        NSLayoutConstraint.activate([
            completionButtonHeightConstraint!,
            completionButton.widthAnchor.constraint(equalTo: completionButton.heightAnchor)
        ] + contentView.constraints(equalTo: layoutMarginsGuide) +
            contentStackView.constraints(equalTo: contentView))
    }

    override open func styleDidChange() {
        super.styleDidChange()
        let cachedStyle = style()
        cardAssembler.enableCardStyling(true, style: cachedStyle)
        directionalLayoutMargins = cachedStyle.dimension.directionalInsets1
        completionButtonHeightConstraint?.constant = cachedStyle.dimension.buttonHeight2
        (completionButton as? OCKCircleButton)?.checkmarkHeight = cachedStyle.dimension.iconHeight3
    }

    @objc
    private func didCompleteEvent(_ gesture: UITapGestureRecognizer) {
        guard
            let sender = gesture.view,
            gesture.state == .ended
        else { return }

        completionButton.isSelected.toggle()
        delegate?.eventView(self, didCompleteEvent: completionButton.isSelected, sender: sender)
    }
}
