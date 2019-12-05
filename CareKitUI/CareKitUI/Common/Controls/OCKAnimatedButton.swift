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
    func inverted() -> UIColor? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        return .init(red: 1 - red, green: 1 - green, blue: 1 - blue, alpha: alpha)
    }
}

/// A highlightable and selectable button that can be animated. The `isHighlighted` state can be specified with options, and the `isSelected` state
/// can be handled automatically when the button is tapped.
///
/// The content view can be injected into the button. By default, the content is contrained to the button's `layoutMarginGuide`.
open class OCKAnimatedButton<Content: UIView>: UIControl, OCKStylable {

    /// Options for displaying the the highlighted state of an `OCKAnimatedButton`.
    public enum HighlightOption: Hashable {

        /// Draw an overlay over the button's content.
        case overlay(alpha: CGFloat)

        /// Lower the alpha of the button.
        case fade(alpha: CGFloat)

        /// Delay showing the highlighted state after the button is tapped.
        case delayOnSelect(delay: TimeInterval)

        /// Draw an overlay over the button's content with a default alpha.
        public static var defaultOverlay: HighlightOption { .overlay(alpha: 0.05) }

        /// Delay showing the highlighted state after the button is tapped by a default value.
        public static var defaultFade: HighlightOption { .fade(alpha: 0.6) }

        /// Delay showing the highlighted state after the button is tapped by a default value.
        public static var defaultDelayOnSelect: HighlightOption { .delayOnSelect(delay: 0.05) }

        public func hash(into hasher: inout Hasher) {
            // Hash self without taking into account the associated values.
            switch self {
            case .overlay: hasher.combine(2)
            case .fade: hasher.combine(3)
            case .delayOnSelect: hasher.combine(4)
            }
        }

        // Check if self is `.overlay` and ignore the associated value.
        var isOverlay: Bool {
            switch self {
            case .overlay: return true
            default: return false
            }
        }

        // Check if self is `.delayOnSelect` and ignore the associated value.
        var isDelayOnSelect: Bool {
            switch self {
            case .delayOnSelect: return true
            default: return false
            }
        }

        // Check if self is `.fade` and ignore the associated value.
        var isFade: Bool {
            switch self {
            case .fade: return true
            default: return false
            }
        }
    }

    // MARK: Properties

    /// Set the selected state for the button. By default the selected state is not animated.
    override open var isSelected: Bool {
        get { return super.isSelected }
        set { return setSelected(newValue, animated: false) }
    }

    /// Set the highlighted state for the button. By default the highlighted state is animated.
    override open var isHighlighted: Bool {
        get { return super.isHighlighted }
        set {
            if showsHighlight {
                // Note: We animate by default because `isHighlighted` is set and managed internally by `UIControl`.
                setHighlighted(newValue, animated: true, buttonWasTapped: true)
            } else {
                super.isHighlighted = newValue
            }
        }
    }

    /// Handle the selection state automatically when the button is tapped.
    public var handlesSelection: Bool = true

    /// The highlighted state options.
    public let highlightOptions: Set<HighlightOption>

    /// The content inside the button.
    public let contentView: Content?

    public var customStyle: OCKStyler? {
        didSet { styleChildren() }
    }

    // Overlay over the content during the highlighted state.
    private lazy var overlayView: UIView = {
        let view = UIView()
        view.alpha = 0
        view.isUserInteractionEnabled = false
        return view
    }()

    private let highlightAnimator = UIViewPropertyAnimator(duration: 0.1, curve: .easeOut, animations: nil)
    private let selectAnimator = UIViewPropertyAnimator(duration: 0.1, curve: .easeOut, animations: nil)
    private var showsHighlight: Bool { !highlightOptions.isEmpty }

    // MARK: - Life Cycle

    /// Creat an animated button with injected content. The content will automatically be constrained to the button's `layoutMarginGuide`.
    /// - Parameter contentView: The content to be constrained to the button's `layoutMarginGuide`.
    /// - Parameter highlightOptions: Options for displaying the highlighted state. Suppplying no options cause the button to show no highlighted
    ///                               state
    /// - Parameter handlesSelection: Automatically sets the selected state when the button is tapped.
    public init(contentView: Content?,
                highlightOptions: Set<HighlightOption> = [],
                handlesSelection: Bool = true) {
        self.contentView = contentView
        self.handlesSelection = handlesSelection
        self.highlightOptions = Set(highlightOptions)
        super.init(frame: .zero)
        setup()
    }

    public required init?(coder: NSCoder) {
        contentView = nil
        highlightOptions = []
        super.init(coder: coder)
        setup()
    }

    // MARK: - Methods

