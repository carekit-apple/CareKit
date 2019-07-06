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

internal class OCKLabeledCircleButton: OCKButton {
    
    // MARK: Properties
    
    override var titleButton: OCKButton? { return _titleButton }
    override var imageButton: OCKButton? { return _imageButton }
    
    private let _titleButton: OCKButton = {
        let button = OCKButton(titleTextStyle: .caption1, titleWeight: .medium)
        button.isUserInteractionEnabled = false
        button.setTitleColor(.lightGray, for: .selected)
        return button
    }()
    
    private let _imageButton: OCKButton = {
        let button = OCKCircleButton()
        button.layer.borderWidth = OCKStyle.appearance.borderWidth2
        button.isUserInteractionEnabled = false
        return button
    }()
    
    // MARK: Life cycle
    
    override init() {
        super.init()
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    // MARK: Methods
    
    private func setup() {
        addSubviews()
        styleSubviews()
        constrainSubviews()
    }
    
    private func constrainSubviews() {
        [_titleButton, _imageButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            _imageButton.topAnchor.constraint(equalTo: topAnchor),
            _imageButton.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7),
            _imageButton.heightAnchor.constraint(equalTo: _imageButton.widthAnchor),
            _imageButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            _titleButton.topAnchor.constraint(equalTo: _imageButton.bottomAnchor),
            _titleButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            _titleButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomAnchor.constraint(equalTo: _titleButton.bottomAnchor)
        ])
    }
    
    private func addSubviews() {
        [_imageButton, _titleButton].forEach { addSubview($0) }
    }
    
    private func styleSubviews() {
        preservesSuperviewLayoutMargins = true
    }
}
