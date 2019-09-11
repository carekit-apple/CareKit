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
    /// Adjust the brightness level of a color. Positive numbers will lighten the color.
    /// - Parameter percentage: Positive numbers lighten the color
    func adjusted(by percentage: CGFloat) -> UIColor? {
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        guard self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else { return nil }

        // The lower the alpha, the higher the brightness adjustment. Helps to adjust colors with a low alpha.
        let alphaPercentageFactor: CGFloat = 5   // Factor to increase the `alphaAdjustment`
        let alphaAdjustement = (1 - alpha) * percentage * alphaPercentageFactor
        let adjustedBrightness = brightness + (percentage + alphaAdjustement) / 100.0
        let clampedBrightness = min(max(0, adjustedBrightness), 1)    // In range [0, 1]
        return UIColor(hue: hue, saturation: saturation, brightness: clampedBrightness, alpha: alpha)
    }
}

private extension UIView {
    func selectChildren(_ isSelected: Bool) {
        subviews.forEach {
            ($0 as? UIButton)?.isSelected = isSelected
            $0.selectChildren(isSelected)
        }
    }
}

/// A button with added accessibility features.
///
/// By default, the button handles its selection state when pressed. The selection state will also propogate down
/// to any of its subviews that are of type `UIButton`. This behavior can be toggled with the `handlesSelectionStateAutomatically` flag.
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
open class OCKButton: UIButton, OCKStylable {
    // MARK: Properties

    public var customStyle: OCKStyler? {
        didSet { styleChildren() }
    }

    // The elements that can adapt their color to the tint color whenever it changes.
    enum Trait {
        case titleColor, backgroundColor
    }

    /// A trait that matches the tint color for a particular state.
    struct TintedTrait: Equatable {
        /// The trait for which to set the tint color.
        let trait: Trait
        /// The state for which the trait is tinted.
        let state: UIControl.State
    }

    private enum Constants {
        static let highlightedColorShift: CGFloat = 5  // Percent
    }

    private let titleTextStyle: UIFont.TextStyle?
    private let detailTextStyle: UIFont.TextStyle?
    private let titleWeight: UIFont.Weight?
    private let detailWeight: UIFont.Weight?

    /// Background colors that map to the raw value for each UIControl state
    private var backgroundColors: [UInt: UIColor?] = Dictionary(uniqueKeysWithValues:
         [State.normal.rawValue, State.highlighted.rawValue, State.disabled.rawValue, State.selected.rawValue,
          State.focused.rawValue, State.application.rawValue, State.reserved.rawValue]
            .map { ($0, nil) }
    )

    /// The traits that adapt their color to the tint color whenever it changes.
    var tintedTraits: [TintedTrait] = [] {
        didSet {
            if tintedTraits.count > oldValue.count { colorTintedTraits(tintedTraits) }  // only update when new value is added
        }
    }

    /// Flag determining whether to animate state text changes.
    public var animatesStateChanges = false

    /// Flag determines if the selection state is toggled when the button is pressed
    public var handlesSelectionStateAutomatically = true

    /// True if the button's frame should fit the `titleLabel`'s frame.
    var sizesToFitTitleLabel = false {
        didSet { invalidateIntrinsicContentSize() }
    }

    override open var intrinsicContentSize: CGSize {
        guard sizesToFitTitleLabel else { return super.intrinsicContentSize }

        // Fit the frame to the title label's frame
        let labelSize = titleLabel?.sizeThatFits(CGSize(width: frame.size.width, height: CGFloat.greatestFiniteMagnitude)) ?? .zero
        return CGSize(width: labelSize.width + titleEdgeInsets.left + titleEdgeInsets.right,
                      height: labelSize.height + titleEdgeInsets.top + titleEdgeInsets.bottom)
    }

    /// Flag that indicates whether or not the button is selected. If `handlesSelectionStateAutomatically` is true, changes to
    /// `isSelected` will be animated.
    override open var isSelected: Bool {
        get {
            return super.isSelected
        } set {
            selectChildren(newValue)
            guard animatesStateChanges else {
                super.isSelected = newValue
                return
            }
            UIView.transition(
                with: self, duration: style().animation.stateChangeDuration, options: .transitionCrossDissolve,
                animations: { super.isSelected = newValue }, completion: nil)
        }
    }

    /// The secondary label in the button if it exists. This may or may not be tinted.
    open var detailLabel: UILabel? {
        return detailButton?.titleLabel
    }

    /// The primary label in the button if it exists. This is never tinted.
    override open var titleLabel: UILabel? {
        return titleButton?.titleLabel ?? super.titleLabel
    }

    override open var imageView: UIImageView? {
        return imageButton?.imageView ?? super.imageView
    }

    // Buttons to override the standard UIButton label and image
    var titleButton: OCKButton? { nil }
    var detailButton: OCKButton? { nil }
    var imageButton: OCKButton? { nil }

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

    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Methods

    override open func tintColorDidChange() {
        colorTintedTraits(tintedTraits)
    }

