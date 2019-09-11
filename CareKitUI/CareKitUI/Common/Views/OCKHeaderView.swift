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

/// A title and detail label. The view can also be configured to show a separator,
/// icon image, and a detail disclosure arrow.
///
///    +----------------------------------------+
///    | +----+                                 |
///    | |icon|  Title             [detail      |
///    | |img |  Detail             disclosure] |
///    | +----+                                 |
///    |                                        |
///    |  ------------------------------------  |
///    |                                        |
///    +----------------------------------------+
///
open class OCKHeaderView: OCKView {
    // MARK: Properties

    /// Configuration for a header view.
    public struct Configuration {
        /// Flag to show a separator under the text in the view.
        public var showsSeparator: Bool = false

        /// Flag to show an image on the trailing end of the view. The default image is an arrow.
        public var showsDetailDisclosure: Bool = false

        /// Flag to show an image on the leading side of the text in the view.
        public var showsIconImage: Bool = false
    }

    /// The configuration for the view.
    private let configuration: Configuration

    private enum Constants {
        static let bundle = Bundle(for: OCKHeaderView.self)
        static let spacing: CGFloat = 4
    }

    private var detailDisclosureImageWidthConstraint: NSLayoutConstraint?
    private var iconImageHeightConstraint: NSLayoutConstraint?

    // MARK: Stack views

    /// Vertical stack view that holds the main content.
    public let contentStackView: OCKStackView = {
        let stackView = OCKStackView(style: .plain)
        stackView.axis = .vertical
        return stackView
    }()

    /// Stack view that holds the text content in the header.
    private let headerTextStackView: OCKStackView = {
        let stackView = OCKStackView(style: .plain)
        stackView.axis = .vertical
        return stackView
    }()

    /// Stack view that holds the content in the header.
    private let headerStackView: OCKStackView = {
        let stackView = OCKStackView(style: .plain)
        stackView.alignment = .center
        return stackView
    }()

    // MARK: Images

    /// The image on the leading end of the text in the view. Depending on the configuration, this may be ni.
    public let iconImageView: UIImageView?

    /// The image on the trialing end of the view. The default image is an arrow. Depending on the configuration, this may be nil.
    public let detailDisclosureImage: UIImageView?

    // MARK: Labels

    /// Multi-line title label above `detailLabel`
    public let titleLabel: OCKLabel = {
        let label = OCKLabel(textStyle: .headline, weight: .bold)
        label.numberOfLines = 0
        label.animatesTextChanges = true
        return label
    }()

    /// Multi-line detail label below `titleLabel`.
    public let detailLabel: OCKLabel = {
        let label = OCKLabel(textStyle: .caption1, weight: .medium)
        label.numberOfLines = 0
        label.animatesTextChanges = true
        return label
    }()

    // MARK: Misc views

    /// Separator between the header and the body.
    private let separatorView: OCKSeparatorView?

    // MARK: Life Cycle

    /// Create the view with a configuration block. The configuration block determines which views the header should show.
    public init(configurationHandler: (inout Configuration) -> Void = { _ in }) {
        var configuration = Configuration()
        configurationHandler(&configuration)
        self.configuration = configuration

        iconImageView = configuration.showsIconImage ? OCKHeaderView.makeIconImageView() : nil
        detailDisclosureImage = configuration.showsDetailDisclosure ? OCKHeaderView.makeDetailDisclosureImage() : nil
        separatorView = configuration.showsSeparator ? OCKSeparatorView() : nil
        super.init()
    }

    public required init?(coder aDecoder: NSCoder) {
        self.configuration = Configuration()
        iconImageView = nil
        detailDisclosureImage = nil
        separatorView = nil
        super.init(coder: aDecoder)
    }

    // MARK: Methods

    override func setup() {
        super.setup()
        addSubviews()
        constrainSubviews()
        styleSubviews()
    }

    private func addSubviews() {
        [titleLabel, detailLabel].forEach { headerTextStackView.addArrangedSubview($0) }
        [headerTextStackView].forEach { headerStackView.addArrangedSubview($0) }
        [headerStackView].forEach { contentStackView.addArrangedSubview($0) }

        // Setup dynamic views based on the configuration
        if let separatorView = separatorView { contentStackView.addArrangedSubview(separatorView) }
        if let detailDisclosureImage = detailDisclosureImage { headerStackView.addArrangedSubview(detailDisclosureImage) }
        if let iconImageView = iconImageView { headerStackView.insertArrangedSubview(iconImageView, at: 0) }

        addSubview(contentStackView)
    }

    private func styleSubviews() {
        let margin = directionalLayoutMargins.top * 2
        contentStackView.spacing = margin
        headerStackView.spacing = margin / 2.0
        headerTextStackView.spacing = margin / 4.0
        contentStackView.setCustomSpacing(margin, after: headerStackView)
    }

    private static func makeIconImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }

    private static func makeDetailDisclosureImage() -> UIImageView {
        let image = UIImage(systemName: "chevron.right")
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }

    private func constrainSubviews() {
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        var constraints = contentStackView.constraints(equalTo: self)

        if let detailDisclosureImage = detailDisclosureImage {
            detailDisclosureImage.translatesAutoresizingMaskIntoConstraints = false
            // Constant will be set when style is updated
            detailDisclosureImageWidthConstraint = detailDisclosureImage.widthAnchor.constraint(equalToConstant: 0)
            constraints.append(detailDisclosureImageWidthConstraint!)
        }

        if let iconImageView = iconImageView {
            iconImageView.translatesAutoresizingMaskIntoConstraints = false
            iconImageHeightConstraint = iconImageView.heightAnchor.constraint(equalToConstant: 0) // Constant will be set when style is updated
            constraints += [
                iconImageHeightConstraint!,
                iconImageView.widthAnchor.constraint(equalTo: iconImageView.heightAnchor)
            ]
        }

        NSLayoutConstraint.activate(constraints)
    }

    override open func styleDidChange() {
        super.styleDidChange()
        let cachedStyle = style()
        titleLabel.textColor = cachedStyle.color.label
        detailLabel.textColor = cachedStyle.color.label

        iconImageView?.layer.cornerRadius = cachedStyle.dimension.iconHeight1 / 2.0
        iconImageView?.tintColor = cachedStyle.color.systemGray3

        detailDisclosureImage?.tintColor = cachedStyle.color.systemGray3

        detailDisclosureImageWidthConstraint?.constant = cachedStyle.dimension.iconHeight4
        iconImageHeightConstraint?.constant = cachedStyle.dimension.iconHeight1
    }
}
