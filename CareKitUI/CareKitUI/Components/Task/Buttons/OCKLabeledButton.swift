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

/// A button with a filled background color.
///
///     +--------------------------+
///     |         [Title]          |
///     +--------------------------+
///
internal class OCKLabeledButton: OCKButton {
    
    // MARK: Properties
    
    override var titleButton: OCKButton? { _titleButton }
    
    private let _titleButton: OCKButton = {
        let button = OCKButton(titleTextStyle: .subheadline, titleWeight: .medium)
        button.fitsSizeToTitleLabel = true
        button.isUserInteractionEnabled = false
        button.tintedTraits = [TintedTrait(trait: .titleColor, state: .selected)]
        
        button.setTitle(OCKStyle.strings.markCompleted, for: .normal)
        button.setTitle(OCKStyle.strings.completed, for: .selected)
        
        return button
    }()
    
    // MARK: Life Cycle
    
    internal override init() {
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
        styleSubviews()
        constrainSubviews()
    }
    
    private func addSubviews() {
        addSubview(_titleButton)
    }
    
    private func styleSubviews() {
        animatesStateChanges = true
        adjustsImageWhenHighlighted = false
        layer.cornerRadius = OCKStyle.appearance.cornerRadius2
        clipsToBounds = true
        setBackgroundColor(OCKStyle.color.gray1, for: .selected)
        setTitleColor(OCKStyle.color.white, for: .normal)
        tintedTraits = [TintedTrait(trait: .backgroundColor, state: .normal)]
    }
    
    private func constrainSubviews() {
        _titleButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            _titleButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: directionalLayoutMargins.leading * 2),
            _titleButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -directionalLayoutMargins.trailing * 2),
            _titleButton.topAnchor.constraint(equalTo: topAnchor, constant: directionalLayoutMargins.top * 1.5),
            _titleButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -directionalLayoutMargins.bottom * 1.5)
        ])
    }
}
