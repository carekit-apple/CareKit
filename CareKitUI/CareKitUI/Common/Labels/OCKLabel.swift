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

/// A label that handles animating state changes and provides accessibilty features.
///
/// To animate changes to the text, set `animatesTextChanges` to true.
///
/// To have the label automatically change its text size whenever the accessibility content size changes,
/// use the initialzer that takes a `textStyle` and `weight`.
open class OCKLabel: UILabel, OCKStylable {

    // MARK: Properties

    public var customStyle: OCKStyler? {
        didSet { styleChildren() }
    }

    /// Flag determining whether to animate text changes.
    public var animatesTextChanges = false

    override open var text: String? {
        get {
            return super.text
        } set {
            guard animatesTextChanges else { super.text = newValue; return; }
            UIView.transition(with: self, duration: style().animation.stateChangeDuration, options: .transitionCrossDissolve, animations: {
                super.text = newValue
            }, completion: nil)
        }
    }

    private let textStyle: UIFont.TextStyle?
    private let weight: UIFont.Weight?

    // MARK: Life Cycle

    /// Create an instance of and `OCKLabel`. By default, the label will not animate text changes and will not scale with
    /// accessibility content size changes.
    public init() {
        textStyle = nil
        weight = nil
        super.init(frame: .zero)
        setup()
    }

    /// Create an instance of and `OCKLabel`. By default, the label will not animate text changes and will scale with
    /// accessibility content size changes.
    ///
    /// - Parameters:
    ///   - textStyle: The style of the font.
    ///   - weight: The weight of the font.
    public init(textStyle: UIFont.TextStyle, weight: UIFont.Weight) {
        self.textStyle = textStyle
        self.weight = weight
        super.init(frame: .zero)
        font = UIFont.preferredCustomFont(forTextStyle: textStyle, weight: weight)
        setup()
    }

    public required init?(coder aDecoder: NSCoder) {
        textStyle = nil
        weight = nil
        super.init(coder: aDecoder)
        setup()
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard
            let textStyle = textStyle, let weight = weight,
            traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory
        else { return }
        font = UIFont.preferredCustomFont(forTextStyle: textStyle, weight: weight)
    }

    // MARK: Methods

    private func setup() {
        preservesSuperviewLayoutMargins = true
        adjustsFontForContentSizeCategory = false
        styleDidChange()
    }

    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        styleDidChange()
    }

    override open func removeFromSuperview() {
        super.removeFromSuperview()
        styleChildren()
    }

    open func styleDidChange() {}
}
