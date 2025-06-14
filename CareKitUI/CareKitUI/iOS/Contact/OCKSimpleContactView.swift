/*
 Copyright (c) 2016-2025, Apple Inc. All rights reserved.

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
#if !os(watchOS)

import UIKit

/// A card that displays information for a contact. The header is an `OCKHeaderView`.
///
/// ```
///     +-------------------------------------------------------+
///     | +------+                                              |
///     | | icon | [title]                       [detail        |
///     | | img  | [detail]                       disclosure]   |
///     | +------+                                              |
///     +-------------------------------------------------------+
/// ```
open class OCKSimpleContactView: OCKView, OCKContactDisplayable {

    // MARK: Properties

    /// An object that handles events related to a contact object.
    public weak var delegate: OCKContactViewDelegate?

    /// A vertical stack view that holds the main content in the view.
    public let contentStackView: OCKStackView = {
        let stackView = OCKStackView.vertical()
        stackView.distribution = .fill
        return stackView
    }()

    /// A header stack view that shows an icon image view and a separator.
    public let headerView = OCKHeaderView {
        $0.showsIconImage = true
        $0.showsDetailDisclosure = true
    }

    let contentView: OCKView = {
        let view = OCKView()
        view.clipsToBounds = true
        return view
    }()

    // A button that displays the highlighted state for the view.
    private lazy var backgroundButton = OCKAnimatedButton(contentView: contentStackView, highlightOptions: [.defaultOverlay, .defaultDelayOnSelect],
                                                          handlesSelection: false)

    // MARK: - Methods

    /// Prepares interface after initialization.
    override func setup() {
        super.setup()
        addSubviews()
        constrainSubviews()
        setupGestures()
        styleSubviews()
    }

    private func setupGestures() {
        backgroundButton.addTarget(self, action: #selector(viewTapped(_:)), for: .touchUpInside)
    }

    private func addSubviews() {
        addSubview(contentView)
        contentView.addSubview(backgroundButton)
        contentStackView.addArrangedSubview(headerView)
    }

    @objc
    private func viewTapped(_ sender: UIControl) {
        delegate?.didSelectContactView(self)
    }

    private func styleSubviews() {
        headerView.iconImageView?.image = UIImage(systemName: "person.crop.circle")
    }

    private func constrainSubviews() {
        [contentView, backgroundButton, contentStackView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate(
            contentView.constraints(equalTo: self) +
            backgroundButton.constraints(equalTo: contentView) +
            contentStackView.constraints(equalTo: backgroundButton.layoutMarginsGuide))
    }

    override open func styleDidChange() {
        super.styleDidChange()
        let style = self.style()
        let cardBuilder = OCKCardBuilder(cardView: self, contentView: contentView)
        cardBuilder.enableCardStyling(true, style: style)
        directionalLayoutMargins = style.dimension.directionalInsets1
        contentStackView.spacing = style.dimension.directionalInsets1.top
    }
}
#endif
