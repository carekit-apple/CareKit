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

/// A card that displays a vertically stacked checklist of items. In CareKit, this view is intended to display
/// multiple events for a particular task.
///
/// To insert custom views vertically the view, see `contentStack`. The header is an `OCKHeaderView`. The body has a
/// stack of checklist items and an instructions label underneath. To access the checklist item buttons, for instance
/// to hook them up to target actions, see the `items` array. To modify the checklist, see
/// `updateItem`, `appendItem`, `insertItem`, `removeItem` and `clearItems`.
///
///     +-------------------------------------------------------+
///     | +------+                                              |
///     | | icon | [title]                       [detail        |
///     | | img  | [detail]                       disclosure]   |
///     | +------+                                              |
///     |                                                       |
///     |  --------------------------------------------------   |
///     |                                                       |
///     |  +-------------------------------------------------+  |
///     |  | [title]                                   [img] |  |
///     |  +-------------------------------------------------+  |
///     |  +-------------------------------------------------+  |
///     |  | [title]                                   [img] |  |
///     |  +-------------------------------------------------+  |
///     |                         .                             |
///     |                         .                             |
///     |                         .                             |
///     |  +-------------------------------------------------+  |
///     |  | [title]                                   [img] |  |
///     |  +-------------------------------------------------+  |
///     |                                                       |
///     |  [instructions]                                       |
///     +-------------------------------------------------------+
///
open class OCKChecklistTaskView: OCKView, OCKTaskDisplayable {

    // MARK: Properties

    let contentView: OCKView = {
        let view = OCKView()
        view.clipsToBounds = true
        return view
    }()

    private let checklistItemsStackView: OCKStackView = {
        let stackView = OCKStackView(style: .separated)
        stackView.axis = .vertical
        return stackView
    }()

    private let headerStackView = OCKStackView.vertical()

    private lazy var headerButton = OCKAnimatedButton(contentView: headerView, highlightOptions: [.defaultDelayOnSelect, .defaultOverlay],
                                                      handlesSelection: false)

    /// The vertical stack view that holds the main content in the view.
    public let contentStackView: OCKStackView = {
        let stackView = OCKStackView.vertical()
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()

    /// Handles events related to an `OCKTaskDisplayable` object.
    public weak var delegate: OCKTaskViewDelegate?

    /// The header that shows a `detailDisclosureImage`.
    public let headerView = OCKHeaderView {
        $0.showsDetailDisclosure = true
    }

    /// Multi-line label beneath the checklist items.
    public let instructionsLabel: OCKLabel = {
        let label = OCKLabel(textStyle: .caption1, weight: .regular)
        label.numberOfLines = 0
        return label
    }()

    /// The buttons in the checklist.
    public var items: [OCKChecklistItemButton] {
        guard let items = checklistItemsStackView.arrangedSubviews as? [OCKChecklistItemButton] else { fatalError("Unsupported type.") }
        return items
    }

    // MARK: Methods

    override func setup() {
        super.setup()
        addSubviews()
        constrainSubviews()
        styleSubviews()
        setupGestures()
    }

    private func setupGestures() {
        headerButton.addTarget(self, action: #selector(didTapView), for: .touchUpInside)
    }

    private func styleSubviews() {
        contentStackView.setCustomSpacing(0, after: instructionsLabel)
    }

    private func addSubviews() {
        addSubview(contentView)
        contentView.addSubview(headerStackView)
        [headerButton, contentStackView].forEach { headerStackView.addArrangedSubview($0) }
        [checklistItemsStackView, instructionsLabel].forEach { contentStackView.addArrangedSubview($0) }
    }

    private func constrainSubviews() {
        [contentView, headerStackView, headerView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate(
            contentView.constraints(equalTo: self) +
            headerStackView.constraints(equalTo: contentView) +
            headerView.constraints(equalTo: headerButton.layoutMarginsGuide))
    }

    @objc
    private func didTapView() {
        delegate?.didSelectTaskView(self, eventIndexPath: .init(row: 0, section: 0))
    }

    @objc
    private func eventButtonTapped(_ sender: UIControl) {
        guard let row = checklistItemsStackView.arrangedSubviews.firstIndex(of: sender) else {
            fatalError("Invalid index")
        }
        delegate?.taskView(self, didCompleteEvent: !sender.isSelected, at: .init(row: row, section: 0), sender: sender)
    }

    private func makeItem(withTitle title: String) -> OCKChecklistItemButton {
        let button = OCKChecklistItemButton()
        button.addTarget(self, action: #selector(eventButtonTapped(_:)), for: .touchUpInside)
        button.label.text = title
        button.accessibilityLabel = title
        return button
    }

    /// Update an item with text.
    ///
    /// - Parameters:
    ///   - index: The index of the item to update.
    ///   - title: The new text for the item.
    /// - Returns: The item that was modified.
    @discardableResult
    public func updateItem(at index: Int, withTitle title: String) -> OCKChecklistItemButton? {
        guard index < checklistItemsStackView.arrangedSubviews.count else { return nil }
        let button = items[index]
        button.label.text = title
        return button
    }

    /// Insert an item in the checklist.
    ///
    /// - Parameters:
    ///   - title: The text displayed in the item.
    ///   - index: The index at which to insert the item.
    ///   - animated: Animate the insertion of the view.
    /// - Returns: The item that was inserted.
    @discardableResult
    public func insertItem(withTitle title: String, at index: Int, animated: Bool) -> OCKChecklistItemButton {
        let button = makeItem(withTitle: title)
        checklistItemsStackView.insertArrangedSubview(button, at: index, animated: animated)
        return button
    }

    /// Append an item to the checklist.
    ///
    /// - Parameters:
    ///   - title: The text displayed in the item.
    ///   - animated: Animate the appending of the view.
    /// - Returns: The view that was appended.
    @discardableResult
    public func appendItem(withTitle title: String, animated: Bool) -> OCKChecklistItemButton {
        let button = makeItem(withTitle: title)
        checklistItemsStackView.addArrangedSubview(button, animated: animated)
        return button
    }

    /// Remove an item from the checkliist.
    ///
    /// - Parameters:
    ///   - index: The index for which to remove the item.
    ///   - animated: Animate the removal of the item.
    /// - Returns: The item that was removed from the checklist.
    @discardableResult
    public func removeItem(at index: Int, animated: Bool) -> OCKChecklistItemButton? {
        guard index < checklistItemsStackView.arrangedSubviews.count else { return nil }
        let button = items[index]
        checklistItemsStackView.removeArrangedSubview(button, animated: animated)
        return button
    }

    /// Clear all items from the checklist.
    ///
    /// - Parameter animated: Animate the removal of the items from the checklist.
    public func clearItems(animated: Bool) {
        checklistItemsStackView.clear(animated: animated)
    }

    override open func styleDidChange() {
        super.styleDidChange()
        let style = self.style()
        let cardBuilder = OCKCardBuilder(cardView: self, contentView: contentView)
        cardBuilder.enableCardStyling(true, style: style)
        instructionsLabel.textColor = style.color.secondaryLabel
        directionalLayoutMargins = style.dimension.directionalInsets1
        contentStackView.spacing = style.dimension.directionalInsets1.top
        contentStackView.directionalLayoutMargins = .init(top: 0,
                                                          leading: style.dimension.directionalInsets1.leading,
                                                          bottom: style.dimension.directionalInsets1.bottom,
                                                          trailing: style.dimension.directionalInsets1.trailing)
    }
}
