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

/// OCKCheckmarkButton button with a label.
open class OCKLabeledCheckmarkButton: OCKAnimatedButton<OCKStackView> {

    // MARK: Properties

    /// The label underneath the checkmark button.
    public let label: OCKLabel = {
        let label = OCKLabel(textStyle: .caption1, weight: .medium)
        label.textAlignment = .center
        return label
    }()

    /// The checkmark button above the label.
    public let checkmarkButton: OCKCheckmarkButton = {
        let button = OCKCheckmarkButton()
        button.isUserInteractionEnabled = false
        return button
    }()

    /// Holds the main content in the button.
    public let contentStackView: OCKStackView = {
        let stackView = OCKStackView.vertical()
        stackView.alignment = .center
        return stackView
    }()

    // MARK: - Life Cycle

    public init() {
        super.init(contentView: contentStackView, handlesSelection: true)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(contentView: contentStackView, handlesSelection: true)
        setup()
    }

    // MARK: - Methods

    private func setup() {
        addSubviews()
        constrainSubviews()
        applyTintColor()
    }

    private func addSubviews() {
        [checkmarkButton, label].forEach { contentStackView.addArrangedSubview($0) }
    }

    private func constrainSubviews() {
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        checkmarkButton.setContentHuggingPriority(.defaultHigh, for: .vertical)
        NSLayoutConstraint.activate(contentStackView.constraints(equalTo: self))
    }

    private func applyTintColor() {
        label.textColor = tintColor
    }

    override open func styleDidChange() {
        super.styleDidChange()
        let style = self.style()
        contentStackView.spacing = style.dimension.directionalInsets2.bottom
    }

    override open func tintColorDidChange() {
        super.tintColorDidChange()
        applyTintColor()
    }

    override open func setSelected(_ isSelected: Bool, animated: Bool) {
        super.setSelected(isSelected, animated: animated)
        checkmarkButton.setSelected(isSelected, animated: animated)
    }

    override open func setStyleForSelectedState(_ isSelected: Bool) {}
}
