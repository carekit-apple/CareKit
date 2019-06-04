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

private extension UIColor {
    func adjusted(by percentage: CGFloat) -> UIColor? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        return UIColor(red: min(red + percentage / 100, 1.0), green: min(green + percentage / 100, 1.0),
                       blue: min(blue + percentage / 100, 1.0), alpha: alpha)
    }
}

/// A button with added accessibility features.
///
/// By default, the button handles its selection state when pressed. The selection state will also propogate down
/// to any of it's subviews that are of type `UIButton`. This behavior can be toggled with the `handlesSelectionStateAutomatically` flag.
///
/// The depending on the specific button, there may be a `titleLabel` and a `detailLabel` The former is generally the main focus in the
/// button and is un-tinted. The latter is an accessory label that may be tinted. To modify the `detailLabel`, see `setDetail`,
/// `setDetailColor`, `setAttributedDetail`, and `setDetailShadowColor`.
///
/// See `setBackgroundColor` to change the background color of the button for a particular state.
///
/// During initialization, there is an option to pass in the `textStyle` and `weight` for both the `titleButton` and `detailButtton`.
/// When provided, the labels will automatically adapt to any changes to the accessbility content size.
///
open class OCKButton: UIButton {
    
    // MARK: Properties
    
    // The elements that can adapt their color to the tint color whenever it changes.
    internal enum Trait {
        case titleColor, backgroundColor
    }
    
    /// A trait that matches the tint color for a particular state.
    internal struct TintedTrait: Equatable {
        /// The trait for which to set the tint color.
        internal let trait: Trait
        /// The state for which the trait is tinted.
        internal let state: UIControl.State
    }
    
    private enum Constants {
        static let darkeningShift: CGFloat = -5
    }
    
    open override var intrinsicContentSize: CGSize {
        guard let titleLabel = titleLabel else { return super.intrinsicContentSize }
        return fitsSizeToTitleLabel ?
            CGSize(width: frame.width, height: titleLabel.frame.height) :
            super.intrinsicContentSize
    }
    
    private let titleTextStyle: UIFont.TextStyle?
    private let detailTextStyle: UIFont.TextStyle?
    private let titleWeight: UIFont.Weight?
    private let detailWeight: UIFont.Weight?
    
    /// The traits that adapt their color to the tint color whenever it changes.
    internal var tintedTraits: [TintedTrait] = [] {
        didSet {
            if tintedTraits.count > oldValue.count { colorTintedTraits(tintedTraits) }  // only update when new value is added
        }
    }

    internal var fitsSizeToTitleLabel = false {
        didSet { invalidateIntrinsicContentSize() }
    }
    
    /// Flag determining whether to state text changes.
    public var animatesStateChanges = false
    
    /// Flag determines if the selection state is toggled when the button is pressed
    public var handlesSelectionStateAutomatically = true

    /// Flag that indicates whether or not the button is selected. If `handlesSelectionStateAutomatically` is true, changes to
    /// `isSelected` will be animated.
    open override var isSelected: Bool {
        get {
            return super.isSelected
        } set {
            subviews.forEach { ($0 as? UIButton)?.isSelected = newValue }   // cascade status down to embedded buttons
            guard animatesStateChanges else {
                super.isSelected = newValue
                return
            }
            UIView.transition(
                with: self, duration: OCKStyle.animation.stateChangeDuration, options: .transitionCrossDissolve,
                animations: { super.isSelected = newValue }, completion: nil)
        }
    }
    
    /// The secondary label in the button if it exists. This may or may not be tinted.
    open var detailLabel: UILabel? {
        return detailButton?.titleLabel
    }
    
    /// The primary label in the button if it exists. This is never tinted.
    open override var titleLabel: UILabel? {
        return titleButton?.titleLabel ?? super.titleLabel
    }
    
    open override var imageView: UIImageView? {
        return imageButton?.imageView ?? super.imageView
    }
    
    // Buttons to override the standard UIButton label and image
    internal var titleButton: OCKButton? { nil }
    internal var detailButton: OCKButton? { nil }
    internal var imageButton: OCKButton? { nil }
    
    // MARK: Life Cycle
    
