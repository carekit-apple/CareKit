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

internal class OCKLogItemButton: OCKButton {
    
    private enum Constants {
        static let bundle = Bundle(for: OCKChecklistItemButton.self)
        static let spacing: CGFloat = 2
    }
    
    override var imageButton: OCKButton? { return _imageButton }
    override var detailButton: OCKButton? { _detailButton }
    override var titleButton: OCKButton? { _titleButton }
    
    private let _imageButton: OCKButton = {
        let button = OCKButton()
        let image = UIImage(named: OCKStyle.assets.clock, in: Constants.bundle, compatibleWith: nil)?
            .withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.isUserInteractionEnabled = false
        return button
    }()
    
    private let _titleButton: OCKButton = {
        let button = OCKButton(titleTextStyle: .caption1, titleWeight: .regular)
        button.setTitleColor(.black, for: .normal)
        button.isUserInteractionEnabled = false
        return button
    }()
    
    private let _detailButton: OCKButton = {
        let button = OCKButton(titleTextStyle: .caption1, titleWeight: .regular)
        button.tintedTraits = [TintedTrait(trait: .titleColor, state: .normal)]
        button.isUserInteractionEnabled = false
        return button
    }()
    
    // MARK: Life cycle
    
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
        styleSubviews()
        addSubviews()
        constrainSubviews()
    }
    
    private func styleSubviews() {
        preservesSuperviewLayoutMargins = true
    }
    
    private func addSubviews() {
        [_imageButton, _titleButton, _detailButton].forEach { addSubview($0) }
    }
    
    private func constrainSubviews() {
        [_imageButton, _titleButton, _detailButton].forEach { $0?.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            _imageButton.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            _imageButton.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            _imageButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            _imageButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            _imageButton.heightAnchor.constraint(equalToConstant: OCKStyle.dimension.iconHeight4),
            _imageButton.widthAnchor.constraint(equalTo: _imageButton.heightAnchor),
            
            _detailButton.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            _detailButton.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            _detailButton.leadingAnchor.constraint(equalTo: _imageButton.trailingAnchor, constant: Constants.spacing),
            _detailButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            _titleButton.leadingAnchor.constraint(equalTo: _detailButton.trailingAnchor, constant: directionalLayoutMargins.leading),
            _titleButton.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            _titleButton.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            _titleButton.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            _titleButton.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    override func setDetailColor(_ color: UIColor?, for state: UIControl.State) {
        super.setDetailColor(color, for: state)
        // match the detail image tint with the detail color
        if state == .normal {
            imageButton?.tintColor = color
        }
    }
}
