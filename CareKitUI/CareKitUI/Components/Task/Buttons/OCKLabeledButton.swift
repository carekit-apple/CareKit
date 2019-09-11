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

/// A button with a filled background color.
///
///     +--------------------------+
///     |         [Title]          |
///     +--------------------------+
///
class OCKLabeledButton: OCKButton {
    // MARK: Properties

    override var titleButton: OCKButton? { _titleButton }

    private let _titleButton: OCKButton = {
        let button = OCKButton(titleTextStyle: .subheadline, titleWeight: .medium)
        button.isUserInteractionEnabled = false
        button.tintedTraits = [TintedTrait(trait: .titleColor, state: .selected)]
        button.sizesToFitTitleLabel = true

        button.setTitle(OCKStrings.markCompleted, for: .normal)
        button.setTitle(OCKStrings.completed, for: .selected)

        return button
    }()

    // MARK: Methods

    override func setup() {
        super.setup()
        addSubviews()
        constrainSubviews()
        styleSubviews()
    }

    private func addSubviews() {
        addSubview(_titleButton)
    }

    private func styleSubviews() {
        animatesStateChanges = true
        adjustsImageWhenHighlighted = false
        clipsToBounds = true
        tintedTraits = [TintedTrait(trait: .backgroundColor, state: .normal)]
    }

    private func constrainSubviews() {
        _titleButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(_titleButton.constraints(equalTo: layoutMarginsGuide))
    }

    override func styleDidChange() {
        super.styleDidChange()
        let cachedStyle = style()
        _titleButton.setTitleColor(cachedStyle.color.white, for: .normal)
        layer.cornerRadius = cachedStyle.appearance.cornerRadius2
        setBackgroundColor(cachedStyle.color.tertiarySystemFill, for: .selected)
        directionalLayoutMargins = cachedStyle.dimension.directionalInsets1
    }
}
