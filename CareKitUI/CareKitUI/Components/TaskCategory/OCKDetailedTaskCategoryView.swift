/*
 Copyright (c) 2020, Apple Inc. All rights reserved.
 
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

/// A card that displays information for a task category. The header is an `OCKHeaderView`
/// The body contains a multi-line istructions label, and four buttons; call, message,
/// email, and address. The first three buttons have title labels and image views that can
/// be modified, while the last has a title label, body label, and image view.
///
///     +-------------------------------------------------------+
///     | +------+                                              |
///     | | icon | [title]                                      |
///     | | img  | [detail]                                     |
///     | +------+                                              |
///     +-------------------------------------------------------+
///
open class OCKDetailedTaskCategoryView: OCKView, OCKTaskCategoryDisplayable {

    // MARK: Properties

    /// Handles events related to an `OCKOCKTaskCategoryDisplayable` object.
    public weak var delegate: OCKTaskCategoryViewDelegate?

    /// A vertical stack view that holds the main content in the view.
    public let contentStackView: OCKStackView = {
        let stackView = OCKStackView.vertical()
        stackView.distribution = .fill
        return stackView
    }()

    /// Header stack view that shows an `iconImageView` and a separator.
    public let headerView = OCKHeaderView {
        $0.showsIconImage = true
        $0.showsSeparator = false
        $0.showsDetailDisclosure = true
        $0.isIconImageCircular = true
    }

    /// The default image that can be used as a placeholder for the `iconImageView` in the `headerView`.
    public static let defaultImage = UIImage(systemName: "questionmark.circle.fill")!

    let contentView = OCKView()

    private lazy var cardBuilder = OCKCardBuilder(cardView: self, contentView: contentView)

    // Button that displays the highlighted state for the view.
    private lazy var backgroundButton = OCKAnimatedButton(contentView: contentStackView, highlightOptions: [.defaultOverlay, .defaultDelayOnSelect],
                                                          handlesSelection: false)

    /// Stack view that holds phone, message, and email task category action buttons.
    private lazy var taskCategoryStackView: OCKStackView = {
        let stackView = OCKStackView()
        stackView.axis = self.taskCategoryStackAxisDirection()
        stackView.distribution = .fillEqually
        return stackView
    }()

    // MARK: - Methods

    /// Prepares interface after initialization
    override func setup() {
        super.setup()
        addSubviews()
        constrainSubviews()
        styleSubviews()
        setupGestures()
    }

    private func setupGestures() {
        backgroundButton.addTarget(self, action: #selector(viewTapped(_:)), for: .touchUpInside)
    }

    @objc
    private func viewTapped(_ sender: UIControl) {
        delegate?.didSelectTaskCategoryView(self)
    }

    private func addSubviews() {
        addSubview(contentView)
        contentView.addSubview(backgroundButton)
        contentView.addSubview(contentStackView)

        [headerView].forEach { contentStackView.addArrangedSubview($0) }
    }

    private func constrainSubviews() {
        [contentView, backgroundButton, contentStackView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate(
            contentView.constraints(equalTo: self) +
            backgroundButton.constraints(equalTo: contentView) +
            contentStackView.constraints(equalTo: backgroundButton.layoutMarginsGuide))
    }

    private func styleSubviews() {
        headerView.iconImageView?.image = OCKDetailedTaskCategoryView.defaultImage   // set default profile picture
    }

    override open func styleDidChange() {
        super.styleDidChange()
        let cachedStyle = style()
        cardBuilder.enableCardStyling(true, style: cachedStyle)
        directionalLayoutMargins = cachedStyle.dimension.directionalInsets1
        let topInset = cachedStyle.dimension.directionalInsets1.top
        contentStackView.spacing = topInset

        [taskCategoryStackView].forEach { $0.spacing = topInset / 2.0 }
    }

    // MARK: Accessibility Scaling

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        taskCategoryStackView.axis = taskCategoryStackAxisDirection()
    }

    private func taskCategoryStackAxisDirection() -> NSLayoutConstraint.Axis {
        traitCollection.preferredContentSizeCategory < .extraExtraLarge ? .horizontal : .vertical
    }
}
