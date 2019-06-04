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

internal class OCKAddressButton: OCKButton {
    
    // MARK: Properties
    
    override var detailButton: OCKButton? { _detailButton }
    override var titleButton: OCKButton? { _titleButton }
    override var imageButton: OCKButton? { _imageButton }
  
    private let _imageButton: OCKButton = {
        let button = OCKButton()
        button.isUserInteractionEnabled = false
        let bundle = Bundle(for: OCKAddressButton.self)
        let image = UIImage(named: OCKStyle.assets.location, in: bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        return button
    }()
     
    private let _titleButton: OCKButton = {
        let button = OCKButton(titleTextStyle: .footnote, titleWeight: .semibold)
        button.fitsSizeToTitleLabel = true
        button.titleLabel?.numberOfLines = 0
        button.isUserInteractionEnabled = false
        button.contentHorizontalAlignment = .leading
        button.setTitle(OCKStyle.strings.address, for: .normal)
        return button
    }()
    
    private let _detailButton: OCKButton = {
        let button = OCKButton(titleTextStyle: .footnote, titleWeight: .regular)
        button.fitsSizeToTitleLabel = true
        button.titleLabel?.numberOfLines = 0
        button.isUserInteractionEnabled = false
        button.contentHorizontalAlignment = .leading
        button.setTitleColor(.black, for: .normal)
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
    
    internal override func tintColorDidChange() {
        imageView?.tintColor = tintColor
        _titleButton.setTitleColor(tintColor, for: .normal)
    }
    
    private func setup() {
        styleSubviews()
        addSubviews()
        constrainSubviews()
    }
    
    private func styleSubviews() {
        preservesSuperviewLayoutMargins = true
        tintColorDidChange()
        
        layer.cornerRadius = OCKStyle.appearance.cornerRadius2
        clipsToBounds = true
        adjustsImageWhenHighlighted = false

        setBackgroundColor(OCKStyle.color.gray1, for: .normal)
    }
    
    private func addSubviews() {
        [_titleButton, _detailButton, _imageButton].forEach { addSubview($0) }
    }
    
    func constrainSubviews() {
        [_titleButton, _detailButton, _imageButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            _titleButton.topAnchor.constraint(equalTo: topAnchor, constant: directionalLayoutMargins.top * 2),
            _titleButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: directionalLayoutMargins.leading * 2),
            
            _imageButton.leadingAnchor.constraint(greaterThanOrEqualTo: _titleButton.trailingAnchor, constant: directionalLayoutMargins.leading * 2),
            _imageButton.topAnchor.constraint(equalTo: topAnchor, constant: directionalLayoutMargins.top * 2),
            _imageButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -directionalLayoutMargins.trailing * 2),
            _imageButton.heightAnchor.constraint(equalToConstant: OCKStyle.dimension.iconHeight3),
            
            _detailButton.leadingAnchor.constraint(equalTo: _titleButton.leadingAnchor),
            _detailButton.trailingAnchor.constraint(equalTo: _imageButton.leadingAnchor, constant: -directionalLayoutMargins.trailing * 2),
            _detailButton.topAnchor.constraint(equalTo: _titleButton.bottomAnchor, constant: directionalLayoutMargins.top / 3),
            bottomAnchor.constraint(equalTo: _detailButton.bottomAnchor, constant: directionalLayoutMargins.bottom * 2)
        ])
    }
}
