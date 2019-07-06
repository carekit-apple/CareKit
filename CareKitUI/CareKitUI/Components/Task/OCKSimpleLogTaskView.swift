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

/// Protocol for interactions with an `OCKSimpleLogTaskView`.
public protocol OCKSimpleLogTaskViewDelegate: class {
    
    /// Called when an item in the log was selected.
    ///
    /// - Parameters:
    ///   - simpleLogTaskView: The view containing the log item.
    ///   - item: The item in the log that was selected.
    ///   - index: The index of the item in the log.
    func simpleLogTaskView(_ simpleLogTaskView: OCKSimpleLogTaskView, didSelectItem item: OCKButton, at index: Int)
}

/// A card that displays a header, multi-line label, a log button, and a dynamic vertical stack of logged items.
/// In CareKit, this view is intended to display a particular event for a task. When the log button is presses,
/// a new outcome is created for the event.
///
/// To insert custom views vertically the view, see `contentStack`. To modify the logged items, see
/// `updateItem`, `appendItem`, `insertItem`, `removeItem` and `clearItems`.
///
///     +-------------------------------------------------------+
///     |                                                       |
///     | [title]                                [detail        |
///     | [detail]                               disclosure]    |
///     |                                                       |
///     |                                                       |
///     |  --------------------------------------------------   |
///     |                                                       |
///     |   [instructions]                                      |
///     |                                                       |
///     |  +-------------------------------------------------+  |
///     |  | [img]  [detail]  [title]                        |  |
///     |  +-------------------------------------------------+  |
///     |                                                       |
///     +-------------------------------------------------------+
///
open class OCKSimpleLogTaskView: UIView, OCKCardable {
    
    // MARK: Properties
    
    private enum Constants {
        static let spacing: CGFloat = 16
    }
    
    /// Delegate that gets notified of interactions with the `OCKSimpleLogTaskView`.
    public weak var delegate: OCKSimpleLogTaskViewDelegate?
    
    /// The list of buttons in the log.
    public var items: [OCKButton] {
        guard let buttons = logItemsStackView.arrangedSubviews as? [OCKButton] else { fatalError("Unsupported type.") }
        return buttons
    }
    
    private let logItemsStackView: OCKStackView = {
        var stackView = OCKStackView(style: .separated)
        stackView.showsOuterSeparators = false
        return stackView
    }()
    
    /// The button that can be hooked up to modify the list of logged items.
    public let logButton: OCKButton = {
        let button = OCKLabeledButton()
        button.animatesStateChanges = false
        button.setTitle(OCKStyle.strings.log, for: .normal)
        button.handlesSelectionStateAutomatically = false
        return button
    }()
    
    /// The vertical stack view that holds the main content for the view.
    public let contentStackView: OCKStackView = {
        let stack = OCKStackView()
        stack.axis = .vertical
        return stack
    }()
    
    /// Multi-line label below the header.
    public let instructionsLabel: OCKLabel = {
        let label = OCKLabel(textStyle: .subheadline, weight: .medium)
        label.numberOfLines = 0
        return label
    }()
    
    /// The header view that shows a separator and a `detailDisclosureImage`.
    public let headerView = OCKHeaderView {
        $0.showsSeparator = true
        $0.showsDetailDisclosure = true
    }
    
    // MARK: Life cycle
    
    public init() {
        super.init(frame: .zero)
        setup()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    // MARK: Methods
    
    private func setup() {
        addSubviews()
        styleSubviews()
        constrainSubviews()
    }
    
    private func styleSubviews() {
        preservesSuperviewLayoutMargins = true
        enableCardStyling(true)
        logItemsStackView.spacing = directionalLayoutMargins.top
        contentStackView.spacing = directionalLayoutMargins.top * 2
        setSpacingAfterLogButton(0, animated: false)
    }
    
    private func addSubviews() {
        addSubview(contentStackView)
        [headerView, instructionsLabel, logButton, logItemsStackView].forEach { contentStackView.addArrangedSubview($0) }
    }
    
    private func constrainSubviews() {
        [contentStackView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: directionalLayoutMargins.leading * 2),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -directionalLayoutMargins.trailing * 2),
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: directionalLayoutMargins.top * 2),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -directionalLayoutMargins.bottom * 2)
        ])
    }
    
    private func makeItem(withTitle title: String, detail: String) -> OCKLogItemButton {
        let button = OCKLogItemButton()
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        button.setTitle(title, for: .normal)
        button.setDetail(detail, for: .normal)
        return button
    }
    
    /// Update the text for an item at a particular index.
    ///
    /// - Parameters:
    ///   - index: The index of the item to update.
    ///   - title: The title text to display in the item.
    ///   - detail: The detail text to display in the item. The text is tinted by default.
    /// - Returns: The item that was updated.
    @discardableResult
    public func updateItem(at index: Int, withTitle title: String?, detail: String?) -> OCKButton? {
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
    public func insertItem(withTitle title: String, detail: String, at index: Int, animated: Bool) -> OCKButton {
        let button = makeItem(withTitle: title, detail: detail)
        if logItemsStackView.arrangedSubviews.isEmpty { setSpacingAfterLogButton(Constants.spacing, animated: true) }
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
    public func appendItem(withTitle title: String, detail: String, animated: Bool) -> OCKButton {
        let button = makeItem(withTitle: title, detail: detail)
        if logItemsStackView.arrangedSubviews.isEmpty { setSpacingAfterLogButton(Constants.spacing, animated: true) }
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
    public func removeItem(at index: Int, animated: Bool) -> OCKButton? {
        guard index < logItemsStackView.arrangedSubviews.count else { return nil }
        if logItemsStackView.arrangedSubviews.count == 1 { setSpacingAfterLogButton(0, animated: true) }
        let button = items[index]
        logItemsStackView.removeArrangedSubview(button, animated: animated)
        return button
    }

    /// Clear all items from the list of logged items.
    ///
    /// - Parameter animated: Animate clearing the items.
    public func clearItems(animated: Bool) {
        setSpacingAfterLogButton(0, animated: true)
        logItemsStackView.clear(animated: animated)
    }
    
    private func setSpacingAfterLogButton(_ spacing: CGFloat, animated: Bool) {
        let block = { [weak self] in
            guard let self = self else { return }
            self.contentStackView.setCustomSpacing(spacing, after: self.logButton)
        }
        
        animated ?
            UIView.animate(withDuration: OCKStyle.animation.stateChangeDuration, delay: 0,
                           options: .curveEaseOut, animations: block, completion: nil) :
            block()
    }
    
    @objc
    private func buttonTapped(_ sender: OCKButton) {
        guard let index = logItemsStackView.arrangedSubviews.firstIndex(of: sender) else {
            fatalError("Target was not set up properly.")
        }
        delegate?.simpleLogTaskView(self, didSelectItem: sender, at: index)
    }
}