    // Tint the given `tintedTraits` to match `tintColor`.
    private func colorTintedTraits(_ tintedTraits: [TintedTrait]) {
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

    func setup() {
        preservesSuperviewLayoutMargins = true
        addTarget(self, action: #selector(selected), for: .touchUpInside)
        updateLabels()
        styleDidChange()
    }

    private func updateLabelWithTextStyle(_ style: UIFont.TextStyle?, weight: UIFont.Weight, label: UILabel?) {
        guard let style = style else { return }
        label?.font = UIFont.preferredCustomFont(forTextStyle: style, weight: weight)
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // update the labels based on the new size categories
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            updateLabels()
        }

        // Update the color shifted colors for highlighted buttons based on on light/dark mode
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAdjustedColors()
        }
    }

    private func updateLabels() {
        if let textStyle = titleTextStyle, let weight = titleWeight {
            updateLabelWithTextStyle(textStyle, weight: weight, label: titleLabel)
        }

        if let textStyle = detailTextStyle, let weight = detailWeight {
            updateLabelWithTextStyle(textStyle, weight: weight, label: detailLabel)
        }
    }

    override open func setTitle(_ title: String?, for state: UIControl.State) {
        if let titleButton = titleButton {
            titleButton.setTitle(title, for: state)
        } else {
            super.setTitle(title, for: state)
            guard state == .selected else { return }
            super.setTitle(title, for: State.selected.union(.highlighted))  // for when in selected state, then highlight
        }

        // Update the frame if needed
        if sizesToFitTitleLabel {
            invalidateIntrinsicContentSize()
        }
    }

    override open func setImage(_ image: UIImage?, for state: UIControl.State) {
        if let imageButton = imageButton {
            imageButton.setImage(image, for: state)
        } else {
            super.setImage(image, for: state)
            guard state == .selected else { return }
            super.setImage(image, for: State.selected.union(.highlighted))
        }
    }

    override open func setAttributedTitle(_ title: NSAttributedString?, for state: UIControl.State) {
        if let titleButton = titleButton {
            titleButton.setAttributedTitle(title, for: state)
        } else {
            super.setAttributedTitle(title, for: state)
            guard state == .selected else { return }
            super.setAttributedTitle(title, for: State.selected.union(.highlighted))
        }

        // Update the frame if needed
        if sizesToFitTitleLabel {
            invalidateIntrinsicContentSize()
        }
    }

    override open func setTitleColor(_ color: UIColor?, for state: UIControl.State) {
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

    override open func setBackgroundImage(_ image: UIImage?, for state: UIControl.State) {
        super.setBackgroundImage(image, for: state)
        guard state == .selected else { return }
        super.setBackgroundImage(image, for: State.selected.union(.highlighted))
    }

    override open func setTitleShadowColor(_ color: UIColor?, for state: UIControl.State) {
        if let titleButton = titleButton {
            titleButton.setTitleShadowColor(color, for: state)
        } else {
            super.setTitleShadowColor(color, for: state)
            guard state == .selected else { return }
            super.setTitleShadowColor(color, for: State.selected.union(.highlighted))
        }
    }

    /// Returns the detail associated with a specific state.
    /// - Parameter state: The state to check for a detail.
    open func detail(for state: UIControl.State) -> String? {
        guard let detailButton = detailButton else { return nil }
        return detailButton.title(for: state)
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
    open func setBackgroundColor(_ color: UIColor?, for state: State) {
        backgroundColors[state.rawValue] = color     // update the cache

        // If a color is explicitely set, don't match the tintColor
        if color != tintColor {
            removeTintedTrait(TintedTrait(trait: .backgroundColor, state: state))
        }

        // If the color is nil, clear the background image
        guard let color = color else {
            setBackgroundImage(nil, for: state)
            return
        }

        // Set the background image as the color
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIGraphicsGetCurrentContext()!.setFillColor(color.cgColor)
        UIGraphicsGetCurrentContext()!.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        setBackgroundImage(colorImage, for: state)

        // Update the adjusted color when the button is highlighted
        if state == .normal || state == .selected {
            updateAdjustedColors()
        }
    }

    /// Returns the background color for a given state.
    /// - Parameter state: The state in which the background color exists.
    open func backgroundColor(for state: UIControl.State) -> UIColor? {
        guard let color = backgroundColors[state.rawValue] else {
            fatalError("state (\(state)) is not a member of property `backgroundColors`")
        }
        return color
    }

    @objc
    private func selected() {
        guard handlesSelectionStateAutomatically else { return }
        isSelected.toggle()
    }

    /// Update the background color adjustment when the button is highlighted
    private func updateAdjustedColors() {
        let factor: CGFloat = traitCollection.userInterfaceStyle == .light ? -1 : 1
        let adjustment = factor * Constants.highlightedColorShift
        let adjustedSelectedColor = backgroundColor(for: .selected)?.adjusted(by: adjustment)
        let adjustedNormalColor = backgroundColor(for: .normal)?.adjusted(by: adjustment)
        setBackgroundColor(adjustedNormalColor, for: .highlighted)
        setBackgroundColor(adjustedSelectedColor, for: State.highlighted.union(.selected))
    }

    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        styleDidChange()
    }

    override open func removeFromSuperview() {
        super.removeFromSuperview()
        styleChildren()
    }

    public func styleDidChange() {}
}
