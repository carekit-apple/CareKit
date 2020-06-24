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

import Foundation
import UIKit

class OCKDetailedImageView: OCKView {

    private enum Constants {
        static let overlayAlpha: CGFloat = 0.2
        static let intrinsicSize: CGSize = .init(width: 300, height: 300)
    }

    // MARK: - Properties

    let label: OCKLabel = {
        let label = OCKLabel(textStyle: .title2, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private(set) lazy var overlayView: UIView? = {
        let view: UIView?
        switch overlayStyle {
        case .dark:
            view = UIView()
            view?.backgroundColor = UIColor.black.withAlphaComponent(Constants.overlayAlpha)
        case .light:
            view = UIView()
            view?.backgroundColor = UIColor.white.withAlphaComponent(Constants.overlayAlpha)
        case .unspecified:
            view = nil
        @unknown default:
            view = nil
        }
        return view
    }()

    override var intrinsicContentSize: CGSize { Constants.intrinsicSize }

    let overlayStyle: UIUserInterfaceStyle

    // MARK: - Initializers

    init(overlayStyle: UIUserInterfaceStyle = .unspecified) {
        self.overlayStyle = overlayStyle
        super.init()
        addSubviews()
        constrainSubviews()
        styleSubviews()
        setupAccessibility()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods

    private func setupAccessibility() {
        imageView.isAccessibilityElement = true
        label.isAccessibilityElement = true
    }

    private func addSubviews() {
        [imageView, overlayView, label]
            .compactMap { $0 }
            .forEach { addSubview($0) }
    }

    private func styleSubviews() {
        imageView.clipsToBounds = true
    }

    private func constrainSubviews() {
        // NOTE: The image and overlay needs to use frame based layout to allow for custom view controller transition animation
        [overlayView, imageView].forEach {
            $0?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            $0?.frame = bounds
        }

        label.translatesAutoresizingMaskIntoConstraints = false
        let constraints =
            label.constraints(equalTo: layoutMarginsGuide, directions: [.horizontal, .bottom]) +
            [label.topAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.topAnchor)]

        NSLayoutConstraint.activate(constraints)
    }

    override func styleDidChange() {
        super.styleDidChange()
        let style = self.style()
        directionalLayoutMargins = style.dimension.directionalInsets1
        imageView.backgroundColor = style.color.secondaryCustomGroupedBackground
    }
}
#endif
