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

/// A card that displays a header, multi-line label, and a completion button. In CareKit, this view is
/// intended to display a particular event for a task. The state of the completion button indicates
/// the completion state of the event.
///
/// To insert custom views vertically the view, see `contentStack`
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
///     |  |                    [title]                      |  |
///     |  +-------------------------------------------------+  |
///     |                                                       |
///     +-------------------------------------------------------+
///
open class OCKInstructionsTaskView: UIView, OCKCardable, OCKCollapsible, OCKCollapsibleView {
    
    // MARK: OCKCollapsibleView
    
    internal var collapsedViews: Set<UIView> { [collapsedView, collapserButton] }
    internal var expandedViews: Set<UIView> { [headerView, instructionsLabel, completionButton, spacerView] }
    internal var completeViews: Set<UIView> { [headerView, instructionsLabel, completionButton, collapserButton, spacerView] }
    internal var cardView: UIView { return self }
    internal var collapsedState: OCKCollapsibleState = .expanded
    
    internal let collapserButton: OCKButton = {
        let collapserButton = OCKCollapserButton()
        collapserButton.isHidden = true
        collapserButton.alpha = 0
        return collapserButton
    }()
    
    /// A vertical stack view that holds the main content for the view.
    public let contentStackView: OCKStackView = {
        let stack = OCKStackView()
        stack.axis = .vertical
        return stack
    }()
    
    // MARK: Properties
    
    private enum Constants {
        static let bundle = Bundle(for: OCKInstructionsTaskView.self)
    }
    
    internal var shouldCollapse: Bool = true
    
    internal let collapsedView: OCKCollapsedView = {
        let collapsedView = OCKCollapsedView()
        collapsedView.isHidden = true
        collapsedView.alpha = 0
        return collapsedView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()
    
    private let spacerView = UIView()
    
    /// The button on the bottom of the view. The background color is the `tintColor` when in a normal state. and gray when
    /// in a selected state. Also supports a `titleLabel`.
    public let completionButton: OCKButton = OCKLabeledButton()
    
    /// Multi-line label over the `completionButton`.
    public let instructionsLabel: OCKLabel = {
        let label = OCKLabel(textStyle: .subheadline, weight: .medium)
        label.numberOfLines = 0
        return label
    }()
    
    /// A header view that tshows a separator and a `detailDisclosureImage`.
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
        
        // setup targets for collapsing the view
        collapserButton.addTarget(self, action: #selector(toggleCollapse), for: .touchUpInside)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleCollapse))
        collapsedView.addGestureRecognizer(tapGesture)
    }
    
    private func styleSubviews() {
        preservesSuperviewLayoutMargins = true
        enableCardStyling(true)
        contentStackView.spacing = directionalLayoutMargins.top * 2
        contentStackView.setCustomSpacing(0, after: completionButton)
        contentStackView.setCustomSpacing(0, after: spacerView)
    }
    
    private func addSubviews() {
        addSubview(contentView)
        contentView.addSubview(contentStackView)
        [headerView, instructionsLabel, completionButton,
         spacerView, collapsedView, collapserButton].forEach { contentStackView.addArrangedSubview($0) }
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
    
    // MARK: OCKCollapsible
    
    internal func setCollapsedState(_ state: OCKCollapsibleState, animated: Bool) {
        guard shouldCollapse else { return }
        setViewCollapsedState(state, animated: animated)
    }
}
