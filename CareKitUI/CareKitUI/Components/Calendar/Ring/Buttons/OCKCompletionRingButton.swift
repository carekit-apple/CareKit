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

/// A selectable completion ring with an inner check view and a title label.
open class OCKCompletionRingButton: OCKAnimatedButton<OCKStackView> {

    // MARK: Properties

    /// Label above the completion ring.
    public let label: OCKLabel = {
        let label = OCKCappedSizeLabel(textStyle: .caption1, weight: .semibold)
        label.maxFontSize = 20
        return label
    }()

    /// A fillable ring view.
    public let ring = OCKCompletionRingView()

    /// The completion state of the ring
    public private (set) var completionState = CompletionState.empty

    public let contentStackView: OCKStackView = {
        let stackView = OCKStackView.vertical()
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        return stackView
    }()

    public enum CompletionState: Equatable {
        case dimmed
        case empty
        case zero
        case progress(_ value: CGFloat)
    }

    // MARK: - Life cycle

    public init() {
        super.init(contentView: contentStackView, handlesSelection: true)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(contentView: contentStackView, handlesSelection: true)
        setup()
    }

    // MARK: - Methods

    override open func styleDidChange() {
        super.styleDidChange()
        updateRingColors()
        ring.lineWidth = style().appearance.lineWidth1
    }

    override open func setStyleForSelectedState(_ isSelected: Bool) {
        updateRingColors()
    }

    /// Called when the tint color of the view changes.
    override open func tintColorDidChange() {
        super.tintColorDidChange()
        updateRingColors()
        applyTintColor()
    }

    /// Changes the display state of the button
    ///
    /// - Parameters:
    ///   - state: The state that the completion ring button will be set to.
    ///   - animated: Determines if the change will be animated or instantaneous.
    public func setState(_ state: CompletionState, animated: Bool) {
        completionState = state
        switch state {
        case .dimmed: ring.setProgress(0, animated: animated)
        case .empty: ring.setProgress(0, animated: animated)
        case .zero: ring.setProgress(0.001, animated: animated)
        case .progress(let value): ring.setProgress(value, animated: animated)
        }
        updateRingColors()
    }

    private func setup() {
        addSubviews()
        applyTintColor()
    }

    private func updateRingColors() {
        let cachedStyle = style()
        let grooveStrokeColor = completionState == .dimmed ? cachedStyle.color.customGray3 : cachedStyle.color.customGray
        let deselectedLabelColor = completionState == .dimmed ? cachedStyle.color.tertiaryLabel : cachedStyle.color.label

        label.textColor = isSelected ? tintColor : deselectedLabelColor
        ring.grooveView.strokeColor = grooveStrokeColor
        ring.strokeColor = tintColor
    }

    private func addSubviews() {
        addSubview(contentStackView)
        [label, ring].forEach { contentStackView.addArrangedSubview($0) }
    }

    private func applyTintColor() {
        ring.strokeColor = tintColor
    }
}
