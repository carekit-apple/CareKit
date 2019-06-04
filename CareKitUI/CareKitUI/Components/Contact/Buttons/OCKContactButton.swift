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

internal class OCKContactButton: OCKButton {
    
    // MARK: Properties
    
    internal enum `Type`: String {
        case call = "Call"
        case message = "Message"
        case email = "E-mail"
        
        func imageName() -> String {
            switch self {
            case .call: return OCKStyle.assets.phone
            case .message: return OCKStyle.assets.messages
            default: return OCKStyle.assets.email
            }
        }
    }
    
    override var imageButton: OCKButton? { _imageButton }
    override var titleButton: OCKButton? { _titleButton }
    
    private let _imageButton: OCKButton = {
        let button = OCKButton()
        button.imageView?.contentMode = .scaleAspectFit
        button.isUserInteractionEnabled = false
        return button
    }()
    
    private let _titleButton: OCKButton = {
        let button = OCKButton(titleTextStyle: .footnote, titleWeight: .semibold)
        button.titleLabel?.textAlignment = .center
        button.fitsSizeToTitleLabel = true
        button.isUserInteractionEnabled = false
        return button
    }()
    
    internal let type: Type
    
    // MARK: Life cycle
    
    internal init(type: Type) {
        self.type = type
        super.init()
        setup()
    }
    
    required internal init?(coder aDecoder: NSCoder) {
        fatalError("Not supported.")
    }
    
    // MARK: Methods
    
    internal override func tintColorDidChange() {
        _imageButton.imageView?.tintColor = tintColor
        _titleButton.setTitleColor(tintColor, for: .normal)
    }
    
    func setup() {
        styleSubviews()
        addSubviews()
        constrainSubviews()
    }
    
    private func styleSubviews() {
        preservesSuperviewLayoutMargins = true
        tintColorDidChange()
        
        let bundle = Bundle(for: OCKContactButton.self)
        let image = UIImage(named: type.imageName(), in: bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        setImage(image, for: .normal)
        _titleButton.setTitle(type.rawValue, for: .normal)
        
        layer.cornerRadius = OCKStyle.appearance.cornerRadius2
        clipsToBounds = true
        backgroundColor = OCKStyle.color.gray1
        adjustsImageWhenHighlighted = false
        
        setBackgroundColor(OCKStyle.color.gray1, for: .normal)
    }
    
    func addSubviews() {
        [_titleButton, _imageButton].forEach { addSubview($0) }
    }
    
    func constrainSubviews() {
        [_titleButton, _imageButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            _imageButton.heightAnchor.constraint(equalToConstant: OCKStyle.dimension.iconHeight3),
            _imageButton.topAnchor.constraint(equalTo: topAnchor, constant: directionalLayoutMargins.top * 2),
            _imageButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: directionalLayoutMargins.leading * 2),
            _imageButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -directionalLayoutMargins.trailing * 2),
            _imageButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            _titleButton.topAnchor.constraint(equalTo: _imageButton.bottomAnchor, constant: directionalLayoutMargins.top / 2.0),
            _titleButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: directionalLayoutMargins.leading * 2),
            _titleButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -directionalLayoutMargins.trailing * 2),
            _titleButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -directionalLayoutMargins.bottom * 2)
        ])
    }
}
