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

/// A view intended to display fine grained details. The view contains a configurable image, title, and instructions. To add
/// custom views, insert into the `contentStackView`.
open class OCKDetailView: OCKView {
    // MARK: Properties

    private var contentStackViewTopConstraint: NSLayoutConstraint?
    private var imageViewHeightConstraint: NSLayoutConstraint?

    /// Configurable image that spans the width of the view.
    public let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    /// Primary multi-line label.
    public let titleLabel: OCKLabel = {
        let titleLabel = OCKLabel(textStyle: .title2, weight: .semibold)
        titleLabel.numberOfLines = 0
        return titleLabel
    }()

    /// Secondary multi-line label
    public let instructionsLabel: OCKLabel = {
        let label = OCKLabel(textStyle: .subheadline, weight: .medium)
        label.numberOfLines = 0
        return label
    }()

    /// The vertical stack view that holds the main content for the view.
    public let contentStackView = OCKStackView.vertical()

    // MARK: Methods

    override func setup() {
        super.setup()
        addSubviews()
        constrainSubviews()
    }

    private func addSubviews() {
        [imageView, contentStackView].forEach { addSubview($0) }
        [titleLabel, instructionsLabel].forEach { contentStackView.addArrangedSubview($0) }
    }

    private func constrainSubviews() {
        [imageView, contentStackView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        imageViewHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: 0)
        contentStackViewTopConstraint = contentStackView.topAnchor.constraint(equalTo: imageView.bottomAnchor)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageViewHeightConstraint!,

            contentStackViewTopConstraint!,
            contentStackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            contentStackView.bottomAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.bottomAnchor)
        ])
    }

    override open func styleDidChange() {
        super.styleDidChange()
        let cachedStyle = style()
        backgroundColor = cachedStyle.color.customBackground
        directionalLayoutMargins = cachedStyle.dimension.directionalInsets1
        instructionsLabel.textColor = cachedStyle.color.label
        imageView.backgroundColor = cachedStyle.color.secondaryCustomFill
        titleLabel.textColor = cachedStyle.color.label
        imageViewHeightConstraint?.constant = cachedStyle.dimension.imageHeight1
        contentStackViewTopConstraint?.constant = cachedStyle.dimension.directionalInsets1.top
        contentStackView.spacing = cachedStyle.dimension.directionalInsets1.top / 2.0
    }
}
