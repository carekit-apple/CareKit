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
    // MARK: Properties

    let contentView = OCKView()

    private lazy var cardAssembler = OCKCardAssembler(cardView: self, contentView: contentView)

    /// The vertical stack view that holds the main content in the view.
    public let contentStackView: OCKStackView = {
        let stack = OCKStackView()
        stack.axis = .vertical
        return stack
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
    public let collectionView: UICollectionView = {
        let layout = OCKGridCollectionViewFlowLayout()
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize

        let collectionView = OCKSelfSizingCollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = nil
        collectionView.register(OCKGridTaskView.DefaultCellType.self, forCellWithReuseIdentifier: OCKGridTaskView.defaultCellIdentifier)
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()

    /// Multi-line label below the `collectionView`.
    public let instructionsLabel: OCKLabel = {
        let label = OCKLabel(textStyle: .caption1, weight: .regular)
        label.numberOfLines = 0
        return label
    }()

    // MARK: Methods

    override func setup() {
        super.setup()
        addSubviews()
        styleSubviews()
        constrainSubviews()
        setupGestures()
        collectionView.delegate = self
    }

    private func setupGestures() {
        let tappedViewGesture = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        headerView.addGestureRecognizer(tappedViewGesture)
    }

    private func addSubviews() {
        addSubview(contentView)
        contentView.addSubview(contentStackView)
        [headerView, collectionView, instructionsLabel].forEach { contentStackView.addArrangedSubview($0) }
    }

    private func styleSubviews() {
        contentStackView.setCustomSpacing(0, after: instructionsLabel)
    }

    private func constrainSubviews() {
        [contentView, contentStackView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate(
            contentStackView.constraints(equalTo: contentView) +
            contentView.constraints(equalTo: layoutMarginsGuide))
    }

    @objc
    private func didTapView() {
        delegate?.didSelectTaskView(self)
    }

    override open func styleDidChange() {
        super.styleDidChange()
        let cachedStyle = style()
        cardAssembler.enableCardStyling(true, style: cachedStyle)
        instructionsLabel.textColor = cachedStyle.color.secondaryLabel
        contentStackView.spacing = cachedStyle.dimension.directionalInsets1.top
        directionalLayoutMargins = cachedStyle.dimension.directionalInsets1

        let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        let spacing = cachedStyle.dimension.directionalInsets1.top
        layout?.minimumInteritemSpacing = spacing
        layout?.minimumLineSpacing = spacing
    }

    // MARK: - UICollectionViewDelegate

    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? OCKGridTaskView.DefaultCellType else {
            fatalError("Invalid cell type")
        }
        delegate?.taskView(self, didCompleteEvent: !cell.completionButton.isSelected, at: indexPath.row, sender: cell)
    }
}
