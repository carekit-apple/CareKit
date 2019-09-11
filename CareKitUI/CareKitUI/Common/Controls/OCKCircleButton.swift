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

class OCKCircleButton: OCKButton {
    // MARK: Properties

    var checkmarkHeight: CGFloat = OCKStyle().dimension.iconHeight4 {
        didSet { checkmarkHeightConstraint.constant = checkmarkHeight }
    }

    private var checkmarkHeightConstraint: NSLayoutConstraint!

    override var imageButton: OCKButton? {
        return _imageButton
    }

    private lazy var _imageButton: OCKButton = {
        let button = OCKButton()
        let selectedImage = UIImage(systemName: "checkmark")?.applyingSymbolConfiguration(.init(weight: .bold))
        button.setImage(selectedImage, for: .selected)
        button.setImage(nil, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.isUserInteractionEnabled = false
        return button
    }()

    // MARK: Life cycle

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.height / 2.0
    }

    // MARK: Methods

    override func setup() {
        super.setup()
        addSubviews()
        constrainSubviews()
        styleSubviews()
    }

    private func styleSubviews() {
        clipsToBounds = true
        setBackgroundColor(.clear, for: .normal)
        tintedTraits = [TintedTrait(trait: .backgroundColor, state: .selected)]
    }

    private func addSubviews() {
        addSubview(_imageButton)
    }

    private func constrainSubviews() {
        _imageButton.translatesAutoresizingMaskIntoConstraints = false
        checkmarkHeightConstraint = _imageButton.heightAnchor.constraint(equalToConstant: checkmarkHeight)
        NSLayoutConstraint.activate([
            checkmarkHeightConstraint,
            _imageButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            _imageButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0.5)
        ])
    }

    override func setBackgroundColor(_ color: UIColor?, for state: UIControl.State) {
        super.setBackgroundColor(color, for: state)
        // match the layer's border color with the selected state color
        if state == .selected {
            layer.borderColor = color?.cgColor
        }
    }

    override func styleDidChange() {
        super.styleDidChange()
        let cachedStyle = style()
        layer.borderWidth = cachedStyle.appearance.borderWidth1
        _imageButton.tintColor = cachedStyle.color.systemBackground
    }
}