    /// By default doesn't adapt labels to accessibility content size changes, does handles selection state, and does not animate
    /// selection state changes.
    public init() {
        self.titleTextStyle = nil
        self.titleWeight = nil
        self.detailTextStyle = nil
        self.detailWeight = nil
        super.init(frame: .zero)
        setup()
    }
    
    /// By default does adapt `titleLabel` to accessibility content size changes, does handles selection state, and does not animate
    /// selection state changes.
    ///
    /// - Parameters:
    ///   - titleTextStyle: The font style for the `titleLabel`
    ///   - titleWeight: The weight for the `titleLabel` font.
    public init(titleTextStyle: UIFont.TextStyle, titleWeight: UIFont.Weight) {
        self.titleTextStyle = titleTextStyle
        self.detailTextStyle = nil
        self.titleWeight = titleWeight
        self.detailWeight = nil
        super.init(frame: .zero)
        setup()
    }

    /// By default does adapt `detailLabel` to accessibility content size changes, does handles selection state, and does not animate
    /// selection state changes.
    ///
    /// - Parameters:
    ///   - detailTextStyle: The font style for the `detailLabel`
    ///   - detailWeight: The weight for the `detailLabel` font.
    public init(detailTextStyle: UIFont.TextStyle, detailWeight: UIFont.Weight) {
        self.titleTextStyle = nil
        self.detailTextStyle = detailTextStyle
        self.titleWeight = nil
        self.detailWeight = detailWeight
        super.init(frame: .zero)
        setup()
    }
    
    /// By default does adapt `titleLabel` and `detailLabel` to accessibility content size changes, does handles selection state,
    /// and does not animate selection state changes.
    ///
    /// - Parameters:
    ///   - titleTextStyle: The font style for the `titleLabel`
    ///   - titleWeight: The weight for the `titleLabel` font.
    ///   - detailTextStyle: The font style for the `detailLabel`
    ///   - detailWeight: The weight for the `detailLabel` font.
    public init(titleTextStyle: UIFont.TextStyle, titleWeight: UIFont.Weight,
                detailTextStyle: UIFont.TextStyle, detailWeight: UIFont.Weight) {
        self.titleTextStyle = titleTextStyle
        self.detailTextStyle = detailTextStyle
        self.titleWeight = titleWeight
        self.detailWeight = detailWeight
        super.init(frame: .zero)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        if let titleLabel = titleLabel {
            titleLabel.preferredMaxLayoutWidth = titleLabel.frame.size.width
        }
    }
    
    // MARK: Methods
    
    open override func tintColorDidChange() {
        colorTintedTraits(tintedTraits)
    }
    
    // Tint the given `tintedTraits` to match `tintColor`.
    private func colorTintedTraits(_ tinteTraits: [TintedTrait]) {
        for tintedTrait in tintedTraits {
            switch tintedTrait.trait {
            case .titleColor: setTitleColor(tintColor, for: tintedTrait.state)
            case .backgroundColor: setBackgroundColor(tintColor, for: tintedTrait.state)
            }
        }
    }
    
    private func removeTintedTrait(_ tintedTrait: TintedTrait) {
        tintedTraits.removeAll { tintedTrait == $0 }
    }
    
