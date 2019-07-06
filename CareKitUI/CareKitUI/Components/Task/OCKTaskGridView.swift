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

/// A card that displays a header, grid of buttons, and a multi-line label In CareKit, this view is intended to display
/// multiple events for a particular task. The state of each button in the grid indicates the completion state of the
/// corresponding event.
///
/// To insert custom views vertically the view, see `contentStack`. To modify the data in the grid, set a `dataSource`
/// for the `collectionView`.
///
///     +-------------------------------------------------------+
///     |                                                       |
///     |  [title]                               [detail        |
///     |  [detail]                              disclosure]    |
///     |                                                       |
///     |                                                       |
///     |  --------------------------------------------------   |
///     |     o o      o o      o o                     o o     |
///     |    o   o    o   o    o   o        ...        o   o    |
///     |     o o      o o      o o                     o o     |
///     |                                                       |
///     |   [instructions]                                      |
///     +-------------------------------------------------------+
///
open class OCKTaskGridView: UIView, OCKCardable, OCKCollapsible, OCKCollapsibleView {
    
    // MARK: OCKCollapsibleView
    
    internal var collapsedViews: Set<UIView> { [collapsedView, collapserButton] }
    internal var expandedViews: Set<UIView> { [headerView, instructionsLabel, collectionView, spacerView] }
    internal var completeViews: Set<UIView> { [headerView, instructionsLabel, collectionView, collapserButton, spacerView] }
    internal var cardView: UIView { return self }
    internal var collapsedState: OCKCollapsibleState = .expanded
    
    internal let collapserButton: OCKButton = {
        let collapserButton = OCKCollapserButton()
        collapserButton.isHidden = true
        collapserButton.alpha = 0
        return collapserButton
    }()

    /// The vertical stack view that holds the main content in the view.
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
    
    internal var shouldCollapse: Bool = true
    
    private let spacerView = UIView()
    
    internal let collapsedView: OCKCollapsedView = {
        let collapsedView = OCKCollapsedView()
        collapsedView.isHidden = true
        collapsedView.alpha = 0
        return collapsedView
    }()
    
    /// A header view that shows a separator and a `detailDisclosureImage`.
    public let headerView = OCKHeaderView {
        $0.showsSeparator = true
        $0.showsDetailDisclosure = true
    }
    
    /// The default cell identifier that is registered for the collection view.
    public let defaultCellIdentifier = "outcome-value"
    
    /// The default cell type that is used for the `collectionView`.
    public typealias DefaultCellType = OCKGridTaskCell
    
    /// A collection view that sizes itself based on the size of it's content. Cells used should have a constant width constraint. The
    /// default cell that is used is an `OCKTaskGridView.DefaultCellType` (`OCKGridTaskCell`). Set a data source to control the content
    /// of the grid.
    public let collectionView: UICollectionView = {
        let layout = OCKGridCollectionViewFlowLayout()
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        
        let collectionView = OCKSelfSizingCollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()
    
    /// Multi-line label below the `collectionView`.
    public let instructionsLabel: OCKLabel = {
        let label = OCKLabel(textStyle: .caption1, weight: .regular)
        label.textColor = .lightGray
        return label
    }()
    
    // MARK: Life Cycle
    
    public init() {
        super.init(frame: .zero)
        setup()
    }
    
    public required init?(coder: NSCoder) {
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
        
        collectionView.register(DefaultCellType.self, forCellWithReuseIdentifier: defaultCellIdentifier)
    }
    
    private func addSubviews() {
        addSubview(contentView)
        contentView.addSubview(contentStackView)
        [headerView, collectionView, instructionsLabel,
         spacerView, collapsedView, collapserButton].forEach { contentStackView.addArrangedSubview($0) }
    }

    private func styleSubviews() {
        preservesSuperviewLayoutMargins = true
        enableCardStyling(true)

        let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        layout?.minimumInteritemSpacing = directionalLayoutMargins.top * 1.5
        layout?.minimumLineSpacing = directionalLayoutMargins.top * 1.5

        contentStackView.spacing = directionalLayoutMargins.top * 2
        contentStackView.setCustomSpacing(0, after: instructionsLabel)
        contentStackView.setCustomSpacing(0, after: spacerView)
    }

    private func constrainSubviews() {
        [contentView, contentStackView, spacerView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            spacerView.heightAnchor.constraint(equalToConstant: directionalLayoutMargins.top * 2),

            contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: directionalLayoutMargins.leading * 2),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -directionalLayoutMargins.leading * 2),
            contentView.topAnchor.constraint(equalTo: topAnchor, constant: directionalLayoutMargins.leading * 2),
            bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: contentStackView.bottomAnchor)
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
