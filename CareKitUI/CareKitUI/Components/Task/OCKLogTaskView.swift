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

/// Base class for all log view. Shows an `OCKHeaderView` and a dynamic stack view of log items.
open class OCKLogTaskView: OCKView, OCKEventDisplayable {
    // MARK: Properties

    private let contentView: OCKView = {
        let view = OCKView()
        view.clipsToBounds = true
        return view
    }()

    private lazy var cardAssembler = OCKCardAssembler(cardView: self, contentView: contentView)

    /// Handles events related to an `OCKEventDisplayable` object.
    public weak var delegate: OCKEventViewDelegate?

    let logItemsStackView: OCKStackView = {
        var stackView = OCKStackView(style: .separated)
        stackView.showsOuterSeparators = false
        return stackView
    }()

    /// The vertical stack view that holds the main content for the view.
    public let contentStackView: OCKStackView = {
        let stack = OCKStackView()
        stack.axis = .vertical
        return stack
    }()

    /// The list of buttons in the log.
    open var items: [OCKButton] {
        guard let buttons = logItemsStackView.arrangedSubviews as? [OCKButton] else { fatalError("Unsupported type.") }
        return buttons
    }

    /// The header view that shows a separator and a `detailDisclosureImage`.
    public let headerView = OCKHeaderView {
        $0.showsSeparator = true
        $0.showsDetailDisclosure = true
    }

    // MARK: - Methods

    override func setup() {
        super.setup()
        addSubviews()
        constrainSubviews()
        setupGestures()
    }

    func addSubviews() {
        addSubview(contentView)
        contentView.addSubview(contentStackView)
        [headerView, logItemsStackView].forEach { contentStackView.addArrangedSubview($0) }
    }

    func constrainSubviews() {
        [contentView, contentStackView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate(
            contentStackView.constraints(equalTo: contentView) +
            contentView.constraints(equalTo: layoutMarginsGuide))
    }

    private func setupGestures() {
        let tappedViewGesture = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        headerView.addGestureRecognizer(tappedViewGesture)
    }

    override open func styleDidChange() {
        super.styleDidChange()
        let cachedStyle = style()
        cardAssembler.enableCardStyling(true, style: cachedStyle)
        contentStackView.spacing = cachedStyle.dimension.directionalInsets1.top
        directionalLayoutMargins = cachedStyle.dimension.directionalInsets1
    }

    /// Update the text for an item at a particular index.
    ///
    /// - Parameters:
    ///   - index: The index of the item to update.
    ///   - title: The title text to display in the item.
    ///   - detail: The detail text to display in the item. The text is tinted by default.
    /// - Returns: The item that was updated.
    @discardableResult
    open func updateItem(at index: Int, withTitle title: String?, detail: String?) -> OCKButton? {
        guard index < logItemsStackView.arrangedSubviews.count else { return nil }
        let button = items[index]
        button.setTitle(title, for: .normal)
        button.setDetail(detail, for: .normal)
        return button
    }

    /// Insert an item in the list of logged items.
    ///
    /// - Parameters:
    ///   - title: The title text to display in the item.
    ///   - detail: The detail text to display in the item. The text is tinted by default.
    ///   - index: The index to insert the item in the list of logged items.
    ///   - animated: Animate the insertion of the logged item.
    /// - Returns: The item that was inserted.
    @discardableResult
    open func insertItem(withTitle title: String?, detail: String?, at index: Int, animated: Bool) -> OCKButton {
        let button = makeItem(withTitle: title, detail: detail)
        logItemsStackView.insertArrangedSubview(button, at: index, animated: animated)
        return button
    }

    /// Append an item to the list of logged items.
    ///
    /// - Parameters:
    ///   - title: The detail text to display in the item. The text is tinted by default.
    ///   - detail: The detail text to display in the item. The text is tinted by default.
    ///   - animated: Animate appending the item.
    /// - Returns: The item that was appended.
    @discardableResult
    open func appendItem(withTitle title: String?, detail: String?, animated: Bool) -> OCKButton {
        let button = makeItem(withTitle: title, detail: detail)
        logItemsStackView.addArrangedSubview(button, animated: animated)
        return button
    }

    /// Remove an item from the list of logged items.
    ///
    /// - Parameters:
    ///   - index: The index of the item to remove.
    ///   - animated: Animate the removal of the item.
    /// - Returns: The item that was removed.
    @discardableResult
    open func removeItem(at index: Int, animated: Bool) -> OCKButton? {
        guard index < logItemsStackView.arrangedSubviews.count else { return nil }
        let button = items[index]
        logItemsStackView.removeArrangedSubview(button, animated: animated)
        return button
    }

    /// Clear all items from the list of logged items.
    ///
    /// - Parameter animated: Animate clearing the items.
    open func clearItems(animated: Bool) {
        logItemsStackView.clear(animated: animated)
    }

    private func makeItem(withTitle title: String?, detail: String?) -> OCKLogItemButton {
        let button = OCKLogItemButton()
        button.addTarget(self, action: #selector(itemTapped(_:)), for: .touchUpInside)
        button.setTitle(title, for: .normal)
        button.setDetail(detail, for: .normal)
        return button
    }

    @objc
    private func didTapView() {
        delegate?.didSelectEventView(self)
    }

    @objc
    private func itemTapped(_ sender: OCKButton) {
        guard let index = logItemsStackView.arrangedSubviews.firstIndex(of: sender) else {
            fatalError("Target was not set up properly.")
        }
        delegate?.eventView(self, didSelectOutcomeValueAt: index, sender: sender)
    }
}
