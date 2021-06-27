/*
 Copyright (c) 2020, Apple Inc. All rights reserved.
 
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
#if !os(watchOS)

import UIKit

/// Handles events for an `OCKFeaturedContentView`.
public protocol OCKFeaturedContentViewDelegate: AnyObject {

    /// Called when the view was tapped.
    /// - Parameter view: The view that was tapped.
    func didTapView(_ view: OCKFeaturedContentView)
}

/// A card that displays a large background image. The whole view is tappable.
///
/// # Style
/// The card supports styling using `careKitStyle(_:)`.
///
/// ```
///     +-------------------------------------------------------+
///     |                                                       |
///     |                                                       |
///     |                                                       |
///     |                        <Image>                        |
///     |                                                       |
///     |                                                       |
///     |   <Label>                                             |
///     +-------------------------------------------------------+
/// ```
open class OCKFeaturedContentView: OCKView, OCKCardable {

    // MARK: - OCKCardable

    public var contentView: UIView { button }
    public var cardView: UIView { self }

    // MARK: - Properties

    private let detailedImageView: OCKDetailedImageView
    private let button: OCKAnimatedButton<UIView>

    /// Handles events related to the view.
    public weak var delegate: OCKFeaturedContentViewDelegate?

    /// Primary multi-line label.
    public var label: OCKLabel { detailedImageView.label }

    /// Large background image.
    public var imageView: UIImageView { detailedImageView.imageView }

    override open var intrinsicContentSize: CGSize { detailedImageView.intrinsicContentSize }

    // MARK: - Initializers

    /// Create an instance.
    /// - Parameter imageOverlayStyle: The interface style of the overlay over the image. Use `.unspecified` for no overlay.
    public init(imageOverlayStyle: UIUserInterfaceStyle = .unspecified) {
        self.detailedImageView = .init(overlayStyle: imageOverlayStyle)
        button = .init(contentView: self.detailedImageView, highlightOptions: [.defaultFade, .defaultDelayOnSelect], handlesSelection: false)
        super.init()

        addSubviews()
        constrainSubviews()
        button.addTarget(self, action: #selector(didTapView), for: .touchUpInside)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods

    private func addSubviews() {
        addSubview(button)
    }

    private func constrainSubviews() {
        button.frame = bounds
        button.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    @objc
    private func didTapView() {
        delegate?.didTapView(self)
    }

    override open func styleDidChange() {
        super.styleDidChange()
        let style = self.style()
        enableCardStyling(true, style: style)
    }
}
#endif