    private func setup() {
        addSubviews()
        constrainSubviews()
        styleDidChange()

        contentView?.isUserInteractionEnabled = false
    }

    private func addSubviews() {
        if let contentView = contentView {
            addSubview(contentView)
        }

        if highlightOptions.contains(where: { $0.isOverlay }) {
            addSubview(overlayView)
        }
    }

    private func constrainSubviews() {
        if highlightOptions.contains(where: { $0.isOverlay }) {
            overlayView.frame = bounds
            overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }

        if let contentView = contentView {
            contentView.frame = bounds
            contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
    }

    private func highlightDelayValue(for options: Set<HighlightOption>) -> TimeInterval {
        guard let index = options.firstIndex(where: { $0.isDelayOnSelect }) else { return 0 }
        if case let HighlightOption.delayOnSelect(delay) = options[index] {
            return delay
        }
        return 0
    }

    private func setHighlighted(_ isHighlighted: Bool, animated: Bool, buttonWasTapped: Bool) {
        guard isHighlighted != super.isHighlighted else { return }
        super.isHighlighted = isHighlighted

        // Ensure the button should show a highlighted state. If it should not, clear the state.
        guard showsHighlight else {
            if isHighlighted {
                setStyleForSelectedState(false)
            }
            return
        }

        // Set the state without an animation.
        guard animated else {
            highlightAnimator.stopAnimation(true)
            setStyleForHighlightedState(isHighlighted)
            return
        }

        // Compute the delay value for showing the highlighted state. Only delay if the highlighted state is the result of a tap, and the highlight
        // options specify a delay.
        let delay: TimeInterval = buttonWasTapped && isHighlighted ? highlightDelayValue(for: highlightOptions) : 0

        // Animate the highlighted state.
        highlightAnimator.stopAnimation(true)
        highlightAnimator.addAnimations { [unowned self] in
            self.setStyleForHighlightedState(isHighlighted)
        }
        highlightAnimator.startAnimation(afterDelay: delay)
    }

    private func isTouchInside(_ touches: Set<UITouch>, event: UIEvent?) -> Bool {
        guard let touch = touches.first else { return false }
        let position = touch.location(in: self)
        return point(inside: position, with: event)
    }

    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        // Automatically set the selected state when the button is tapped
        guard handlesSelection && isTouchInside(touches, event: event) else { return }
        setSelected(!isSelected, animated: true)
    }

    /// Set the style for the highlighted state. This function may be called in an animation block if the state is being animated.
    /// - Parameter isHighlighted: True if the button is in the highlighted state.
    open func setStyleForHighlightedState(_ isHighlighted: Bool) {
        for option in highlightOptions {
            switch option {
            case .overlay(let alpha):
                overlayView.alpha = isHighlighted ? alpha : 0
            case .fade(let alpha):
                self.alpha = isHighlighted ? alpha : 1
            case .delayOnSelect:
                break
            }
        }
    }

    /// Set the highlighted state and update the `isHighlighted` property.
    /// - Parameter isHighlighted: True if the button is in the highlighted state.
    /// - Parameter animated: Animate the highlighted state.
    open func setHighlighted(_ isHighlighted: Bool, animated: Bool) {
        setHighlighted(isHighlighted, animated: animated, buttonWasTapped: false)
    }

    /// Set the style for the selected state. This function may be called in an animation block if the state is being animated.
    /// - Parameter isSelected: True if the button is in the selected state.
    open func setStyleForSelectedState(_ isSelected: Bool) {
        assert(false, "Should override setStyleForSelectedState(isSelected:)")
    }

    /// Set the selected state and update the `isSelected` property.
    /// - Parameter isSelected: True if the button is in the selected state.
    /// - Parameter animated: Animate the selected state.
    open func setSelected(_ isSelected: Bool, animated: Bool) {
        guard isSelected != self.isSelected else { return }
        super.isSelected = isSelected

        // Set the state without an animation.
        guard animated else {
            selectAnimator.stopAnimation(true)
            setStyleForSelectedState(isSelected)
            return
        }

        // Animate the selected state.
        selectAnimator.stopAnimation(true)
        selectAnimator.addAnimations { [unowned self] in
            self.setStyleForSelectedState(isSelected)
        }
        selectAnimator.startAnimation()
    }

    // MARK: - OCKStylable

    open func styleDidChange() {
        let style = self.style()
        overlayView.backgroundColor = UIColor { _ in
            let customBackground = style.color.customBackground
            return customBackground.inverted() ?? customBackground
        }
        directionalLayoutMargins = style.dimension.directionalInsets1
    }

    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        styleDidChange()
    }

    override open func removeFromSuperview() {
        super.removeFromSuperview()
        styleChildren()
    }
}
