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

/// A scrollable view with an image header and text content.
///
/// Use `contentStackView` to insert custom views.
///
/// ```
///     +-------------------------------------------------------+
///     |                                                       |
///     |                        <Image>                        |
///     |   <Image Label>                                       |
///     |-------------------------------------------------------|
///     |   <Title>                                             |
///     |   <Body>                                              |
///     |                                                       |
///     |                                                       |
///     +-------------------------------------------------------+
/// ```
open class OCKDetailView: OCKView, UIScrollViewDelegate {

    // MARK: - Properties

    /// Label overlaying the header image.
    public var imageLabel: OCKLabel { detailedImageView.label }

    /// Header image.
    public var imageView: UIImageView { detailedImageView.imageView }

    /// Holds the main content.
    public let contentStackView: OCKStackView = {
        let stackView = OCKStackView.vertical()
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()

    /// Primary label.
    public let titleLabel: OCKLabel = {
        let label = OCKLabel(textStyle: .title2, weight: .semibold)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    /// Secondary label.
    public let bodyLabel: OCKLabel = {
        let label = OCKLabel(textStyle: .subheadline, weight: .medium)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    /// HTML to render in the `bodyLabel`.
    public var html: StyledHTML? {
        didSet { updateBody(with: html) }
    }

    /// Close button. The button will be non-nil when `showsCloseButton` is true.
    public private(set) lazy var closeButton: UIButton? = {
        guard showsCloseButton else { return nil }

        let button = UIButton()

        switch detailedImageView.overlayStyle {
        case .dark: button.tintColor = .black
        case .light, .unspecified: button.tintColor = .white
        @unknown default: button.tintColor = .white
        }

        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.accessibilityLabel = loc("CLOSE")
        return button
    }()

    private let detailedImageView: OCKDetailedImageView
    private let containerStackView = OCKStackView.vertical()
    private let scrollView = UIScrollView()
    private let contentView = UIView()  // content for the scroll view
    private var closeButtonHeightConstraint: NSLayoutConstraint?
    private let showsCloseButton: Bool

    private lazy var closeButtonHeight: OCKAccessibleValue<OCKStyler>? = !showsCloseButton ?
        nil :
        OCKAccessibleValue(container: style(), keyPath: \.dimension.buttonHeight3) { [weak self] height in
            self?.closeButtonHeightConstraint?.constant = height
        }

    // MARK: - Initializers

    /// Create an instance.
    /// - Parameter html: HTML to render as the `bodyLabel` text.
    /// - Parameter imageOverlayStyle: The interface style of the overlay over the image. Use `.unspecified` for no overlay.
    /// - Parameter showsCloseButton: True if the view should show a close button.
    public init(html: StyledHTML? = nil, imageOverlayStyle: UIUserInterfaceStyle, showsCloseButton: Bool) {
        self.detailedImageView = .init(overlayStyle: imageOverlayStyle)
        self.showsCloseButton = showsCloseButton
        self.html = html
        super.init()

        addSubviews()
        constrainSubviews()
        styleSubviews()
        updateBody(with: html)

        scrollView.delegate = self
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods

    private func styleSubviews() {
        backgroundColor = .systemBackground
    }

    private func addSubviews() {
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(containerStackView)
        [detailedImageView, contentStackView].forEach { containerStackView.addArrangedSubview($0) }
        [titleLabel, bodyLabel].forEach { contentStackView.addArrangedSubview($0) }
        closeButton.map { contentView.addSubview($0) }
    }

    private func constrainSubviews() {
        [scrollView, contentView, closeButton, containerStackView].forEach {
            $0?.translatesAutoresizingMaskIntoConstraints = false
        }

        var constraints: [NSLayoutConstraint] =
            scrollView.constraints(equalTo: self) +
            contentView.constraints(equalTo: scrollView) +
            containerStackView.constraints(equalTo: contentView) +
            [
                contentView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor)
            ]

        // Add close button constraints if needed
        if let closeButton = closeButton {
            closeButtonHeightConstraint = closeButton.heightAnchor.constraint(equalToConstant: closeButtonHeight!.scaledValue)
            constraints +=
                closeButton.constraints(equalTo: contentView.layoutMarginsGuide, directions: [.trailing, .top]) +
                [
                    closeButtonHeightConstraint!,
                    closeButton.widthAnchor.constraint(equalTo: closeButton.heightAnchor)
                ]
        }

        NSLayoutConstraint.activate(constraints)
    }

    // Note: This should always be called on the main thread
    private func updateBody(with html: StyledHTML?) {
        bodyLabel.attributedText = html?.attributedText(
            labelWidth: bodyLabel.frame.width,
            interfaceStyle: traitCollection.userInterfaceStyle
        )
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        bodyLabel.preferredMaxLayoutWidth = frame.inset(by: layoutMargins).size.width
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        closeButtonHeight?.apply()
        self.setNeedsLayout()

        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            updateBody(with: html)
        }
    }

    override open func styleDidChange() {
        let style = self.style()
        contentStackView.directionalLayoutMargins = style.dimension.directionalInsets1
        contentView.directionalLayoutMargins = style.dimension.directionalInsets1
        closeButtonHeight?.update(withContainer: style)

        [self, scrollView, contentView].forEach { $0.backgroundColor = style.color.customBackground }

        imageView.backgroundColor = style.color.secondaryCustomFill
        contentStackView.spacing = style.dimension.directionalInsets2.top
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // If the scroll offset is less than 0, stretch the header image (and image overlay) to fill the empty space
        let yOffset = scrollView.contentOffset.y
        guard yOffset <= 0 else { return }
        let newHeight = detailedImageView.intrinsicContentSize.height - yOffset
        imageView.frame = CGRect(x: detailedImageView.frame.minX, y: yOffset,
                                 width: detailedImageView.frame.width, height: newHeight)
        detailedImageView.overlayView?.frame = imageView.frame
    }
}

public extension OCKDetailView {

    /// String representations of HTML and CSS for styling.
    struct StyledHTML {

        // HTML string representation.
        public let html: String

        // CSS string representation used for styling the HTML.
        public let css: String?

        /// Create an instance.
        /// - Parameters:
        ///   - html: HTML string representation.
        ///   - css: CSS string representation used for styling the HTML.
        public init(html: String, css: String? = nil) {
            self.html = html
            self.css = css
        }

        func attributedText(labelWidth: CGFloat, interfaceStyle: UIUserInterfaceStyle) -> NSAttributedString? {
            // Custom css should take precedence over the default css.
            let htmlAndCSS = [
                defaultCSS(appending: css, contentWidth: labelWidth, interfaceStyle: interfaceStyle),
                html
            ]
            .compactMap { $0 }
            .joined()

            guard
                let data = htmlAndCSS.data(using: .utf8),
                let htmlAttributedString = try? NSMutableAttributedString(
                    data: data,
                    options: [.documentType: NSAttributedString.DocumentType.html],
                    documentAttributes: nil)
            else {
                log(.error, "Could not convert string to HTML")
                return nil
            }

            // The HTML parser adds whitespace to the end of the string for every nested level of block element.
            // This is a defect, block level element margins collapse in HTML.
            while let lastCharacter = htmlAttributedString.string.last, lastCharacter == "\n" {
                htmlAttributedString.deleteCharacters(in: NSRange(location: htmlAttributedString.length - 1, length: 1))
            }

            return htmlAttributedString
        }


        /// Apply custom css on top of a default stylesheet that mirrors dynamic type.
        /// Use the following classes to style content.
        /// - Parameter contentWidth: The width of the content area for text. This is necessary for image sizing.
        ///
        /// The font for this stylesheet is always
        ///
        ///     -apple-system
        ///
        /// The following styles are available as classes:
        ///
        ///     ClassName     Weight     Size  Leading
        ///     "large-title" Regular    34    41
        ///     "title-1"     Regular    28    34
        ///     "title-2"     Regular    22    28
        ///     "title-3"     Regular    20    25
        ///     "headline"    Semi-Bold  17    22
        ///     "body"        Regular    17    22
        ///     "callout"     Regular    16    21
        ///     "subheadline" Regular    15    20
        ///     "footnote"    Regular    13    18
        ///     "caption-1"   Regular    12    16
        ///     "caption-2"   Regular    11    13
        ///
        /// h1, h2, h3, h4, h5 and p tags map to these sequentially.
        func defaultCSS(appending customCSS: String?, contentWidth: CGFloat, interfaceStyle: UIUserInterfaceStyle) -> String {

            let largeTitleFontSize = UIFont.preferredFont(forTextStyle: .largeTitle).pointSize
            let title1FontSize = UIFont.preferredFont(forTextStyle: .title1).pointSize
            let title2FontSize = UIFont.preferredFont(forTextStyle: .title2).pointSize
            let title3FontSize = UIFont.preferredFont(forTextStyle: .title3).pointSize
            let headlineFontSize = UIFont.preferredFont(forTextStyle: .headline).pointSize
            let bodyFontSize = UIFont.preferredFont(forTextStyle: .body).pointSize
            let calloutFontSize = UIFont.preferredFont(forTextStyle: .callout).pointSize
            let subheadlineFontSize = UIFont.preferredFont(forTextStyle: .subheadline).pointSize
            let footnoteFontSize = UIFont.preferredFont(forTextStyle: .footnote).pointSize
            let caption1FontSize = UIFont.preferredFont(forTextStyle: .caption1).pointSize
            let caption2FontSize = UIFont.preferredFont(forTextStyle: .caption2).pointSize

            let textColor = interfaceStyle == .light || interfaceStyle == .unspecified ? "black" : "white"

            return """
            <style>
            body, th, td {
                font: -apple-system-body;
                font-size: \(bodyFontSize)px;
                color: \(textColor);
            }
            h1, .large-title {
                font-size: \(largeTitleFontSize)px;
            }
            h2, .title-1 {
                font-size: \(title1FontSize)px;
            }
            h3, .title-2 {
                font-size: \(title2FontSize)px;
            }
            h4 .title3 {
                font-size: \(title3FontSize)px;
            }
            h5 .headline {
                font-size: \(headlineFontSize)px;
                font-weight: 700;
            }
            .callout {
                font-size: \(calloutFontSize)px;
            }
            .subheadline {
                font-size: \(subheadlineFontSize)px;
            }
            .footnote {
                font-size: \(footnoteFontSize)px;
            }
            .caption-1 {
                font-size: \(caption1FontSize)px;
            }
            .caption-2 {
                font-size: \(caption2FontSize)px;
            }
            img {
                width: \(Int(contentWidth))px;
            }
            p, ol, ul, div {
                display: block;
                padding-top:10px;
                padding-bottom:10px;
                line-height: 1.5;
            }

            \(customCSS ?? "")

            </style>
            """
        }

    }
}

private class NoCardFeaturedContentView: OCKFeaturedContentView {
    override func styleDidChange() {
        super.styleDidChange()
        enableCardStyling(false, style: style())
    }
}
#endif
