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

internal class OCKCircleButton: OCKButton {
    
    // MARK: Properties
    
    override internal var imageButton: OCKButton? {
        return _imageButton
    }
   
    private let _imageButton: OCKButton = {
        let button = OCKButton()
        let bundle = Bundle(for: OCKChecklistItemButton.self)
        let selectedImage = UIImage(named: OCKStyle.assets.check, in: bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)

        button.setImage(selectedImage, for: .selected)
        button.setImage(nil, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
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
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.height / 2.0
    }
    
    // MARK: Methods
    
    private func setup() {
        styleSubviews()
        addSubviews()
        constrainSubviews()
    }
    
    private func styleSubviews() {
        preservesSuperviewLayoutMargins = true
        clipsToBounds = true
        layer.borderWidth = OCKStyle.appearance.borderWidth1
        setBackgroundColor(.clear, for: .normal)
        _imageButton.tintColor = .white
        tintedTraits = [TintedTrait(trait: .backgroundColor, state: .selected)]
    }
    
    private func addSubviews() {
        [_imageButton].forEach { addSubview($0) }
    }
    
    private func constrainSubviews() {
        [_imageButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            _imageButton.heightAnchor.constraint(equalTo: heightAnchor),
            _imageButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            _imageButton.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    override func setBackgroundColor(_ color: UIColor, for state: UIControl.State) {
        super.setBackgroundColor(color, for: state)
        // match the layer's border color with the selected state color
        if state == .selected {
            layer.borderColor = color.cgColor
        }
    }
}
