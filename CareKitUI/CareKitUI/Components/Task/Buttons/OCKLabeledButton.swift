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
open class OCKLabeledButton: OCKAnimatedButton<OCKLabel> {

    // MARK: Properties

    /// Label in the center of the buttton.
    public let label: OCKLabel = {
        let label = OCKLabel(textStyle: .subheadline, weight: .medium)
        label.text = loc("MARK_COMPLETE")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // MARK: Life Cycle

    public init() {
        super.init(contentView: label, handlesSelection: true)
        constrainSubviews()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Methods

    override open func setStyleForSelectedState(_ isSelected: Bool) {
        let completionString = isSelected ? loc("COMPLETED") : loc("MARK_COMPLETE")
        let attributedText = NSMutableAttributedString(string: completionString)

        // Set a checkmark next to the text if the button is in the completed state
        if isSelected, let checkmark = UIImage.from(systemName: "checkmark") {
            let attachment = NSTextAttachment(image: checkmark)
            let checkmarkString = NSAttributedString(attachment: attachment)
            attributedText.append(.init(string: " "))
            attributedText.append(checkmarkString)
        }

        label.attributedText = attributedText

        updateColors()
    }

    override open func styleDidChange() {
        super.styleDidChange()
        let style = self.style()
        updateColors()
        layer.cornerRadius = style.appearance.cornerRadius2
        directionalLayoutMargins = style.dimension.directionalInsets1
    }

    override open func tintColorDidChange() {
        super.tintColorDidChange()
        updateColors()
    }

    private func constrainSubviews() {
        NSLayoutConstraint.activate(label.constraints(equalTo: layoutMarginsGuide))
    }

    private func updateColors() {
        let style = self.style()
        backgroundColor = isSelected ? style.color.tertiaryCustomFill : tintColor
        label.textColor = isSelected ? tintColor : style.color.white
    }
}

private extension UIImage {
    static func from(systemName: String) -> UIImage? {
        let image = UIImage(systemName: systemName)
        assert(image != nil, "Unable to locate symbol for system name: \(systemName)")
        return image
    }
}
