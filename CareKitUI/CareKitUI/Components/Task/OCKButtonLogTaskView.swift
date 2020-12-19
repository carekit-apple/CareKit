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

/// A card that displays a header, multi-line label, a collection of log buttons, and a dynamic vertical stack of logged items.
/// In CareKit, this view is intended to display a particular event for a task. When the log button is presses,
/// a new outcome is created for the event.
///
/// See `logButtonsCollectionView` to customize the layout or number of log buttons.
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
///     |   +-----------------------------------------------+   |
///     |   |                 [log button]                  |   |
///     |   +-----------------------------------------------+   |
///     |                                                       |
///     |   [img]  [detail]  [title]                            |
///     |   -------------------------------------------------   |
///     |   [img]  [detail]  [title]                            |
///     |   -------------------------------------------------   |
///     |   ...                                                 |
///     |   ...                                                 |
///     |   -------------------------------------------------   |
///     |   [img]  [detail]  [title]                            |
///     |                                                       |
///     +-------------------------------------------------------+
///
open class OCKButtonLogTaskView: OCKLogTaskView, UICollectionViewDelegate, UICollectionViewDataSource {

    private enum Constants {
        static let spacing: CGFloat = 16
        static let estimatedCellHeight: CGFloat = 44
    }

    // MARK: Properties

    /// The default cell type used for the `logButtonCollectionView`.
    public typealias DefaultCellType = OCKLogButtonCell

    /// The identifier used for the default cell in the `logButtonCollectionView`.
    public static let defaultCellIdentifier = "log-button-cell"

    /// Collection view holding the log buttons.
    public private (set) var logButtonsCollectionView: UICollectionView!

    /// Multi-line label below the header.
    public let instructionsLabel: OCKLabel = {
        let label = OCKLabel(textStyle: .subheadline, weight: .medium)
        label.numberOfLines = 0
        return label
    }()

    // MARK: Methods

    private func makeCollectionView() -> UICollectionView {
        let collectionView = OCKSelfSizingCollectionView(frame: .zero, collectionViewLayout: makeLayout())
        collectionView.backgroundColor = nil
        collectionView.register(OCKButtonLogTaskView.DefaultCellType.self, forCellWithReuseIdentifier: OCKButtonLogTaskView.defaultCellIdentifier)
        return collectionView
    }

    private func makeLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(Constants.estimatedCellHeight))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(Constants.estimatedCellHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = directionalLayoutMargins.top

        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }

    @objc
    private func didTapLogButton(_ sender: UIControl) {
        delegate?.taskView(self, didCreateOutcomeValueAt: 0, eventIndexPath: .init(row: 0, section: 0), sender: sender)
    }

    override func setup() {
        logButtonsCollectionView = makeCollectionView()
        logButtonsCollectionView.delegate = self
        logButtonsCollectionView.dataSource = self

        super.setup()
    }

    override func addSubviews() {
        super.addSubviews()
        [logButtonsCollectionView, instructionsLabel].forEach { contentStackView.insertArrangedSubview($0, at: 0) }
    }

    override open func styleDidChange() {
        super.styleDidChange()
        let cachedStyle = style()
        instructionsLabel.textColor = cachedStyle.color.label
        contentStackView.setCustomSpacing(cachedStyle.dimension.directionalInsets2.top, after: logButtonsCollectionView)
    }

    // MARK: - UICollectionViewDelegate & DataSource

    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }

    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OCKButtonLogTaskView.defaultCellIdentifier, for: indexPath)
        guard let typedCell = cell as? OCKButtonLogTaskView.DefaultCellType else { return cell }
        typedCell.logButton.addTarget(self, action: #selector(didTapLogButton(_:)), for: .touchUpInside)
        typedCell.logButton.label.text = loc("LOG")
        typedCell.isAccessibilityElement = true
        typedCell.accessibilityLabel = loc("LOG")
        typedCell.accessibilityHint = loc("DOUBLE_TAP_TO_RECORD_EVENT")
        typedCell.accessibilityTraits = .button
        return cell
    }
}
