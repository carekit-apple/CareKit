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
import CareKit
import CareKitUI

class TipView: OCKView, OCKCardable {

    var cardView: UIView { self }
    let contentView: UIView = OCKView()
    let headerView = OCKHeaderView()
    let imageView = UIImageView()
    var imageHeightConstraint: NSLayoutConstraint!

    private let blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.regular)
        return UIVisualEffectView(effect: blurEffect)
    }()

    override init() {
        super.init()
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        headerView.detailLabel.textColor = .secondaryLabel

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = layer.cornerRadius

        blurView.clipsToBounds = true
        blurView.layer.cornerRadius = layer.cornerRadius
        blurView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.frame = bounds

        addSubview(contentView)
        contentView.addSubview(imageView)
        contentView.addSubview(blurView)
        contentView.addSubview(headerView)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        blurView.translatesAutoresizingMaskIntoConstraints = false
        headerView.translatesAutoresizingMaskIntoConstraints = false
        imageHeightConstraint = imageView.heightAnchor.constraint(
            equalToConstant: scaledImageHeight(compatibleWith: traitCollection))

        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            headerView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),

            blurView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            blurView.topAnchor.constraint(equalTo: contentView.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),

            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageHeightConstraint
        ])
    }

    func scaledImageHeight(compatibleWith traitCollection: UITraitCollection) -> CGFloat {
        return UIFontMetrics.default.scaledValue(for: 200, compatibleWith: traitCollection)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            imageHeightConstraint.constant = scaledImageHeight(compatibleWith: traitCollection)
        }
    }

    override func styleDidChange() {
        super.styleDidChange()
        let cachedStyle = style()
        enableCardStyling(true, style: cachedStyle)
        directionalLayoutMargins = cachedStyle.dimension.directionalInsets1
    }
}
