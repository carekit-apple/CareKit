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

import Foundation
import UIKit

/// A button with an icon and title label.
///
///     +--------------------------+
///     | [Title]           [Icon] |
///     +--------------------------+
///
internal class OCKChecklistItemButton: OCKButton {
    
    // MARK: Properties
    
    private enum Constants {
        static let marginFactor: CGFloat = 1.8
    }
    
    override var titleButton: OCKButton? { _titleButton }
    override var imageButton: OCKButton? { circleButton }
    
    /// The title button embedded inside this button.
    private let _titleButton: OCKButton = {
        let button = OCKButton(titleTextStyle: .subheadline, titleWeight: .regular)
        button.isUserInteractionEnabled = false
        button.setTitle(OCKStyle.strings.event, for: .normal)
        button.setTitle(OCKStyle.strings.event, for: .selected)
        button.setTitleColor(.black, for: .normal)
        button.setTitleColor(.lightGray, for: .selected)
        button.fitsSizeToTitleLabel = true
        button.contentHorizontalAlignment = .left
        return button
    }()
    
    /// The icon embedded inside this button.
    private let circleButton: OCKButton = {
        let button = OCKCircleButton()
        button.isUserInteractionEnabled = false
        return button
    }()
    
    // MARK: Life Cycle
    
    /// Create an instance of an event icon button.
    override internal init() {
        super.init()
        setup()
    }
    
    required internal init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    // MARK: Methods
    
    private func setup() {
        addSubviews()
        constrainSubviews()
    }
    
    private func addSubviews() {
        addSubview(_titleButton)
        addSubview(circleButton)
    }
    
    private func constrainSubviews() {
        [self, _titleButton, circleButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        NSLayoutConstraint.activate([
            
            _titleButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            _titleButton.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: directionalLayoutMargins.top * Constants.marginFactor),
            _titleButton.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor,
                                                 constant: -directionalLayoutMargins.bottom * Constants.marginFactor),
            _titleButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            circleButton.leadingAnchor.constraint(equalTo: _titleButton.trailingAnchor, constant: directionalLayoutMargins.leading * 2),
            circleButton.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: directionalLayoutMargins.top * Constants.marginFactor),
            circleButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            circleButton.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor,
                                                 constant: -directionalLayoutMargins.bottom * Constants.marginFactor),
            circleButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            circleButton.heightAnchor.constraint(equalToConstant: OCKStyle.dimension.buttonHeight3),
            circleButton.widthAnchor.constraint(equalTo: circleButton.heightAnchor)
        ])
    }
}
