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
open class OCKLogTaskView: OCKView, OCKTaskDisplayable {

    // MARK: Properties

    private let contentView: OCKView = {
        let view = OCKView()
        view.clipsToBounds = true
        return view
    }()

    private lazy var headerButton = OCKAnimatedButton(contentView: headerView, highlightOptions: [.defaultDelayOnSelect, .defaultOverlay],
                                                      handlesSelection: false)

    private let headerStackView = OCKStackView.vertical()

    let logItemsStackView: OCKStackView = {
        var stackView = OCKStackView(style: .separated)
        stackView.showsOuterSeparators = false
        return stackView
    }()

    /// A vertical stack view that holds the main content for the view.
    public let contentStackView: OCKStackView = {
        let stack = OCKStackView.vertical()
        stack.isLayoutMarginsRelativeArrangement = true
        return stack
    }()

    /// Handles events related to an `OCKTaskDisplayable` object.
    public weak var delegate: OCKTaskViewDelegate?

    /// The header view that shows a separator and a `detailDisclosureImage`.
    public let headerView = OCKHeaderView {
        $0.showsSeparator = true
        $0.showsDetailDisclosure = true
    }

    /// The list of buttons in the log.
    open var items: [OCKLogItemButton] {
        guard let buttons = logItemsStackView.arrangedSubviews as? [OCKLogItemButton] else { fatalError("Unsupported type.") }
        return buttons
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
        contentView.addSubview(headerStackView)
        [headerButton, contentStackView].forEach { headerStackView.addArrangedSubview($0) }
        [logItemsStackView].forEach { contentStackView.addArrangedSubview($0) }
    }

    func constrainSubviews() {
        [contentView, headerStackView, headerView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate(
            contentView.constraints(equalTo: self) +
            headerStackView.constraints(equalTo: contentView) +
            headerView.constraints(equalTo: headerButton.layoutMarginsGuide, directions: [.horizontal, .top]) +
            headerView.constraints(equalTo: headerButton, directions: [.bottom]))
    }

    private func setupGestures() {
        headerButton.addTarget(self, action: #selector(didTapView), for: .touchUpInside)
    }

    private func makeItem(withTitle title: String?, detail: String?) -> OCKLogItemButton {
        let button = OCKLogItemButton()
        button.addTarget(self, action: #selector(itemTapped(_:)), for: .touchUpInside)
        button.titleLabel.text = title
        button.detailLabel.text = detail
        button.accessibilityLabel = (detail ?? "") + " " + (title ?? "")
        button.accessibilityHint = loc("DOUBLE_TAP_TO_REMOVE_EVENT")
        return button
    }

    @objc
    private func didTapView() {
        delegate?.didSelectTaskView(self, eventIndexPath: .init(row: 0, section: 0))
    }

    @objc
    private func itemTapped(_ sender: UIControl) {
        guard let index = logItemsStackView.arrangedSubviews.firstIndex(of: sender) else {
            fatalError("Target was not set up properly.")
        }
        delegate?.taskView(self, didSelectOutcomeValueAt: index, eventIndexPath: .init(row: 0, section: 0), sender: sender)
    }

    override open func styleDidChange() {
        super.styleDidChange()
        let style = self.style()
        let cardBuilder = OCKCardBuilder(cardView: self, contentView: contentView)
        cardBuilder.enableCardStyling(true, style: style)
        contentStackView.spacing = style.dimension.directionalInsets1.top
        directionalLayoutMargins = style.dimension.directionalInsets1
        contentStackView.directionalLayoutMargins = style.dimension.directionalInsets1
    }

    /// Update the text for an item at a particular index.
    ///
    /// - Parameters:
    ///   - index: The index of the item to update.
    ///   - title: The title text to display in the item.
    ///   - detail: The detail text to display in the item. The text is tinted by default.
    /// - Returns: The item that was updated.
    @discardableResult
    open func updateItem(at index: Int, withTitle title: String?, detail: String?) -> OCKLogItemButton? {
        guard index < logItemsStackView.arrangedSubviews.count else { return nil }
        let button = items[index]
        button.accessibilityLabel = title
        button.titleLabel.text = title
        button.detailLabel.text = detail
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
    open func insertItem(withTitle title: String?, detail: String?, at index: Int, animated: Bool) -> OCKLogItemButton {
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
    open func appendItem(withTitle title: String?, detail: String?, animated: Bool) -> OCKLogItemButton {
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
    open func removeItem(at index: Int, animated: Bool) -> OCKLogItemButton? {
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
}
