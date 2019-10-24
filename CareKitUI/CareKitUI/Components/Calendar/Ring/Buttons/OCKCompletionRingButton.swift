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
open class OCKCompletionRingButton: OCKButton {
    override var titleButton: OCKButton? { _titleButton }

    /// Button that displays a title label.
    private let _titleButton = OCKButton()

    /// A fillable ring view.
    let ring = OCKCompletionRingView()

    /// The completion state of the ring
    public private (set) var completionState: CompletionState?

    public enum CompletionState: Equatable {
        case dimmed
        case empty
        case zero
        case progress(_ value: CGFloat)
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

    private func updateRingColors() {
        let cachedStyle = style()
        let grooveStrokeColor = completionState == .dimmed ? cachedStyle.color.systemGray3 : cachedStyle.color.systemGray
        let titleColor = completionState == .dimmed ? cachedStyle.color.tertiaryLabel : cachedStyle.color.label

        setTitleColor(titleColor, for: .normal)
        ring.grooveView.strokeColor = grooveStrokeColor
    }

    /// Called when the tint color of the view changes.
    override open func tintColorDidChange() {
        setTitleColor(tintColor, for: .selected)
        ring.strokeColor = tintColor
    }

    override func setup() {
        super.setup()
        addSubviews()
        constrainSubviews()
        styleSubviews()
    }

    private func styleSubviews() {
        _titleButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        _titleButton.isUserInteractionEnabled = false

        ring.isUserInteractionEnabled = false
        ring.strokeColor = tintColor
    }

    private func addSubviews() {
        addSubview(ring)
        addSubview(_titleButton)
    }

    private func constrainSubviews() {
        [_titleButton, ring, self].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        _titleButton.setContentHuggingPriority(.defaultHigh, for: .vertical)
        ring.setContentHuggingPriority(.defaultLow, for: .vertical)

        NSLayoutConstraint.activate([
            _titleButton.topAnchor.constraint(equalTo: topAnchor),
            _titleButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            _titleButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            _titleButton.bottomAnchor.constraint(equalTo: ring.topAnchor),

            ring.leadingAnchor.constraint(equalTo: leadingAnchor),
            ring.trailingAnchor.constraint(equalTo: trailingAnchor),
            ring.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    override public func styleDidChange() {
        super.styleDidChange()
        updateRingColors()
        ring.lineWidth = style().appearance.lineWidth1
    }
}
