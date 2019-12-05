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

/// A fillable ring with an inner checkmark.
open class OCKCompletionRingView: OCKView {

    // MARK: Properties

    override open var intrinsicContentSize: CGSize {
        let height = style().dimension.buttonHeight2
        return CGSize(width: height, height: height)
    }

    /// The progress value of the ring view.
    public var progress: CGFloat {
        return ringView.progress
    }

    /// The duration for the ring and check view animations.
    public var duration: TimeInterval {
        get { return ringView.duration }
        set { ringView.duration = newValue }
    }

    /// The line width of the ring and check views.
    public var lineWidth: CGFloat {
        get { return  ringView.lineWidth }
        set {
            grooveView.lineWidth = newValue
            ringView.lineWidth = newValue
        }
    }

    /// The stroke color of the ring and check views.
    public var strokeColor: UIColor = OCKStyle().color.customBlue {
        didSet {
            ringView.strokeColor = strokeColor
            checkmarkImageView.tintColor = strokeColor
        }
    }

    private lazy var checkmarkAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 0.7)

    /// The fillable ring view.
    let ringView = OCKRingView()

    /// The groove in which the fillable ring resides.
    let grooveView = OCKRingView()

    /// The checkmark image view inside of the ring view.
    let checkmarkImageView: UIImageView = {
        let image = UIImage(systemName: "checkmark")
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    // MARK: - Methods

    /// Set the progress value for the ring view. The ring will fill accordingly, and if full
    /// the checkmark will display.
    ///
    /// - Parameters:
    ///   - value: The progress value.
    ///   - animated: Flag for the ring and check view animations.
    public func setProgress(_ value: CGFloat, animated: Bool = true) {
        let isComplete = value >= 1.0
        if checkmarkAnimator.isRunning {
            checkmarkAnimator.stopAnimation(true)
        }

        let animationHandler: () -> Void = { [weak self] in
            self?.checkmarkImageView.transform = isComplete ? CGAffineTransform(scaleX: 1, y: 1) : CGAffineTransform(scaleX: 0.1, y: 0.1)
            self?.checkmarkImageView.alpha = isComplete ? 1 : 0
        }

        if animated {
            checkmarkAnimator.addAnimations(animationHandler)
            checkmarkAnimator.startAnimation()
        } else {
            animationHandler()
        }

        ringView.setProgress(value, animated: animated)
    }

    override open func styleDidChange() {
        super.styleDidChange()
        invalidateIntrinsicContentSize()
        let style = self.style()
        strokeColor = tintColor
        grooveView.strokeColor = style.color.customGray3
        checkmarkImageView.preferredSymbolConfiguration = .init(pointSize: style.dimension.symbolPointSize4, weight: .bold)
    }

    override func setup() {
        super.setup()
        grooveView.alpha = 0.25
        grooveView.setProgress(1.0, animated: false)

        setProgress(0, animated: false)

        checkmarkImageView.tintColor = strokeColor
        ringView.strokeColor = strokeColor

        [grooveView, ringView, checkmarkImageView].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        var constraints =
            grooveView.constraints(equalTo: self) +
            ringView.constraints(equalTo: self)

        constraints += [
            checkmarkImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            checkmarkImageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }
}
