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

/// A cell used in the `collectionView` of the `OCKGridTaskView`. The cell shows a circular `completionButton` that has an image and a
/// `titleLabel`. The default image is a checkmark.
open class OCKGridTaskCell: UICollectionViewCell, OCKStylable {
    // MARK: Properties

    private var completionButtonRingWidthConstraint: NSLayoutConstraint?

    public var customStyle: OCKStyler? {
        didSet { styleChildren() }
    }

    /// Circular button that shows an image and `titleLabel`. The default image is a checkmark when selected.
    /// The text for the `.normal` state will automatically adapt to the `tintColor`.
    public let completionButton: OCKButton = {
        let button = OCKLabeledCircleButton()
        button.isUserInteractionEnabled = false
        return button
    }()

    // MARK: Life cycle

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override open func prepareForReuse() {
        super.prepareForReuse()
        completionButton.isSelected = false
        completionButton.setTitle(nil, for: .normal)
        completionButton.setTitle(nil, for: .selected)
    }

    // MARK: Methods

    override open func tintColorDidChange() {
        completionButton.setTitleColor(tintColor, for: .normal)
    }

    private func setup() {
        styleSubviews()
        addSubviews()
        constrainSubviews()
    }

    private func styleSubviews() {
        preservesSuperviewLayoutMargins = true
        tintColorDidChange()
        styleDidChange()
    }

    private func addSubviews() {
        contentView.addSubview(completionButton)
    }

    private func constrainSubviews() {
        [contentView, completionButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        completionButtonRingWidthConstraint = completionButton.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            completionButtonRingWidthConstraint!,
            completionButton.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor),
            completionButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            completionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: completionButton.bottomAnchor),

            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(greaterThanOrEqualTo: trailingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            bottomAnchor.constraint(greaterThanOrEqualTo: contentView.bottomAnchor)
        ])
    }

    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        styleDidChange()
    }

    override open func removeFromSuperview() {
        super.removeFromSuperview()
        styleChildren()
    }

    public func styleDidChange() {
        let cachedStyle = style()
        completionButtonRingWidthConstraint?.constant = cachedStyle.dimension.buttonHeight1
        (completionButton as? OCKCompletionRingButton)?.ring.lineWidth = cachedStyle.appearance.borderWidth2
    }
}
