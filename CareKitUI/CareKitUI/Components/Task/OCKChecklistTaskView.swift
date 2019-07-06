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

/// Protocol for interactions with the `OCKChecklistTaskView`.
public protocol OCKChecklistTaskViewDelegate: class {
    
    /// Called when an item in the checklist was selected.
    ///
    /// - Parameters:
    ///   - checklistTaskView: The view containing the item.
    ///   - item: The item that was selected.
    ///   - index: The index of the item that was selected.
    func checklistTaskView(_ checklistTaskView: OCKChecklistTaskView, didSelectItem item: OCKButton, at index: Int)
}

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
open class OCKChecklistTaskView: UIView, OCKCardable, OCKCollapsible, OCKCollapsibleView {
  
    // MARK: OCKCollapsibleView
    
    internal var collapsedViews: Set<UIView> { [collapsedView, collapserButton] }
    internal var expandedViews: Set<UIView> { [headerView, instructionsLabel, checklistItemsStackView, instructionsLabel, spacerView] }
    internal var completeViews: Set<UIView> { [headerView, instructionsLabel, checklistItemsStackView, collapserButton, spacerView] }
    internal var cardView: UIView { return self }
    internal var collapsedState: OCKCollapsibleState = .expanded
    
    internal let collapserButton: OCKButton = {
        let collapserButton = OCKCollapserButton()
        collapserButton.isHidden = true
        collapserButton.alpha = 0
        return collapserButton
    }()
    
    /// The vertical stack view that contains the main content in the view.
    public let contentStackView: OCKStackView = {
        let stack = OCKStackView()
        stack.axis = .vertical
        return stack
    }()
    
    // MARK: Properties
    
    private let contentView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()
    
    private let spacerView = UIView()
    
    internal var shouldCollapse: Bool = true
    
    /// Listens for interactions with the `OCKChecklistTaskView`.
    public weak var delegate: OCKChecklistTaskViewDelegate?
    
    /// The header that shows a `detailDisclosureImage`.
    public let headerView = OCKHeaderView {
        $0.showsDetailDisclosure = true
    }
    
    /// Multi-line label beneath the checklist items.
    public let instructionsLabel: OCKLabel = {
        let label = OCKLabel(textStyle: .caption1, weight: .regular)
        label.textColor = .lightGray
        return label
    }()
    
    private let checklistItemsStackView: OCKStackView = {
        let stackView = OCKStackView(style: .separated)
        stackView.axis = .vertical
        return stackView
    }()
    
    internal let collapsedView: OCKCollapsedView = {
        let collapsedView = OCKCollapsedView()
        collapsedView.isHidden = true
        collapsedView.alpha = 0
        return collapsedView
    }()
    
    /// The buttons in the checklist.
    public var items: [OCKButton] {
        guard let items = checklistItemsStackView.arrangedSubviews as? [OCKButton] else { fatalError("Unsupported type.") }
        return items
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
        
        // setup targets for collapsing the view
        collapserButton.addTarget(self, action: #selector(toggleCollapse), for: .touchUpInside)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleCollapse))
        collapsedView.addGestureRecognizer(tapGesture)
    }
    
    private func styleSubviews() {
        preservesSuperviewLayoutMargins = true
        enableCardStyling(true)
        contentStackView.spacing = directionalLayoutMargins.top * 2
        contentStackView.setCustomSpacing(0, after: instructionsLabel)
        contentStackView.setCustomSpacing(0, after: spacerView)
    }
    
    private func addSubviews() {
        addSubview(contentView)
        contentView.addSubview(contentStackView)
        [headerView, checklistItemsStackView, instructionsLabel, spacerView, collapsedView, collapserButton].forEach {
            contentStackView.addArrangedSubview($0)
        }
    }
    
    private func constrainSubviews() {
        [contentView, contentStackView, spacerView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            spacerView.heightAnchor.constraint(equalToConstant: directionalLayoutMargins.top * 2),
            
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: directionalLayoutMargins.leading * 2),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -directionalLayoutMargins.leading * 2),
            contentView.topAnchor.constraint(equalTo: topAnchor, constant: directionalLayoutMargins.leading * 2),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    @objc
    private func toggleCollapse() {
        let newState: OCKCollapsibleState = collapsedState == .collapsed ? .complete : .collapsed
        setCollapsedState(newState, animated: true)
    }
    
    private func makeItem(withTitle title: String) -> OCKButton {
        let button = OCKChecklistItemButton()
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        button.setTitle(title, for: .normal)
        button.setTitle(title, for: .selected)
        return button
    }
    
    /// Update an item with text.
    ///
    /// - Parameters:
    ///   - index: The index of the item to update.
    ///   - title: The new text for the item.
    /// - Returns: The item that was modified.
    @discardableResult
    public func updateItem(at index: Int, withTitle title: String) -> OCKButton? {
        guard index < checklistItemsStackView.arrangedSubviews.count else { return nil }
        let button = items[index]
        button.setTitle(title, for: .normal)
        button.setTitle(title, for: .selected)
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
    public func insertItem(withTitle title: String, at index: Int, animated: Bool) -> OCKButton {
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
    public func appendItem(withTitle title: String, animated: Bool) -> OCKButton {
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
    public func removeItem(at index: Int, animated: Bool) -> OCKButton? {
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
    
    @objc
    private func buttonTapped(_ sender: OCKButton) {
        guard let index = checklistItemsStackView.arrangedSubviews.firstIndex(of: sender) else { return }    // should never happen
        delegate?.checklistTaskView(self, didSelectItem: sender, at: index)
    }
    
    // MARK: OCKCollapsible
    
    internal func setCollapsedState(_ state: OCKCollapsibleState, animated: Bool) {
        guard shouldCollapse else { return }
        setViewCollapsedState(state, animated: animated)
    }
}
