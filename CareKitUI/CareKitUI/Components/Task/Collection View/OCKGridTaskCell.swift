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
open class OCKGridTaskCell: UICollectionViewCell {

    // MARK: Properties

    /// Circular button that shows an image and label. The default image is a checkmark when selected.
    /// The text for the deselected state will automatically adapt to the `tintColor`.
    public let completionButton = OCKLabeledCheckmarkButton()

    // MARK: Life cycle

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: Methods

    override open func prepareForReuse() {
        super.prepareForReuse()
        completionButton.isSelected = false
        completionButton.label.text = nil
        accessibilityLabel = nil
        accessibilityValue = nil
    }

    private func setup() {
        addSubviews()
        constrainSubviews()
        completionButton.isEnabled = false
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    private func addSubviews() {
        contentView.addSubview(completionButton)
    }

    private func constrainSubviews() {
        completionButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(
            completionButton.constraints(equalTo: contentView, directions: [.top, .leading]) +
            completionButton.constraints(equalTo: contentView, directions: [.bottom, .trailing], priority: .almostRequired)
        )
    }
}