    private func setup() {
        preservesSuperviewLayoutMargins = true
        addTarget(self, action: #selector(selected), for: .touchUpInside)
        updateLabels()
    }
    
    private func updateLabelWithTextStyle(_ style: UIFont.TextStyle?, weight: UIFont.Weight, label: UILabel?) {
        guard let style = style else { return }
        label?.font = UIFont.preferredCustomFont(forTextStyle: style, weight: weight)
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory else { return }
        updateLabels()
    }
    
    private func updateLabels() {
        if let textStyle = titleTextStyle, let weight = titleWeight {
            updateLabelWithTextStyle(textStyle, weight: weight, label: titleLabel)
        }
        
        if let textStyle = detailTextStyle, let weight = detailWeight {
            updateLabelWithTextStyle(textStyle, weight: weight, label: detailLabel)
        }
    }
    
    open override func setTitle(_ title: String?, for state: UIControl.State) {
        if let titleButton = titleButton {
            titleButton.setTitle(title, for: state)
        } else {
            super.setTitle(title, for: state)
            guard state == .selected else { return }
            super.setTitle(title, for: State.selected.union(.highlighted))  // for when in selected state, then highlight
        }
    }
    
    open override func setImage(_ image: UIImage?, for state: UIControl.State) {
        if let imageButton = imageButton {
            imageButton.setImage(image, for: state)
        } else {
            super.setImage(image, for: state)
            guard state == .selected else { return }
            super.setImage(image, for: State.selected.union(.highlighted))
        }
    }
    
    open override func setAttributedTitle(_ title: NSAttributedString?, for state: UIControl.State) {
        if let titleButton = titleButton {
            titleButton.setAttributedTitle(title, for: state)
        } else {
            super.setAttributedTitle(title, for: state)
            guard state == .selected else { return }
            super.setAttributedTitle(title, for: State.selected.union(.highlighted))
        }
    }

    open override func setTitleColor(_ color: UIColor?, for state: UIControl.State) {
        // If a color is explicitely set, don't match the tintColor
        if color != tintColor {
            removeTintedTrait(TintedTrait(trait: .titleColor, state: state))
        }

        if let titleButton = titleButton {
            titleButton.setTitleColor(color, for: state)
        } else {
            super.setTitleColor(color, for: state)
            guard state == .selected else { return }
            super.setTitleColor(color, for: State.selected.union(.highlighted))
        }
    }
    open override func setBackgroundImage(_ image: UIImage?, for state: UIControl.State) {
        super.setBackgroundImage(image, for: state)
        guard state == .selected else { return }
        super.setBackgroundImage(image, for: State.selected.union(.highlighted))
    }
    
    open override func setTitleShadowColor(_ color: UIColor?, for state: UIControl.State) {
        if let titleButton = titleButton {
            titleButton.setTitleShadowColor(color, for: state)
        } else {
            super.setTitleShadowColor(color, for: state)
            guard state == .selected else { return }
            super.setTitleShadowColor(color, for: State.selected.union(.highlighted))
        }
    }
    
    /// Set the detail text for a particular state.
    ///
    /// - Parameters:
    ///   - detail: The detail text.
    ///   - state: The state for which to display the text.
    open func setDetail(_ detail: String?, for state: UIControl.State) {
        detailButton?.setTitle(detail, for: state)
    }
    
    /// Set the detail text color for a particular state.
    ///
    /// - Parameters:
    ///   - color: The color of the detail text.
    ///   - state: The state for which to display the detail text color.
    open func setDetailColor(_ color: UIColor?, for state: UIControl.State) {
        detailButton?.setTitleColor(color, for: state)
    }
    
    /// Set the attributed detail text for a particular state.
    ///
    /// - Parameters:
    ///   - detail: The attributed detail text.
    ///   - state: The state for which to display the attributed detail text.
    open func setAttributedDetail(_ detail: NSAttributedString?, for state: UIControl.State) {
        detailButton?.setAttributedTitle(detail, for: state)
    }
    
    /// Set the detail text shadow color for a particular state.
    ///
    /// - Parameters:
    ///   - color: The detail text shadow color.
    ///   - state: The state for which to display the detail text shadow color.
    open func setDetailShadowColor(_ color: UIColor?, for state: UIControl.State) {
        detailButton?.setTitleShadowColor(color, for: state)
    }
    
    /// Set the background color for a particular state. If state is normal, this function
    /// will automatically assign the button's background a darker  `color` when it is selected.
    ///
    /// - Parameters:
    ///   - color: background color.
    ///   - state: The state for which to display the backgroound color.
    public func setBackgroundColor(_ color: UIColor, for state: State) {
        // If a color is explicitely set, don't match the tintColor
        if color != tintColor {
            removeTintedTrait(TintedTrait(trait: .backgroundColor, state: state))
        }
        
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIGraphicsGetCurrentContext()!.setFillColor(color.cgColor)
        UIGraphicsGetCurrentContext()!.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        setBackgroundImage(colorImage, for: state)
        
        // automatically set darkened color for highlighted state
        if state == .normal, let darkerColor = color.adjusted(by: Constants.darkeningShift) {
            setBackgroundColor(darkerColor, for: .highlighted)
        }
        if state == .selected, let darkerColor = color.adjusted(by: Constants.darkeningShift) {
            setBackgroundColor(darkerColor, for: State.highlighted.union(.selected))
        }
    }
    
    @objc
    private func selected() {
        guard handlesSelectionStateAutomatically else { return }
        isSelected = !isSelected
    }
}
