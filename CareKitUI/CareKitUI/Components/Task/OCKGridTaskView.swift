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
open class OCKGridTaskView: OCKView, OCKTaskDisplayable, UICollectionViewDelegate {

    private enum Constants {
        static let estimatedItemHeight: CGFloat = 70
        static let estimatedItemWidth: CGFloat = 80
    }

    // MARK: Properties

    /// The vertical stack view that holds the main content in the view.
    public let contentStackView: OCKStackView = {
        let stackView = OCKStackView.vertical()
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()

    /// Handles events related to an `OCKTaskDisplayable` object.
    public weak var delegate: OCKTaskViewDelegate?

    /// A header view that shows a separator and a `detailDisclosureImage`.
    public let headerView = OCKHeaderView {
        $0.showsSeparator = true
        $0.showsDetailDisclosure = true
    }

    /// The default cell identifier that is registered for the collection view.
    public static let defaultCellIdentifier = "outcome-value"

    /// The default cell type that is used for the `collectionView`.
    public typealias DefaultCellType = OCKGridTaskCell

    /// A collection view that sizes itself based on the size of its content. Cells used should have a constant width constraint. The
    /// default cell that is used is an `OCKGridTaskView.DefaultCellType` (`OCKGridTaskCell`). Set a data source to control the content
    /// of the grid.
    public private(set) lazy var collectionView: UICollectionView = {
        let collectionView = OCKSelfSizingCollectionView(frame: .zero, collectionViewLayout: makeLayout())
        collectionView.register(OCKGridTaskView.DefaultCellType.self, forCellWithReuseIdentifier: OCKGridTaskView.defaultCellIdentifier)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delegate = self
        collectionView.backgroundColor = nil
        return collectionView
    }()

    /// Multi-line label below the `collectionView`.
    public let instructionsLabel: OCKLabel = {
        let label = OCKLabel(textStyle: .caption1, weight: .regular)
        label.numberOfLines = 0
        return label
    }()

    let contentView: OCKView = {
        let view = OCKView()
        view.clipsToBounds = true
        return view
    }()

    private let headerStackView = OCKStackView.vertical()

    private lazy var headerButton = OCKAnimatedButton(contentView: headerView, highlightOptions: [.defaultDelayOnSelect, .defaultOverlay],
                                                      handlesSelection: false)

    // MARK: Methods

    override func setup() {
        super.setup()
        addSubviews()
        constrainSubviews()
        setupGestures()
    }

    // Find the horizontal margin for a grid given the parameters.
    func horizontalMargin(forContainerWidth containerWidth: CGFloat, itemWidth: CGFloat, interItemSpacing: CGFloat, itemCount: Int) -> CGFloat {
        var margin = containerWidth
        var columns: Int = 0
        // Find the optimal column count by increasing the columns while minimizing the margin.
        while margin >= 0 {

            // Equation derived from:
            // containerWidth = margin + spacingBetweenItems + widthOfAllItems
            // Note: This equation ensure the margin decreases at each loop step
            var newMargin = -containerWidth + (interItemSpacing * max(columns - 1, 0).float) + (itemWidth * columns.float)
            newMargin.negate()

            // If the new margin has gone negative, the current margin is the minimum
            if newMargin < 0 { return margin }

            // If we do not have enough items to fill more columns, stop early
            if itemCount <= columns { return newMargin }

            margin = newMargin  // Store the new minimum
            columns += 1        // Increase the columns and try to further minimize the margin
        }
        return margin
    }

    private func setupGestures() {
        headerButton.addTarget(self, action: #selector(didTapView), for: .touchUpInside)
    }

    private func addSubviews() {
        addSubview(contentView)
        contentView.addSubview(headerStackView)
        [headerButton, contentStackView].forEach { headerStackView.addArrangedSubview($0) }
        [collectionView, instructionsLabel].forEach { contentStackView.addArrangedSubview($0) }
    }

    private func constrainSubviews() {
        [contentView, headerStackView, headerView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate(
            contentView.constraints(equalTo: self) +
            headerStackView.constraints(equalTo: contentView) +
            headerView.constraints(equalTo: headerButton.layoutMarginsGuide, directions: [.horizontal, .top]) +
            headerView.constraints(equalTo: headerButton, directions: [.bottom]))
    }

    private func makeLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] _, configuration in
            guard let self = self else { return nil }
            let spacing = self.style().dimension.directionalInsets2.trailing

            // Scale the item dimensions based on the content size category
            let scaledHeight = Constants.estimatedItemHeight.scaled()
            let scaledWidth = Constants.estimatedItemWidth.scaled()

            let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(scaledWidth), heightDimension: .absolute(scaledHeight))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(scaledHeight))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            group.interItemSpacing = .fixed(spacing)

            let containerWidth = configuration.container.effectiveContentSize.width
            let itemCount = self.collectionView.dataSource?.collectionView(self.collectionView, numberOfItemsInSection: 0) ?? 0
            // Create margins to center the content in the container
            let margin = self.horizontalMargin(forContainerWidth: containerWidth, itemWidth: scaledWidth,
                                               interItemSpacing: spacing, itemCount: itemCount)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = spacing
            section.contentInsets = .init(top: 0, leading: margin / 2.0, bottom: 0, trailing: margin / 2.0)
            return section
        }
        return layout
    }

    @objc
    private func didTapView() {
        delegate?.didSelectTaskView(self, eventIndexPath: .init(row: 0, section: 0))
    }

    @objc
    private func didTapCompletionButton(_ sender: UIControl) {
        // Find the index path for the tapped button
        collectionView.indexPathsForVisibleItems.forEach {
            let cell = collectionView.cellForItem(at: $0) as? OCKGridTaskView.DefaultCellType
            if cell?.completionButton === sender {
                delegate?.taskView(self, didCompleteEvent: !sender.isSelected, at: $0, sender: sender)
                return
            }
        }
    }

    private func resetCollectionViewSizing() {
        collectionView.collectionViewLayout.invalidateLayout()  // To reset the margins and item spacing
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            resetCollectionViewSizing()
        }
    }

    override open func styleDidChange() {
        super.styleDidChange()
        let style = self.style()
        let cardBuilder = OCKCardBuilder(cardView: self, contentView: contentView)
        cardBuilder.enableCardStyling(true, style: style)
        instructionsLabel.textColor = style.color.secondaryLabel
        contentStackView.spacing = style.dimension.directionalInsets1.top
        directionalLayoutMargins = style.dimension.directionalInsets1
        contentStackView.directionalLayoutMargins = style.dimension.directionalInsets1
        resetCollectionViewSizing()
    }

    // MARK: - UICollectionViewDelegate

    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? OCKGridTaskView.DefaultCellType else { return }
        // Assume the action is successfull and toggle the selected state
        cell.completionButton.isSelected.toggle()
        // Notify the delegate that an event has been toggled
        delegate?.taskView(self, didCompleteEvent: cell.completionButton.isSelected, at: indexPath, sender: cell.completionButton)
    }
}

private extension Int {
    var float: CGFloat { return CGFloat(self) }
}
