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

/// A card that displays information for a contact. The header is an `OCKHeaderView`
/// The body contains a multi-line istructions label, and four buttons; call, message,
/// email, and address. The first three buttons have title labels and image views that can
/// be modified, while the last has a title label, body label, and image view.
///
///     +-------------------------------------------------------+
///     | +------+                                              |
///     | | icon | [title]                       [detail        |
///     | | img  | [detail]                       disclosure]   |
///     | +------+                                              |
///     |                                                       |
///     |  --------------------------------------------------   |
///     |                                                       |
///     | [Instructions]                                        |
///     |                                                       |
///     | +------------+      +------------+     +------------+ |
///     | |  [title]   |      |   [title]  |     |   [title]  | |
///     | |            |      |            |     |            | |
///     | +------------+      +------------+     +------------+ |
///     |                                                       |
///     | +---------------------------------------------------+ |
///     | |  [title]                                          | |
///     | |  [detail]                                         | |
///     | |                                                   | |
///     | +---------------------------------------------------+ |
///     +-------------------------------------------------------+
///
open class OCKSimpleContactView: UIView, OCKCardable {
    
    private enum Constants {
        static let bundle = Bundle(for: OCKSimpleContactView.self)
    }
    
    /// A certical stack view that holds the main content in the view.
    public let contentStackView: OCKStackView = {
        let stackView = OCKStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        return stackView
    }()
    
    /// Header stack view that shows an `iconImageView` and a separator.
    public let headerView = OCKHeaderView {
        $0.showsIconImage = true
        $0.showsSeparator = true
    }
    
    /// Stack view that holds phone, message, and email contact action buttons.
    private let contactStackView: OCKStackView = {
        let stackView = OCKStackView(style: .plain)
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    /// Stack view that holds buttons in `contactStack` and `directionsButton`.
    /// You may choose to add or hide buttons
    private let buttonStackView: OCKStackView = {
        let stackView = OCKStackView(style: .plain)
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        return stackView
    }()
    
    /// Multi-line label under the `headerView`.
    public let instructionsLabel: OCKLabel = {
        let label = OCKLabel(textStyle: .subheadline, weight: .medium)
        label.numberOfLines = 0
        return label
    }()
    
    /// Button with a phone image and `titleLabel`.
    /// Set the `isHidden` property to `false` to hide the button.
    public let callButton: OCKButton = OCKContactButton(type: .call)
    
    /// Button with a messages images and `titleLabel`.
    /// Set the `isHidden` property to `false` to hide the button.
    public let messageButton: OCKButton = OCKContactButton(type: .message)
    
    /// Button with an email image and `titleLabel`.
    /// Set the `isHidden` property to `false` to hide the button.
    public let emailButton: OCKButton = OCKContactButton(type: .email)
    
    /// Button with a location image, `titleLabel`, and `detailLabel`.
    /// Set the `isHidden` property to `false` to hide the button.
    public let addressButton: OCKButton = OCKAddressButton()
    
    /// The default image that can be used as a placeholder for the `iconImageView` in the `headerView`.
    public static let defaultImage = UIImage(named: OCKStyle.assets.profile,
                                             in: Constants.bundle,
                                             compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
    
    public init() {
        super.init(frame: .zero)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    /// Prepares interface after initialization
    private func setup() {
        addSubviews()
        constrainSubviews()
        styleSubviews()
    }
    
    private func addSubviews() {
        addSubview(contentStackView)
        [headerView, instructionsLabel, buttonStackView].forEach { contentStackView.addArrangedSubview($0) }
        [callButton, messageButton, emailButton].forEach { contactStackView.addArrangedSubview($0) }
        [contactStackView, addressButton].forEach { buttonStackView.addArrangedSubview($0) }
    }
    
    private func constrainSubviews() {
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: directionalLayoutMargins.leading * 2),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -directionalLayoutMargins.trailing * 2),
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: directionalLayoutMargins.top * 2),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -directionalLayoutMargins.bottom * 2)
        ])
    }
    
    private func styleSubviews() {
        preservesSuperviewLayoutMargins = true
        enableCardStyling(true)
        
        contentStackView.spacing = directionalLayoutMargins.top * 2
        [contactStackView, buttonStackView].forEach { $0.spacing = directionalLayoutMargins.top }
  
        // set default profile picture with tint
        headerView.iconImageView?.tintColor = OCKStyle.color.gray1
        headerView.iconImageView?.image = OCKSimpleContactView.defaultImage
    }
}
